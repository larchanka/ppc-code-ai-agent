# --- Markdown Renderer (Mac OS X 10.4 Tiger Terminal.app compatible) ---

sub _format_link_span {
    my ($label, $url, $s_uline, $c_cyan, $c_reset) = @_;
    if ($s_uline eq '' && $c_cyan eq '') {
        return "$label ($url)";
    }
    return "${s_uline}${label}${c_reset} ${c_cyan}($url)${c_reset}";
}

sub format_inline_markdown {
    my ($text) = @_;
    return '' unless defined $text;

    my $c_reset = defined $COLOR_RESET     ? $COLOR_RESET     : '';
    my $c_code  = defined $COLOR_CODE      ? $COLOR_CODE      : '';
    my $c_cyan  = defined $COLOR_SUBAGENT  ? $COLOR_SUBAGENT  : '';
    my $s_bold  = defined $STYLE_BOLD      ? $STYLE_BOLD      : '';
    my $s_uline = defined $STYLE_UNDERLINE ? $STYLE_UNDERLINE : '';

    # 1. Extract inline code spans (`...`) into placeholders
    my @code_spans;
    $text =~ s/`([^`\n]+)`/
        push @code_spans, $1;
        "\x00CODE" . $#code_spans . "\x00"
    /ge;

    # 2. Links: [label](url)
    $text =~ s/\[([^\[\]\n]+)\]\(([^()\s]+)\)/
        _format_link_span($1, $2, $s_uline, $c_cyan, $c_reset)
    /ge;

    # 3. Bold: **text** and __text__
    $text =~ s/\*\*([^\*\n]+)\*\*/${s_bold}$1${c_reset}/g;
    $text =~ s/(?<![0-9A-Za-z_])__([^_\n]+)__(?![0-9A-Za-z_])/${s_bold}$1${c_reset}/g;

    # 4. Emphasis / Underline: *text* and _text_ (respecting word boundaries for snake_case)
    $text =~ s/(?<!\*)\*([^\*\n]+)\*(?!\*)/${s_uline}$1${c_reset}/g;
    $text =~ s/(?<![0-9A-Za-z_])_([^_\n]+)_(?![0-9A-Za-z_])/${s_uline}$1${c_reset}/g;

    # 5. Restore inline code spans
    $text =~ s/\x00CODE(\d+)\x00/${c_code}$code_spans[$1]${c_reset}/g;

    return $text;
}

sub _visible_width {
    my ($str) = @_;
    return 0 unless defined $str && length $str;
    (my $plain = $str) =~ s/\x1b\[[0-9;]*[A-Za-z]//g;
    return defined(&_display_width_chars) ? _display_width_chars($plain) : length($plain);
}

sub _split_table_row {
    my ($line) = @_;
    $line =~ s/^\s*\|\s*//;
    $line =~ s/\s*\|\s*$//;
    my @cells = split /\s*\|\s*/, $line, -1;
    return \@cells;
}

sub _parse_table_alignment {
    my ($cells_ref) = @_;
    return undef unless @$cells_ref > 0;
    my @aligns;
    for my $cell (@$cells_ref) {
        return undef unless $cell =~ /^:?-{2,}:?$/;
        if ($cell =~ /^:-+:$/ ) {
            push @aligns, 'center';
        }
        elsif ($cell =~ /^-+:$/) {
            push @aligns, 'right';
        }
        else {
            push @aligns, 'left';
        }
    }
    return \@aligns;
}

sub _align_cell {
    my ($text, $width, $align) = @_;
    my $vis = _visible_width($text);
    my $pad = $width - $vis;
    $pad = 0 if $pad < 0;
    if ($align eq 'right') {
        return (' ' x $pad) . $text;
    }
    if ($align eq 'center') {
        my $left = int($pad / 2);
        my $right = $pad - $left;
        return (' ' x $left) . $text . (' ' x $right);
    }
    return $text . (' ' x $pad);
}

sub _format_table_row_cells {
    my ($raw_cells, $is_header, $num_cols) = @_;
    my $c_hdr   = defined $COLOR_HEADER ? $COLOR_HEADER : '';
    my $c_reset = defined $COLOR_RESET  ? $COLOR_RESET  : '';
    my @formatted;
    for my $c (0 .. $num_cols - 1) {
        my $raw = defined $raw_cells->[$c] ? $raw_cells->[$c] : '';
        my $val = format_inline_markdown($raw);
        if ($is_header && $c_hdr ne '' && length($val)) {
            $val = "$c_hdr$val$c_reset";
        }
        push @formatted, $val;
    }
    return \@formatted;
}

sub _pad_table_row {
    my ($row, $col_widths, $aligns, $num_cols) = @_;
    my @padded;
    for my $c (0 .. $num_cols - 1) {
        my $al = $aligns->[$c] || 'left';
        push @padded, ' ' . _align_cell($row->[$c], $col_widths->[$c], $al) . ' ';
    }
    return '  |' . join('|', @padded) . '|';
}

sub _collect_table_metrics {
    my ($raw_rows, $has_header, $num_cols) = @_;
    my @formatted_rows;
    my @col_widths = (0) x $num_cols;
    for my $idx (0 .. $#$raw_rows) {
        next if $has_header && $idx == 1;
        my $is_hdr = ($has_header && $idx == 0) ? 1 : 0;
        my $f_row  = _format_table_row_cells($raw_rows->[$idx], $is_hdr, $num_cols);
        for my $c (0 .. $num_cols - 1) {
            my $w = _visible_width($f_row->[$c]);
            $col_widths[$c] = $w if $w > $col_widths[$c];
        }
        push @formatted_rows, $f_row;
    }
    return (\@formatted_rows, \@col_widths);
}

sub _render_markdown_table {
    my ($lines_ref) = @_;
    my @raw_rows = map { _split_table_row($_) } @$lines_ref;
    my $has_header = (@raw_rows >= 2) ? _parse_table_alignment($raw_rows[1]) : undef;

    my $num_cols = 0;
    for my $r (@raw_rows) {
        $num_cols = scalar(@$r) if scalar(@$r) > $num_cols;
    }
    return @$lines_ref if $num_cols == 0;

    my @aligns = $has_header ? @$has_header : ();
    my ($formatted_rows, $col_widths) = _collect_table_metrics(\@raw_rows, $has_header, $num_cols);

    my $border = '  +' . join('+', map { '-' x ($_ + 2) } @$col_widths) . '+';
    my @out = ($border);
    for my $idx (0 .. $#$formatted_rows) {
        push @out, _pad_table_row($formatted_rows->[$idx], $col_widths, \@aligns, $num_cols);
        push @out, $border if $has_header && $idx == 0;
    }
    push @out, $border;
    return @out;
}

sub _format_header_line {
    my ($hashes, $title) = @_;
    my $level   = length($hashes);
    my $c_hdr   = defined $COLOR_HEADER ? $COLOR_HEADER : '';
    my $c_reset = defined $COLOR_RESET  ? $COLOR_RESET  : '';
    my $formatted = format_inline_markdown($title);

    if ($c_hdr eq '') {
        return ($level >= 3) ? "$hashes $formatted" : $formatted;
    }
    if ($level == 1) {
        return "\x1b[1;4;35m$formatted$c_reset";
    }
    if ($level == 2) {
        return "$c_hdr$formatted$c_reset";
    }
    return "$c_hdr$hashes $formatted$c_reset";
}

sub _format_blockquote_line {
    my ($quotes, $body) = @_;
    my $c_dim   = defined $COLOR_DIM   ? $COLOR_DIM   : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';
    (my $clean_q = $quotes) =~ s/\s+//g;
    my $depth = length($clean_q);
    my $bars  = '  ' . join(' ', ('|') x $depth) . ' ';
    my $formatted = format_inline_markdown($body);
    return ($c_dim ne '') ? "${c_dim}${bars}${c_reset}$formatted" : "${bars}$formatted";
}

sub _format_list_line {
    my ($indent_str, $marker, $body) = @_;
    my $spaces  = length($indent_str);
    my $level   = int($spaces / 2);
    my $pad     = '  ' . ('  ' x $level);
    my $c_cyan  = defined $COLOR_SUBAGENT ? $COLOR_SUBAGENT : '';
    my $c_reset = defined $COLOR_RESET    ? $COLOR_RESET    : '';

    if ($body =~ /^\[([ xX])\]\s+(.*)$/) {
        my ($chk, $rest) = ($1, $2);
        my $box = ($chk =~ /[xX]/)
            ? (($c_cyan ne '') ? "${c_cyan}[x]${c_reset}" : '[x]')
            : '[ ]';
        return "${pad}${box} " . format_inline_markdown($rest);
    }

    if ($marker =~ /^\d+\.$/) {
        return "${pad}${marker} " . format_inline_markdown($body);
    }

    my @bullets = ('*', '-', '+');
    my $b = $bullets[$level < 2 ? $level : 2];
    return "${pad}${b} " . format_inline_markdown($body);
}

sub _format_block_line {
    my ($line) = @_;
    my $c_dim   = defined $COLOR_DIM   ? $COLOR_DIM   : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';

    # Horizontal rule: ---, ***, ___
    if ($line =~ /^\s*([-*_])(?:\s*\1){2,}\s*$/) {
        my $rule = '  ' . ('-' x 60);
        return ($c_dim ne '') ? "${c_dim}${rule}${c_reset}" : $rule;
    }

    # ATX Header: # to ######
    if ($line =~ /^\s*(#{1,6})\s+(.*?)\s*#*\s*$/) {
        return _format_header_line($1, $2);
    }

    # Blockquote: > or >>
    if ($line =~ /^\s*((?:>\s*)+)(.*)$/) {
        return _format_blockquote_line($1, $2);
    }

    # Unordered, ordered, or task list item
    if ($line =~ /^(\s*)([-*+]|\d+\.)\s+(.*)$/) {
        return _format_list_line($1, $2, $3);
    }

    return format_inline_markdown($line);
}

sub _format_code_block_line {
    my ($code_line) = @_;
    my $c_code  = defined $COLOR_CODE  ? $COLOR_CODE  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';
    return "${c_code}  | ${code_line}${c_reset}";
}

sub _format_code_fence_header {
    my ($lang) = @_;
    return () unless defined $lang && length $lang;
    my $c_code  = defined $COLOR_CODE  ? $COLOR_CODE  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';
    return ("${c_code}  +--[ $lang ]${c_reset}");
}

sub render_markdown {
    my ($text) = @_;
    return '' unless defined $text && length $text;
    $text =~ s/\r\n?/\n/g;

    my @lines = split /\n/, $text, -1;
    my @out;
    my $in_code = 0;
    my @table_buf;

    my $flush_table = sub {
        return unless @table_buf;
        push @out, _render_markdown_table(\@table_buf);
        @table_buf = ();
    };

    for my $line (@lines) {
        if (!$in_code && $line =~ /^\s*```([A-Za-z0-9_+-]*)\s*$/) {
            $flush_table->();
            $in_code = 1;
            push @out, _format_code_fence_header($1);
            next;
        }
        if ($in_code) {
            $in_code = 0, next if $line =~ /^\s*```\s*$/;
            push @out, _format_code_block_line($line);
            next;
        }
        if ($line =~ /^\s*\|.*\|\s*$/) {
            push @table_buf, $line;
            next;
        }
        $flush_table->();
        push @out, _format_block_line($line);
    }
    $flush_table->();

    return join("\n", @out);
}

sub _init_standalone_markdown_colors {
    return if defined $COLOR_RESET;
    if (!-t STDOUT || exists $ENV{NO_COLOR}) {
        $COLOR_RESET     = '';
        $COLOR_DIM       = '';
        $COLOR_SUBAGENT  = '';
        $STYLE_BOLD      = '';
        $STYLE_UNDERLINE = '';
        $COLOR_HEADER    = '';
        $COLOR_CODE      = '';
    }
    else {
        $COLOR_RESET     = "\x1b[0m";
        $COLOR_DIM       = "\x1b[33m";
        $COLOR_SUBAGENT  = "\x1b[36m";
        $STYLE_BOLD      = "\x1b[1m";
        $STYLE_UNDERLINE = "\x1b[4m";
        $COLOR_HEADER    = "\x1b[1;35m";
        $COLOR_CODE      = "\x1b[34m";
    }
}

if (!caller && $0 =~ /markdown\.pl$/) {
    _init_standalone_markdown_colors();
    my $raw = do { local $/; <> };
    if (defined $raw && length $raw) {
        print render_markdown($raw) . "\n";
    }
}

1;
