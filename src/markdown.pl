# --- Markdown Renderer (Mac OS X 10.4 Tiger Terminal.app compatible) ---

sub _md_color {
    my ($val) = @_;
    return defined $val ? $val : '';
}

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

    my $c_reset = _md_color($COLOR_RESET);
    my $c_code  = _md_color($COLOR_CODE);
    my $c_cyan  = _md_color($COLOR_SUBAGENT);
    my $s_bold  = _md_color($STYLE_BOLD);
    my $s_uline = _md_color($STYLE_UNDERLINE);

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

sub _get_markdown_term_cols {
    my ($override_cols) = @_;
    for my $candidate ($override_cols, $ENV{COLUMNS}) {
        if (defined $candidate && $candidate =~ /^\s*(\d+)\s*$/ && $1 > 0) {
            return int($1);
        }
    }
    if (defined(&_term_size)) {
        my (undef, $cols) = _term_size();
        return int($cols) if defined $cols && $cols > 0;
    }
    return 80;
}

sub _sum_widths {
    my ($arr_ref) = @_;
    my $s = 0;
    $s += $_ for @$arr_ref;
    return $s;
}

sub _lock_narrow_columns {
    my ($natural, $alloc, $rem_cols, $rem_avail) = @_;
    while (@$rem_cols) {
        my $fair_share = int($rem_avail / scalar(@$rem_cols));
        my @kept;
        for my $c (@$rem_cols) {
            if ($natural->[$c] <= $fair_share) {
                $alloc->[$c] = $natural->[$c];
                $rem_avail  -= $natural->[$c];
            }
            else {
                push @kept, $c;
            }
        }
        last if scalar(@kept) == scalar(@$rem_cols);
        @$rem_cols = @kept;
    }
    return $rem_avail;
}

sub _balance_col_remainder {
    my ($alloc, $rem_cols, $diff, $min_col) = @_;
    my $idx = 0;
    my $n = scalar(@$rem_cols);
    while ($diff != 0 && $idx <= 1000) {
        my $c = $rem_cols->[$idx % $n];
        if ($diff > 0) {
            $alloc->[$c]++;
            $diff--;
        }
        elsif ($alloc->[$c] > $min_col) {
            $alloc->[$c]--;
            $diff++;
        }
        $idx++;
    }
}

sub _distribute_wide_columns {
    my ($natural, $alloc, $rem_cols, $rem_avail, $min_col) = @_;
    return unless @$rem_cols;
    my $wide_sum = 0;
    $wide_sum += $natural->[$_] for @$rem_cols;
    my $used = 0;
    for my $c (@$rem_cols) {
        my $share = ($wide_sum > 0) ? int($rem_avail * $natural->[$c] / $wide_sum) : int($rem_avail / scalar(@$rem_cols));
        $share = $min_col if $share < $min_col;
        $alloc->[$c] = $share;
        $used += $share;
    }
    _balance_col_remainder($alloc, $rem_cols, $rem_avail - $used, $min_col);
}

sub _allocate_table_col_widths {
    my ($natural_widths, $term_cols) = @_;
    my $num_cols = scalar(@$natural_widths);
    my $avail = $term_cols - (3 * $num_cols + 3);
    my $min_col = 10;
    my $total_natural = _sum_widths($natural_widths);

    return ('cards', [@$natural_widths]) if $total_natural > $avail && $avail < $num_cols * $min_col;

    my @alloc = (0) x $num_cols;
    my @rem_cols = (0 .. $num_cols - 1);
    my $rem_avail = _lock_narrow_columns($natural_widths, \@alloc, \@rem_cols, $avail);
    _distribute_wide_columns($natural_widths, \@alloc, \@rem_cols, $rem_avail, $min_col);
    return ('grid', \@alloc);
}

