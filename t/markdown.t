#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL}   = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

require "$root_dir/code-agent.pl";

our ($COLOR_RESET, $COLOR_DIM, $COLOR_SUBAGENT, $STYLE_BOLD, $STYLE_UNDERLINE, $COLOR_HEADER, $COLOR_CODE);

# Slice 1: Styling constants and basic render_markdown / format_inline_markdown existence
ok(defined &render_markdown, 'render_markdown subroutine is defined');
ok(defined &format_inline_markdown, 'format_inline_markdown subroutine is defined');

{
    local $COLOR_RESET     = "\x1b[0m";
    local $COLOR_DIM       = "\x1b[33m";
    local $COLOR_SUBAGENT  = "\x1b[36m";
    local $STYLE_BOLD      = "\x1b[1m";
    local $STYLE_UNDERLINE = "\x1b[4m";
    local $COLOR_HEADER    = "\x1b[1;35m";
    local $COLOR_CODE      = "\x1b[34m";

    is(render_markdown('# Top Heading'), "\x1b[1;4;35mTop Heading\x1b[0m", 'H1 renders with bold+underline+magenta');
    is(render_markdown('## Section Heading'), "\x1b[1;35mSection Heading\x1b[0m", 'H2 renders with bold+magenta');
    is(render_markdown('### Sub Heading'), "\x1b[1;35m### Sub Heading\x1b[0m", 'H3 renders with ### prefix in bold+magenta');

    # Slice 2: Inline markdown formatting
    is(format_inline_markdown('Use **bold** and __also bold__ text'),
       "Use \x1b[1mbold\x1b[0m and \x1b[1malso bold\x1b[0m text",
       'Bold (**text** and __text__) renders in ANSI bold');

    is(format_inline_markdown('Use *italic* and _underlined_ text'),
       "Use \x1b[4mitalic\x1b[0m and \x1b[4munderlined\x1b[0m text",
       'Emphasis (*text* and _text_) renders in ANSI underline');

    is(format_inline_markdown('Keep foo_bar_baz and my_var_1 untouched'),
       'Keep foo_bar_baz and my_var_1 untouched',
       'snake_case identifiers are never corrupted by _emphasis_');

    is(format_inline_markdown('Run `perl_build **raw** _code_` now'),
       "Run \x1b[34mperl_build **raw** _code_\x1b[0m now",
       'Inline code renders in blue and protects inner markdown syntax');

    is(format_inline_markdown('Visit [Apple Tiger](https://apple.com) today'),
       "Visit \x1b[4mApple Tiger\x1b[0m \x1b[36m(https://apple.com)\x1b[0m today",
       'Links render underlined label followed by cyan (url)');

    # Slice 3: Fenced code blocks, lists, blockquotes, horizontal rules
    my $code_md = "```perl\nmy \$x = **1**;\nprint \$x;\n```";
    is(render_markdown($code_md),
       "\x1b[34m  +--[ perl ]\x1b[0m\n\x1b[34m  | my \$x = **1**;\x1b[0m\n\x1b[34m  | print \$x;\x1b[0m",
       'Fenced code block renders with language header and blue ASCII gutter without inline formatting');

    my $code_nolang = "```\nplain_code()\n```";
    is(render_markdown($code_nolang),
       "\x1b[34m  | plain_code()\x1b[0m",
       'Fenced code block without language omits language header');

    my $unclosed_code = "```sh\necho hi";
    is(render_markdown($unclosed_code),
       "\x1b[34m  +--[ sh ]\x1b[0m\n\x1b[34m  | echo hi\x1b[0m",
       'Unclosed fenced code block renders gracefully');

    my $lists_md = join("\n",
        "- top item",
        "  - nested level 1",
        "    - nested level 2",
        "1. first ordered",
        "2. second ordered",
        "- [ ] pending task",
        "- [x] completed task"
    );
    is(render_markdown($lists_md),
       join("\n",
           "  * top item",
           "    - nested level 1",
           "      + nested level 2",
           "  1. first ordered",
           "  2. second ordered",
           "  [ ] pending task",
           "  \x1b[36m[x]\x1b[0m completed task"
       ),
       'Unordered lists (levels 0..2), ordered lists, and task lists render with Tiger-safe ASCII prefixes');

    is(render_markdown("> quoted **line**\n>> nested quote"),
       "\x1b[33m  | \x1b[0mquoted \x1b[1mline\x1b[0m\n\x1b[33m  | | \x1b[0mnested quote",
       'Blockquotes (> and >>) render with dim vertical bars and inline formatting');

    is(render_markdown("---"),
       "\x1b[33m  " . ('-' x 60) . "\x1b[0m",
       'Horizontal rule (---) renders 60-col ASCII divider in dim color');

    # Slice 4: Pipe tables with header styling, column alignment, and inline formatting
    my $table_md = join("\n",
        "| Tool | Mode | Score |",
        "| :--- | :---: | ---: |",
        "| `curl-bin` | auto | 100 |",
        "| perl | manual | 5 |"
    );
    my $expected_table = join("\n",
        "  +----------+--------+-------+",
        "  | \x1b[1;35mTool\x1b[0m     |  \x1b[1;35mMode\x1b[0m  | \x1b[1;35mScore\x1b[0m |",
        "  +----------+--------+-------+",
        "  | \x1b[34mcurl-bin\x1b[0m |  auto  |   100 |",
        "  | perl     | manual |     5 |",
        "  +----------+--------+-------+"
    );
    is(render_markdown($table_md), $expected_table,
       'Pipe table renders as aligned ASCII box table with bold+magenta header and left/center/right alignment');
}

