# --- Tool Call Visual Formatting Helpers ---

sub extract_basename {
    my ($path) = @_;
    return '' unless defined $path && length $path;
    return '/' if $path =~ m{^/+$};
    $path =~ s{/+$}{};
    if ($path =~ m{([^/]+)$}) {
        return $1;
    }
    return $path;
}

sub truncate_text {
    my ($str, $max_len) = @_;
    return '' unless defined $str;
    $max_len = 20 unless defined $max_len;

    my $clean = $str;
    $clean =~ s/\s+/ /g;
    $clean =~ s/^\s+|\s+$//g;

    if (length($clean) > $max_len) {
        return substr($clean, 0, $max_len) . '...';
    }
    return $clean;
}

sub _format_line_range {
    my ($input) = @_;
    return undef unless ref($input) eq 'HASH';
    if (defined $input->{start_line} && defined $input->{end_line}) {
        return "L$input->{start_line}-$input->{end_line}";
    }
    elsif (defined $input->{start_line}) {
        return "L$input->{start_line}-";
    }
    elsif (defined $input->{end_line}) {
        return "L1-$input->{end_line}";
    }
    return undef;
}

sub _summary_file_base {
    my ($input) = @_;
    my $base = extract_basename(resolve_path_param($input));
    return length($base) ? $base : '?';
}

sub _summary_read_file {
    my ($input) = @_;
    my $range = _format_line_range($input);
    return defined $range ? (_summary_file_base($input), $range) : (_summary_file_base($input));
}

sub _summary_write_file {
    my ($input) = @_;
    my @out = (_summary_file_base($input));
    my $content = resolve_content_param($input);
    push @out, truncate_text($content, 20) if defined $content && length($content) > 0;
    return @out;
}

sub _summary_edit_file {
    my ($input) = @_;
    my @out = (_summary_file_base($input));
    my $range = _format_line_range($input);
    push @out, $range if defined $range;
    my $rep = resolve_content_param($input, 'replacement', 'new_text');
    push @out, truncate_text($rep, 20) if defined $rep && length($rep) > 0;
    return @out;
}

sub _summary_run_shell {
    my ($input) = @_;
    my $cmd = resolve_command_param($input);
    return (defined $cmd && length($cmd) > 0) ? (truncate_text($cmd, 20)) : ();
}

sub _summary_list_dir {
    my ($input) = @_;
    my $p = resolve_path_param($input);
    return (!defined $p || $p eq '' || $p eq '.') ? ('.') : (extract_basename($p));
}

sub _summary_invoke_subagent {
    my ($input) = @_;
    my $type = (defined $input->{subagent_type} && length $input->{subagent_type})
             ? $input->{subagent_type}
             : 'build';
    my @out = ("[$type]");
    push @out, truncate_text($input->{task}, 30) if defined $input->{task} && length $input->{task};
    return @out;
}

sub _summary_generic_tool {
    my ($input) = @_;
    for my $k (sort keys %$input) {
        next if $k =~ /^_/;
        my $v = $input->{$k};
        if (defined $v && !ref($v) && length($v) > 0) {
            return (truncate_text($v, 20));
        }
    }
    return ();
}

my %TOOL_SUMMARY_FORMATTERS = (
    read_file       => \&_summary_read_file,
    write_file      => \&_summary_write_file,
    edit_file       => \&_summary_edit_file,
    run_shell       => \&_summary_run_shell,
    list_dir        => \&_summary_list_dir,
    invoke_subagent => \&_summary_invoke_subagent,
);

sub format_tool_summary {
    my ($name, $input) = @_;
    $name = '' unless defined $name;
    $input = {} unless defined $input && ref($input) eq 'HASH';

    my $formatter = $TOOL_SUMMARY_FORMATTERS{$name} || \&_summary_generic_tool;
    my @parts = ($name, $formatter->($input));
    return join('   ', @parts);
}

sub format_tool_call {
    my ($name, $input) = @_;
    my $summary = format_tool_summary($name, $input);
    if (defined $COLOR_DIM && $COLOR_DIM ne '') {
        return "$COLOR_DIM$summary$COLOR_RESET";
    }
    return $summary;
}

sub format_thinking_status {
    my ($elapsed) = @_;
    $elapsed = 1 if !defined $elapsed || $elapsed < 1;
    my $text = "* Thinking ${elapsed}s...";
    if (defined $COLOR_DIM && $COLOR_DIM ne '') {
        return "$COLOR_DIM$text$COLOR_RESET";
    }
    return $text;
}

