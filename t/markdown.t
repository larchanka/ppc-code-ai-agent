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
}

done_testing();