# Slice 5: NO_COLOR / empty color constants degradation
{
    local $COLOR_RESET     = '';
    local $COLOR_DIM       = '';
    local $COLOR_SUBAGENT  = '';
    local $STYLE_BOLD      = '';
    local $STYLE_UNDERLINE = '';
    local $COLOR_HEADER    = '';
    local $COLOR_CODE      = '';

    my $doc = join("\n",
        "# Title",
        "### Sub",
        "Some **bold**, _underline_, `code`, and [Link](https://example.com).",
        "```perl",
        "my \$v = 1;",
        "```",
        "- [x] Done",
        "| A | B |",
        "|---|---|",
        "| 1 | 2 |"
    );
    my $plain = render_markdown($doc);
    unlike($plain, qr/\x1b/, 'NO_COLOR mode emits zero ANSI escape sequences');
    like($plain, qr/^Title\n### Sub\n/m, 'Headers degrade cleanly in NO_COLOR mode');
    like($plain, qr/\+--\[ perl \]/, 'Code block header preserved in NO_COLOR mode');
    like($plain, qr/\+---\+---\+/, 'ASCII table box borders preserved in NO_COLOR mode');
}

# Slice 6: Standalone CLI execution (perl src/markdown.pl)
{
    my $md_script = File::Spec->catfile($root_dir, 'src', 'markdown.pl');
    my $tmp_md = File::Spec->catfile($root_dir, 't', 'tmp_sample_test.md');
    open my $fh, '>', $tmp_md or die "Cannot write $tmp_md: $!";
    print $fh "# CLI Heading\n- item **one**\n";
    close $fh;

    my $out_file = `NO_COLOR=1 "$^X" "$md_script" "$tmp_md" 2>&1`;
    my $exit_code = $? >> 8;
    unlink $tmp_md;

    is($exit_code, 0, 'Standalone src/markdown.pl exits with 0');
    like($out_file, qr/CLI Heading/, 'Standalone src/markdown.pl renders heading from file argument');
    like($out_file, qr/\* item one/, 'Standalone src/markdown.pl renders list item from file argument');
}

# Slice 7: ANSI-aware slow_print
{
    local $ENV{CLAUDE_TYPE_DELAY} = '0.0001';
    my $input = "\x1b[1;35mHello\x1b[0m\n";
    my $captured = '';
    open my $mem_fh, '>', \$captured or die "Cannot open scalar fh: $!";
    my $old_fh = select($mem_fh);
    slow_print($input);
    select($old_fh);
    close $mem_fh;
    is($captured, $input, 'ANSI-aware slow_print outputs exact string including escape sequences');

    # Also test undef / empty guard
    my $empty_cap = '';
    open my $efh, '>', \$empty_cap;
    my $prev = select($efh);
    slow_print('');
    slow_print(undef);
    select($prev);
    close $efh;
    is($empty_cap, '', 'slow_print handles undef and empty string without warnings');
}

# Slice 8: Edge cases (CRLF normalization, header levels 4-6, table without alignment separator, *** and ___ rules)
{
    local $COLOR_RESET     = "\x1b[0m";
    local $COLOR_DIM       = "\x1b[33m";
    local $COLOR_SUBAGENT  = "\x1b[36m";
    local $STYLE_BOLD      = "\x1b[1m";
    local $STYLE_UNDERLINE = "\x1b[4m";
    local $COLOR_HEADER    = "\x1b[1;35m";
    local $COLOR_CODE      = "\x1b[34m";

    is(render_markdown(undef), '', 'render_markdown(undef) returns empty string');
    is(render_markdown(''), '', 'render_markdown("") returns empty string');
    is(format_inline_markdown(undef), '', 'format_inline_markdown(undef) returns empty string');

    is(render_markdown("# Line 1\r\n## Line 2"),
       "\x1b[1;4;35mLine 1\x1b[0m\n\x1b[1;35mLine 2\x1b[0m",
       'CRLF line endings are normalized properly');

    is(render_markdown("#### H4 Heading ##"),
       "\x1b[1;35m#### H4 Heading\x1b[0m",
       'H4 strips trailing closing hashes and keeps #### prefix');

    is(render_markdown("***"),
       "\x1b[33m  " . ('-' x 60) . "\x1b[0m",
       '*** horizontal rule renders 60-col ASCII divider');

    is(render_markdown("___"),
       "\x1b[33m  " . ('-' x 60) . "\x1b[0m",
       '___ horizontal rule renders 60-col ASCII divider');

    my $no_sep_table = "| col1 | col2 |\n| val1 | val2 |";
    my $expected_no_sep = join("\n",
        "  +------+------+",
        "  | col1 | col2 |",
        "  | val1 | val2 |",
        "  +------+------+"
    );
    is(render_markdown($no_sep_table), $expected_no_sep,
       'Pipe table without alignment separator row renders clean ASCII grid without header divider');

    # Slice 9: Terminal-Width Multi-Line Cell Word-Wrapping (Case B)
    {
        local $ENV{COLUMNS} = 80;
        my $wide_table = join("\n",
            "| Feature / Category | AMD Athlon 64 | Intel Pentium 4 |",
            "| :--- | :--- | :--- |",
            "| Architecture & Pipeline | Short 12-stage pipeline designed for high instructions-per-clock efficiency and low branch misprediction penalty. | Very deep 31-stage Prescott NetBurst pipeline designed to maximize raw clock frequency at the expense of IPC. |",
            "| Memory Controller | Integrated on-die DDR memory controller with direct HyperTransport link reducing latency drastically. | Traditional Front-Side Bus architecture routed through external Northbridge chipset adding memory latency. |"
        );
        my $rendered_80 = render_markdown($wide_table);
        my @lines_80 = split /\n/, $rendered_80;
        ok(@lines_80 > 8, 'Wide 3-column table wraps into multiple physical lines on 80-col terminal');
        my $max_vis_80 = 0;
        my $all_pipes_aligned = 1;
        my $first_border = $lines_80[0];
        my @plus_positions;
        while ($first_border =~ /\+/g) {
            push @plus_positions, pos($first_border) - 1;
        }
        for my $l (@lines_80) {
            my $vw = _visible_width($l);
            $max_vis_80 = $vw if $vw > $max_vis_80;
            (my $plain_l = $l) =~ s/\x1b\[[0-9;]*[A-Za-z]//g;
            for my $p (@plus_positions) {
                my $ch = substr($plain_l, $p, 1);
                if (!defined($ch) || ($ch ne '+' && $ch ne '|')) {
                    $all_pipes_aligned = 0;
                }
            }
        }
        cmp_ok($max_vis_80, '<=', 80, 'Every line of 80-col wrapped table fits within 80 columns');
        ok($all_pipes_aligned, 'Vertical | borders align with + corners on every single physical line');
        my @border_lines = grep { /^\s*\+[-+]+\+\s*$/ } @lines_80;
        is(scalar(@border_lines), 4, 'Multi-line wrapped table emits row divider border between data rows (top, header, row1-row2, bottom)');

        local $ENV{COLUMNS} = 120;
        my $rendered_120 = render_markdown($wide_table);
        my @lines_120 = split /\n/, $rendered_120;
        my $max_vis_120 = 0;
        for my $l (@lines_120) {
            my $vw = _visible_width($l);
            $max_vis_120 = $vw if $vw > $max_vis_120;
        }
        cmp_ok($max_vis_120, '<=', 120, 'Every line of 120-col wrapped table fits within 120 columns');
        cmp_ok(scalar(@lines_120), '<', scalar(@lines_80), '120-col terminal requires fewer wrapped lines than 80-col terminal');
    }

    # Slice 10: ANSI style continuity across wrapped cell lines & long unbroken token splitting
    {
        local $ENV{COLUMNS} = 50;
        my $ansi_table = join("\n",
            "| ColA | ColB |",
            "| :--- | :--- |",
            "| **Bold text that wraps across multiple physical lines inside cell one** | Plain second column |"
        );
        my $rendered_ansi = render_markdown($ansi_table);
        my @ansi_lines = split /\n/, $rendered_ansi;
        my @data_lines = grep { /^  \|/ && !/ColA/ } @ansi_lines;
        cmp_ok(scalar(@data_lines), '>=', 2, 'Bold cell wraps across at least 2 physical lines');
        like($data_lines[0], qr/\x1b\[1mBold.*\x1b\[0m\s*\|\s*Plain/,
             'Line 1 of wrapped bold cell closes ANSI bold with RESET before the | border so it does not bleed into ColB');
        like($data_lines[1], qr/^  \|\s*\x1b\[1m/,
             'Line 2 of wrapped bold cell re-opens ANSI bold at the start of the continuation cell');

        # Long unbroken word (e.g. URL/path exceeding column width)
        my $url_table = join("\n",
            "| Key | Endpoint |",
            "| :--- | :--- |",
            "| api | `https://vintage-powerpc-tiger-server.example.com/v1/chat/completions/stream` |"
        );
        my $rendered_url = render_markdown($url_table);
        my @url_lines = split /\n/, $rendered_url;
        my $max_url_vis = 0;
        for my $l (@url_lines) {
            my $vw = _visible_width($l);
            $max_url_vis = $vw if $vw > $max_url_vis;
        }
        cmp_ok($max_url_vis, '<=', 50, 'Long unbroken token (inline code URL) is hard-broken cleanly within column width');
        my @url_data = grep { /^  \|/ && !/Endpoint/ } @url_lines;
        cmp_ok(scalar(@url_data), '>=', 2, 'Long unbroken URL wraps across multiple lines');
        like($url_data[0], qr/\x1b\[34mhttps:.*\x1b\[0m\s*\|$/,
             'First chunk of broken inline-code URL resets color before right border');
        like($url_data[1], qr/\|\s*\x1b\[34m/,
             'Second chunk of broken inline-code URL restores inline-code color');
    }

    # Slice 11: Vertical Card Fallback (Case C: too many columns to fit side-by-side at >= 10 chars each)
    {
        local $ENV{COLUMNS} = 80;
        my $many_cols_table = join("\n",
            "| C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 |",
            "|---|---|---|---|---|---|---|---|",
            "| Alpha value 1 | Beta value 2 | Gamma value 3 | Delta value 4 | Epsilon value 5 | Zeta value 6 | Eta value 7 | Theta value 8 closely wrapped to verify card layout |"
        );
        my $rendered_cards = render_markdown($many_cols_table);
        like($rendered_cards, qr/C1\x1b\[0m\s*:\s*Alpha value 1/,
             '8-column table on 80-col terminal triggers vertical card fallback format (Header : Value)');
        like($rendered_cards, qr/C8\x1b\[0m\s*:\s*Theta value 8/,
             'Card fallback renders all columns as labeled key-value rows');
        my $max_card_vis = 0;
        for my $l (split /\n/, $rendered_cards) {
            my $vw = _visible_width($l);
            $max_card_vis = $vw if $vw > $max_card_vis;
        }
        cmp_ok($max_card_vis, '<=', 80, 'Every line in vertical card fallback fits within 80-column terminal');

        # Card fallback without header separator row
        my $headerless_wide = join("\n",
            "| A111111111 | B222222222 | C333333333 | D444444444 | E555555555 | F666666666 | G777777777 | H888888888 |",
            "| I111111111 | J222222222 | K333333333 | L444444444 | M555555555 | N666666666 | O777777777 | P888888888 |"
        );
        my $rendered_hl_cards = render_markdown($headerless_wide);
        like($rendered_hl_cards, qr/Col 1.*:\s*A111111111/,
             'Headerless wide table uses Col 1..Col N labels in card fallback mode');

        # Compact 8-column table that fits naturally within 80 columns stays a grid (not cards)
        my $compact_many_cols = join("\n",
            "| A | B | C | D | E | F | G | H |",
            "|---|---|---|---|---|---|---|---|",
            "| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |"
        );
        my $rendered_compact_8 = render_markdown($compact_many_cols);
        like($rendered_compact_8, qr/^  \+---\+---\+---\+---\+---\+---\+---\+---\+$/m,
             'Compact 8-column table that fits within 80 columns renders as normal ASCII grid instead of cards');
    }
}

done_testing();
