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

sub format_tool_summary {
    my ($name, $input) = @_;
    $name = '' unless defined $name;
    $input = {} unless defined $input && ref($input) eq 'HASH';

    my @parts = ($name);

    if ($name eq 'read_file') {
        my $base = extract_basename($input->{path});
        push @parts, (length($base) ? $base : '?');
        my $range = _format_line_range($input);
        push @parts, $range if defined $range;
    }
    elsif ($name eq 'write_file') {
        my $base = extract_basename($input->{path});
        push @parts, (length($base) ? $base : '?');
        if (defined $input->{content} && length($input->{content}) > 0) {
            push @parts, truncate_text($input->{content}, 20);
        }
    }
    elsif ($name eq 'edit_file') {
        my $base = extract_basename($input->{path});
        push @parts, (length($base) ? $base : '?');
        my $range = _format_line_range($input);
        push @parts, $range if defined $range;
        my $rep = defined $input->{content} ? $input->{content}
                : defined $input->{replacement} ? $input->{replacement}
                : undef;
        if (defined $rep && length($rep) > 0) {
            push @parts, truncate_text($rep, 20);
        }
    }
    elsif ($name eq 'run_shell') {
        if (defined $input->{command} && length($input->{command}) > 0) {
            push @parts, truncate_text($input->{command}, 20);
        }
    }
    elsif ($name eq 'list_dir') {
        my $target = (!defined $input->{path} || $input->{path} eq '' || $input->{path} eq '.')
                   ? '.'
                   : extract_basename($input->{path});
        push @parts, $target;
    }
    elsif ($name eq 'invoke_subagent') {
        my $type = (defined $input->{subagent_type} && length $input->{subagent_type})
                 ? $input->{subagent_type}
                 : 'build';
        push @parts, "[$type]";
        if (defined $input->{task} && length $input->{task}) {
            push @parts, truncate_text($input->{task}, 30);
        }
    }
    else {
        for my $k (sort keys %$input) {
            my $v = $input->{$k};
            if (defined $v && !ref($v) && length($v) > 0) {
                push @parts, truncate_text($v, 20);
                last;
            }
        }
    }

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

    my $c_yellow  = defined $COLOR_DIM   ? $COLOR_DIM   : '';
    my $c_magenta = defined $COLOR_MODEL ? $COLOR_MODEL : '';
    my $c_reset   = defined $COLOR_RESET ? $COLOR_RESET : '';

    my @banner_lines = (
        [ "   _____          _       ", "  ___                    _   " ],
        [ "  / ____|        | |      ", " / _ \\                  | |  " ],
        [ " | |     ___   __| | ___  ", "/ /_\\ \\ __ _  ___ _ __  | |_ " ],
        [ " | |    / _ \\ / _` |/ _ \\ ", "|  _  |/ _` |/ _ \\ '_ \\ | __|" ],
        [ " | |___| (_) | (_| |  __/ ", "| | | | (_| |  __/ | | || |_ " ],
        [ "  \\_____\\___/ \\__,_|\\___| ", "\\_| |_/\\__, |\\___|_| |_| \\__|" ],
        [ "                          ", "        __/ |                " ],
        [ "                          ", "       |___/                 " ],
    );

    for my $pair (@banner_lines) {
        my ($code_part, $agent_part) = @$pair;
        if ($code_part =~ /\S/) {
            print $out_fh $c_yellow . $code_part . $c_reset . $c_magenta . $agent_part . $c_reset . "\n";
        }
        else {
            print $out_fh $code_part . $c_magenta . $agent_part . $c_reset . "\n";
        }
    }
    print $out_fh "\n";

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
    print $out_fh " Type /help for commands, /models to switch model.\n";
}