sub finalize_thinking_line {
    my ($elapsed) = @_;
    return "\r" . format_thinking_status($elapsed) . "\n";
}

sub clear_thinking_line {
    return "\r\033[K";
}

sub format_retry_status {
    my ($retry_num, $max_retries, $delay) = @_;
    my $text = "* API error, retrying in ${delay}s ($retry_num/$max_retries)...";
    if (defined $COLOR_DIM && $COLOR_DIM ne '') {
        return "$COLOR_DIM$text$COLOR_RESET";
    }
    return $text;
}

sub format_subagent_start {
    my ($subagent_type, $task) = @_;
    my $c_sub   = defined $COLOR_SUBAGENT ? $COLOR_SUBAGENT : '';
    my $c_reset = defined $COLOR_RESET    ? $COLOR_RESET    : '';
    my $c_dim   = defined $COLOR_DIM      ? $COLOR_DIM      : '';
    my $clean_task = truncate_text($task, 50);
    return "\n${c_sub}  ┌── [Sub-agent: $subagent_type]${c_reset} ${c_dim}$clean_task${c_reset}\n";
}

sub format_subagent_tool_call {
    my ($subagent_type, $turn, $max_turns, $name, $input) = @_;
    my $c_sub   = defined $COLOR_SUBAGENT ? $COLOR_SUBAGENT : '';
    my $c_reset = defined $COLOR_RESET    ? $COLOR_RESET    : '';
    my $c_dim   = defined $COLOR_DIM      ? $COLOR_DIM      : '';
    my $summary = format_tool_summary($name, $input);
    return "${c_sub}  │${c_reset} ${c_dim}[Turn $turn/$max_turns]${c_reset} $summary\n";
}

sub format_subagent_finish {
    my ($subagent_type, $turns, $status) = @_;
    my $c_sub   = defined $COLOR_SUBAGENT ? $COLOR_SUBAGENT : '';
    my $c_reset = defined $COLOR_RESET    ? $COLOR_RESET    : '';
    my $c_dim   = defined $COLOR_DIM      ? $COLOR_DIM      : '';
    $status = 'Completed' unless defined $status && length $status;
    return "${c_sub}  └── [Sub-agent: $subagent_type]${c_reset} ${c_dim}$status in $turns turn(s)${c_reset}\n";
}