sub _update_active_sgr {
    my ($text, $current_sgr) = @_;
    my $sgr = defined $current_sgr ? $current_sgr : '';
    while ($text =~ /(\x1b\[[0-9;]*m)/g) {
        my $code = $1;
        $sgr = ($code eq "\x1b[0m" || $code eq "\x1b[m") ? '' : ($sgr . $code);
    }
    return $sgr;
}

sub _break_long_token {
    my ($token, $col_width) = @_;
    my @parts = split /(\x1b\[[0-9;]*[A-Za-z])/, $token;
    my @chunks;
    my $cur = '';
    my $cur_w = 0;
    for my $p (@parts) {
        next unless length $p;
        if ($p =~ /^\x1b\[/) {
            $cur .= $p;
            next;
        }
        for my $ch (split //, $p) {
            my $cw = defined(&_char_width) ? _char_width($ch) : 1;
            if ($cur_w + $cw > $col_width && $cur_w > 0) {
                push @chunks, $cur;
                $cur = '';
                $cur_w = 0;
            }
            $cur .= $ch;
            $cur_w += $cw;
        }
    }
    push @chunks, $cur if length $cur;
    return @chunks;
}

sub _wrap_words_raw {
    my ($text, $col_width) = @_;
    return ('') unless defined $text && length $text;
    my @raw_tokens = grep { length $_ } split /\s+/, $text;
    return ('') unless @raw_tokens;

    my @tokens = map { (_visible_width($_) > $col_width) ? _break_long_token($_, $col_width) : $_ } @raw_tokens;
    my @lines;
    my $cur = shift @tokens;
    my $cur_w = _visible_width($cur);
    for my $tok (@tokens) {
        my $tw = _visible_width($tok);
        if ($cur_w + 1 + $tw <= $col_width) {
            $cur .= ' ' . $tok;
            $cur_w += 1 + $tw;
        }
        else {
            push @lines, $cur;
            $cur = $tok;
            $cur_w = $tw;
        }
    }
    push @lines, $cur;
    return @lines;
}

sub _wrap_table_cell {
    my ($formatted_text, $col_width) = @_;
    $col_width = 1 if !defined $col_width || $col_width < 1;
    my @raw_lines = _wrap_words_raw($formatted_text, $col_width);
    my $c_reset = _md_color($COLOR_RESET);
    my $active_sgr = '';
    my @out;
    for my $line (@raw_lines) {
        my $prefixed = ($active_sgr ne '') ? "${active_sgr}${line}" : $line;
        $active_sgr = _update_active_sgr($line, $active_sgr);
        $prefixed .= $c_reset if $active_sgr ne '' && $c_reset ne '';
        push @out, $prefixed;
    }
    return \@out;
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
    my $c_hdr   = _md_color($COLOR_HEADER);
    my $c_reset = _md_color($COLOR_RESET);
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

sub _render_wrapped_grid_row {
    my ($row, $col_widths, $aligns, $num_cols) = @_;
    my @wrapped_cols;
    my $max_lines = 1;
    for my $c (0 .. $num_cols - 1) {
        my $lines = _wrap_table_cell($row->[$c], $col_widths->[$c]);
        $max_lines = scalar(@$lines) if scalar(@$lines) > $max_lines;
        push @wrapped_cols, $lines;
    }
    my @physical_lines;
    for my $l_idx (0 .. $max_lines - 1) {
        my @line_cells = map { defined $wrapped_cols[$_][$l_idx] ? $wrapped_cols[$_][$l_idx] : '' } (0 .. $num_cols - 1);
        push @physical_lines, _pad_table_row(\@line_cells, $col_widths, $aligns, $num_cols);
    }
    return \@physical_lines;
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

sub _resolve_card_headers {
    my ($formatted_rows, $has_header, $num_cols) = @_;
    return (\@{ $formatted_rows->[0] }, 1) if $has_header && @$formatted_rows > 0;
    my $c_hdr   = _md_color($COLOR_HEADER);
    my $c_reset = _md_color($COLOR_RESET);
    my @headers = map {
        my $lbl = "Col " . ($_ + 1);
        ($c_hdr ne '') ? "$c_hdr$lbl$c_reset" : $lbl;
    } (0 .. $num_cols - 1);
    return (\@headers, 0);
}

sub _render_markdown_table_cards {
    my ($formatted_rows, $has_header, $num_cols, $term_cols) = @_;
    my ($headers_ref, $start_idx) = _resolve_card_headers($formatted_rows, $has_header, $num_cols);
    my $label_w = 0;
    for my $h (@$headers_ref) {
        my $w = _visible_width($h);
        $label_w = $w if $w > $label_w;
    }
    my $val_width = $term_cols - ($label_w + 5);
    $val_width = 20 if $val_width < 20;
    my $rule_len = ($term_cols > 62) ? 60 : (($term_cols > 4) ? ($term_cols - 2) : 40);
    my $divider  = '  ' . ('-' x $rule_len);
    my $indent   = '  ' . (' ' x $label_w) . '   ';

    my @out = ($divider);
    for my $r_idx ($start_idx .. $#$formatted_rows) {
        my $row = $formatted_rows->[$r_idx];
        for my $c (0 .. $num_cols - 1) {
            my $lbl = _align_cell($headers_ref->[$c], $label_w, 'left');
            my $w_lines = _wrap_table_cell($row->[$c], $val_width);
            push @out, "  $lbl : " . $w_lines->[0];
            for my $li (1 .. $#$w_lines) {
                push @out, $indent . $w_lines->[$li];
            }
        }
        push @out, $divider;
    }
    return @out;
}

sub _max_row_cols {
    my ($rows_ref) = @_;
    my $max = 0;
    for my $r (@$rows_ref) {
        $max = scalar(@$r) if scalar(@$r) > $max;
    }
    return $max;
}

sub _assemble_grid_table {
    my ($formatted_rows, $col_widths, $aligns_ref, $num_cols, $has_header) = @_;
    my @rendered_rows = map { _render_wrapped_grid_row($_, $col_widths, $aligns_ref, $num_cols) } @$formatted_rows;
    my $has_multiline = grep { scalar(@$_) > 1 } @rendered_rows;

    my $border = '  +' . join('+', map { '-' x ($_ + 2) } @$col_widths) . '+';
    my @out = ($border);
    for my $idx (0 .. $#rendered_rows) {
        push @out, @{ $rendered_rows[$idx] };
        push @out, $border if ($has_header && $idx == 0) || ($has_multiline && $idx < $#rendered_rows);
    }
    push @out, $border;
    return @out;
}

sub _render_markdown_table {
    my ($lines_ref) = @_;
    my @raw_rows = map { _split_table_row($_) } @$lines_ref;
    my $has_header = (@raw_rows >= 2) ? _parse_table_alignment($raw_rows[1]) : undef;
    my $num_cols = _max_row_cols(\@raw_rows);
    return @$lines_ref if $num_cols == 0;

    my @aligns = $has_header ? @$has_header : ();
    my ($formatted_rows, $natural_widths) = _collect_table_metrics(\@raw_rows, $has_header, $num_cols);
    my $term_cols = _get_markdown_term_cols();
    my ($mode, $col_widths) = _allocate_table_col_widths($natural_widths, $term_cols);
    if ($mode eq 'cards') {
        return _render_markdown_table_cards($formatted_rows, $has_header, $num_cols, $term_cols);
    }
    return _assemble_grid_table($formatted_rows, $col_widths, \@aligns, $num_cols, $has_header);
}

sub _format_header_line {
    my ($hashes, $title) = @_;
    my $level   = length($hashes);
    my $c_hdr   = _md_color($COLOR_HEADER);
    my $c_reset = _md_color($COLOR_RESET);
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
    my $c_dim   = _md_color($COLOR_DIM);
    my $c_reset = _md_color($COLOR_RESET);
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
    my $c_cyan  = _md_color($COLOR_SUBAGENT);
    my $c_reset = _md_color($COLOR_RESET);

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
    my $c_dim   = _md_color($COLOR_DIM);
    my $c_reset = _md_color($COLOR_RESET);

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
    my $c_code  = _md_color($COLOR_CODE);
    my $c_reset = _md_color($COLOR_RESET);
    return "${c_code}  | ${code_line}${c_reset}";
}

sub _format_code_fence_header {
    my ($lang) = @_;
    return () unless defined $lang && length $lang;
    my $c_code  = _md_color($COLOR_CODE);
    my $c_reset = _md_color($COLOR_RESET);
    return ("${c_code}  +--[ $lang ]${c_reset}");
}

sub _flush_markdown_table_buf {
    my ($table_buf_ref, $out_ref) = @_;
    return unless @$table_buf_ref;
    push @$out_ref, _render_markdown_table($table_buf_ref);
    @$table_buf_ref = ();
}

sub render_markdown {
    my ($text) = @_;
    return '' unless defined $text && $text ne '';
    $text =~ s/\r\n?/\n/g;

    my @lines = split /\n/, $text, -1;
    my @out;
    my $in_code = 0;
    my @table_buf;

    for my $line (@lines) {
        if ($in_code) {
            $in_code = 0, next if $line =~ /^\s*```\s*$/;
            push @out, _format_code_block_line($line);
            next;
        }
        if ($line =~ /^\s*```([A-Za-z0-9_+-]*)\s*$/) {
            _flush_markdown_table_buf(\@table_buf, \@out);
            $in_code = 1;
            push @out, _format_code_fence_header($1);
            next;
        }
        if ($line =~ /^\s*\|.*\|\s*$/) {
            push @table_buf, $line;
            next;
        }
        _flush_markdown_table_buf(\@table_buf, \@out);
        push @out, _format_block_line($line);
    }
    _flush_markdown_table_buf(\@table_buf, \@out);

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
        $COLOR_GRAY      = '';
    }
    else {
        $COLOR_RESET     = "\x1b[0m";
        $COLOR_DIM       = "\x1b[33m";
        $COLOR_SUBAGENT  = "\x1b[36m";
        $STYLE_BOLD      = "\x1b[1m";
        $STYLE_UNDERLINE = "\x1b[4m";
        $COLOR_HEADER    = "\x1b[1;35m";
        $COLOR_CODE      = "\x1b[34m";
        $COLOR_GRAY      = "\x1b[90m";
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