sub slow_print {
    my ($text) = @_;
    return unless defined $text && length $text;
    my $delay = $ENV{CLAUDE_TYPE_DELAY};
    $delay = 0.006 unless defined $delay && $delay ne '';
    $delay = 0 + $delay;
    if ($delay <= 0) {
        print $text;
        return;
    }
    while ($text =~ /(\x1b\[[0-9;]*[A-Za-z]|.)/sg) {
        my $tok = $1;
        print $tok;
        next if length($tok) > 1; # ANSI escape sequence: no delay
        select(undef, undef, undef, $tok eq "\n" ? $delay * 12 : $delay);
    }
}

sub show_banner {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;

    my $c_bold   = defined $STYLE_BOLD  ? $STYLE_BOLD  : '';
    my $c_code   = defined $COLOR_CODE  ? $COLOR_CODE  : '';
    my $c_gray   = defined $COLOR_GRAY  ? $COLOR_GRAY  : '';
    my $c_reset  = defined $COLOR_RESET ? $COLOR_RESET : '';
    my $c_bold_blue = $c_bold . $c_code;

    # Detect if target handle has a UTF-8 layer (such as STDOUT configured with :encoding(UTF-8)).
    # When printing to a UTF-8 handle, characters must be decoded characters.
    # When printing to an unencoded raw handle (like in-memory scalar handles in tests),
    # printing raw bytes avoids "Wide character in print" warnings and multibyte boundary splitting.
    my $has_utf8_layer = 0;
    eval {
        my @layers = PerlIO::get_layers($out_fh);
        $has_utf8_layer = 1 if grep { $_ eq 'utf8' || $_ =~ /^encoding\(/ } @layers;
    };

    my $mascot_body_bytes = "\xe2\x96\x88\xc2\xb7\xe2\x96\x88\xc2\xb7\xe2\x96\x88";
    my $mascot_legs_bytes = " \xe2\x96\x80 \xe2\x96\x80 ";

    my $mascot_body = $has_utf8_layer
        ? eval { Encode::decode('UTF-8', $mascot_body_bytes) } || $mascot_body_bytes
        : $mascot_body_bytes;
    my $mascot_legs = $has_utf8_layer
        ? eval { Encode::decode('UTF-8', $mascot_legs_bytes) } || $mascot_legs_bytes
        : $mascot_legs_bytes;

    my $ver_str = 'v' . (defined $VERSION && length $VERSION ? $VERSION : '1.3.0');

    # Line 1: █·█·█  CodeAgent v1.3.0
    print $out_fh $c_bold_blue . $mascot_body . $c_reset . "  "
                . $c_bold_blue . "CodeAgent" . $c_reset . " "
                . $c_gray . $ver_str . $c_reset . "\n";

    # Line 2:  ▀ ▀   AI everywhere
    print $out_fh $c_code . $mascot_legs . $c_reset . "  "
                . $c_gray . "AI everywhere" . $c_reset . "\n\n";

    my $prov = (defined &get_current_provider ? get_current_provider() : undef) || $PROVIDER || 'unknown';
    my $mod  = (defined &get_current_model ? get_current_model() : undef) || $MODEL || 'unknown';
    my $api_url = (defined &get_current_api_url ? get_current_api_url() : undef) || $API_URL || '';
    my $where = '';
    if ($prov eq 'openai' && $api_url =~ m{^https?://([^/]+)}) {
        $where = " @ $1";
    }
    my $auto = defined &get_auto_mode ? get_auto_mode() : $AUTO_MODE;
    my $mode_str = (defined $auto && $auto) ? 'auto' : 'manual';

    print $out_fh " [$prov / $mod$where]  mode: $mode_str\n";
    if (keys %MCP_SERVERS) {
        my $connected = 0;
        for my $s (values %MCP_SERVERS) {
            $connected++ if defined $s->{status} && $s->{status} eq 'connected';
        }
        my $total = scalar(keys %MCP_SERVERS);
        my $tools_count = scalar(keys %MCP_TOOLS);
        print $out_fh " MCP: $connected/$total servers connected ($tools_count tools)\n";
    }
    print $out_fh " Type /help for commands, /models to switch model.\n";
}

# --- Session Statistics Formatting Helpers ---

sub format_duration {
    my ($seconds) = @_;
    $seconds = 0 if !defined $seconds || $seconds < 0;
    $seconds = int($seconds);

    if ($seconds < 60) {
        return "${seconds}s";
    }
    elsif ($seconds < 3600) {
        my $m = int($seconds / 60);
        my $s = $seconds % 60;
        return "${m}m ${s}s";
    }
    else {
        my $h = int($seconds / 3600);
        my $rem = $seconds % 3600;
        my $m = int($rem / 60);
        my $s = $rem % 60;
        return "${h}h ${m}m ${s}s";
    }
}

sub format_number_comma {
    my ($num) = @_;
    return '0' unless defined $num && length($num);
    my $sign = '';
    $num = "$num";
    if ($num =~ s/^-//) {
        $sign = '-';
    }
    my ($int, $dec) = split(/\./, $num, 2);
    1 while $int =~ s/^(-?\d+)(\d{3})/$1,$2/;
    return defined $dec ? "$sign$int.$dec" : "$sign$int";
}

sub _format_stats_header {
    my ($session, $duration_str) = @_;
    my $c_head  = defined $COLOR_HEADER ? $COLOR_HEADER : '';
    my $c_reset = defined $COLOR_RESET  ? $COLOR_RESET  : '';

    my $id = defined $session->{id} ? $session->{id} : 'unknown';
    my $prov = defined $session->{provider} ? $session->{provider} : ($PROVIDER || 'unknown');
    my $model = defined $session->{model} ? $session->{model} : ($MODEL || 'unknown');

    my $created = defined $session->{created_at} ? int($session->{created_at}) : time();
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($created);
    $year += 1900;
    $mon += 1;
    my $started_str = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);

    my $out = "\n${c_head}=== Session Statistics ===${c_reset}\n";
    $out .= "  Session ID: $id\n";
    $out .= "  Provider:   $prov\n";
    $out .= "  Model:      $model\n";
    $out .= "  Started:    $started_str\n";
    $out .= "  Duration:   $duration_str\n\n";
    return $out;
}

sub _format_stats_activity {
    my ($session, $stats) = @_;
    my $c_bold  = defined $STYLE_BOLD  ? $STYLE_BOLD  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';

    my $user_turns = count_user_turns($session);
    my $asst_turns = count_assistant_turns($session);
    my $total_msgs = (ref($session->{messages}) eq 'ARRAY') ? scalar(@{ $session->{messages} }) : 0;
    my $api_calls  = $stats->{api_calls} || 0;
    my $chars      = estimate_session_chars($session);

    my $out = "${c_bold}Activity:${c_reset}\n";
    $out .= "  User turns:      " . format_number_comma($user_turns) . "\n";
    $out .= "  Assistant turns: " . format_number_comma($asst_turns) . "\n";
    $out .= "  Total messages:  " . format_number_comma($total_msgs) . "\n";
    $out .= "  API calls:       " . format_number_comma($api_calls) . "\n";
    $out .= "  Context size:    " . format_number_comma($chars) . " chars\n\n";
    return $out;
}

sub _format_stats_tokens {
    my ($stats) = @_;
    my $c_bold  = defined $STYLE_BOLD  ? $STYLE_BOLD  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';

    my $in_tok  = $stats->{input_tokens} || 0;
    my $out_tok = $stats->{output_tokens} || 0;
    my $tot_tok = $in_tok + $out_tok;
    my $cr_tok  = $stats->{cache_read_tokens} || 0;
    my $cw_tok  = $stats->{cache_write_tokens} || 0;

    my $out = "${c_bold}Token Usage:${c_reset}\n";
    $out .= "  Input tokens:    " . format_number_comma($in_tok) . "\n";
    $out .= "  Output tokens:   " . format_number_comma($out_tok) . "\n";
    $out .= "  Total tokens:    " . format_number_comma($tot_tok) . "\n";
    if ($cr_tok > 0) {
        $out .= "  Cache read:      " . format_number_comma($cr_tok) . "\n";
    }
    if ($cw_tok > 0) {
        $out .= "  Cache write:     " . format_number_comma($cw_tok) . "\n";
    }
    $out .= "\n";
    return $out;
}

sub _format_stats_tools {
    my ($stats) = @_;
    my $c_bold  = defined $STYLE_BOLD  ? $STYLE_BOLD  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';

    my $tool_calls = $stats->{tool_calls} || 0;
    my $subagents  = $stats->{subagent_calls} || 0;
    my $tools_href = (ref($stats->{tools}) eq 'HASH') ? $stats->{tools} : {};

    my $out = "${c_bold}Tool Invocations:${c_reset}\n";
    $out .= "  Total tool calls: " . format_number_comma($tool_calls) . "\n";
    if ($subagents > 0) {
        $out .= "  Sub-agents:       " . format_number_comma($subagents) . "\n";
    }
    for my $tool_name (sort keys %$tools_href) {
        my $cnt = $tools_href->{$tool_name} || 0;
        $out .= "    $tool_name: " . format_number_comma($cnt) . "\n";
    }
    $out .= "\n";
    return $out;
}

sub _format_stats_compaction {
    my ($stats) = @_;
    my $compact_cnt = $stats->{compact_count} || 0;
    return '' unless $compact_cnt > 0;

    my $c_bold  = defined $STYLE_BOLD  ? $STYLE_BOLD  : '';
    my $c_reset = defined $COLOR_RESET ? $COLOR_RESET : '';
    my $bytes_saved = $stats->{bytes_saved} || 0;

    my $out = "${c_bold}Context Compaction:${c_reset}\n";
    $out .= "  Compactions:     " . format_number_comma($compact_cnt) . "\n";
    $out .= "  Bytes saved:     " . format_number_comma($bytes_saved) . " bytes\n\n";
    return $out;
}

sub format_session_stats {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return "No active session.\n" unless defined $session && ref($session) eq 'HASH';

    my $stats = get_session_stats($session);
    my $created = defined $session->{created_at} ? int($session->{created_at}) : time();
    my $now = time();
    my $elapsed = ($now >= $created) ? ($now - $created) : 0;
    my $duration_str = format_duration($elapsed);

    return _format_stats_header($session, $duration_str)
         . _format_stats_activity($session, $stats)
         . _format_stats_tokens($stats)
         . _format_stats_tools($stats)
         . _format_stats_compaction($stats);
}



