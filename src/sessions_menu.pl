# --- Interactive /sessions Menu & Session Listing Helper ---

sub _normalize_path {
    my ($p) = @_;
    return '' unless defined $p;
    $p =~ s{/+$}{} if length($p) > 1;
    return $p;
}

sub get_recent_sessions {
    my ($opt_cwd, $limit) = @_;
    $limit = 15 unless defined $limit && $limit =~ /^\d+$/ && $limit > 0;

    my $filter_cwd;
    if (!defined $opt_cwd) {
        $filter_cwd = eval { cwd() };
    }
    elsif (lc($opt_cwd) ne 'all') {
        $filter_cwd = $opt_cwd;
    }

    my $index = load_sessions_index();
    my $sessions = (ref($index) eq 'HASH' && ref($index->{sessions}) eq 'ARRAY')
        ? [ @{ $index->{sessions} } ]
        : [];

    if (defined $filter_cwd && length $filter_cwd) {
        my $norm_target = _normalize_path($filter_cwd);
        $sessions = [ grep {
            defined $_->{cwd} && (
                _normalize_path($_->{cwd}) eq $norm_target ||
                lc(_normalize_path($_->{cwd})) eq lc($norm_target)
            )
        } @$sessions ];
    }

    if (scalar(@$sessions) > $limit) {
        $sessions = [ @$sessions[0 .. $limit - 1] ];
    }

    return $sessions;
}

sub _format_session_menu_row {
    my ($entry, $is_current, $is_all) = @_;
    return '' unless defined $entry && ref($entry) eq 'HASH';

    my $cur_mark = $is_current ? '*' : ' ';
    my $title = (defined $entry->{title} && length($entry->{title})) ? $entry->{title} : '(untitled)';
    $title = substr($title, 0, 25);

    my $id = defined $entry->{id} ? $entry->{id} : 'unknown';
    my $updated = (defined $entry->{updated_at} && $entry->{updated_at} > 0)
        ? $entry->{updated_at}
        : ($entry->{created_at} || time());
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($updated);
    my $date_str = sprintf("%04d-%02d-%02d %02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min);

    my $mc = $entry->{message_count} || 0;
    my $msg_label = ($mc == 1 ? "1 msg" : "$mc msgs");

    my $row = sprintf("%s %-25s [%s] %s (%s)", $cur_mark, $title, $id, $date_str, $msg_label);
    if ($is_all) {
        my $dir_name = (defined $entry->{cwd} && length($entry->{cwd}))
            ? File::Basename::basename($entry->{cwd})
            : 'unknown';
        $dir_name = '/' if $dir_name eq '';
        $row .= " [$dir_name]";
    }
    return $row;
}

sub select_session_nontty {
    my ($sessions, $current_id, $is_all, $in_fh, $out_fh, $cwd_name) = @_;
    return undef unless defined $sessions && ref($sessions) eq 'ARRAY' && @$sessions;
    $in_fh  ||= \*STDIN;
    $out_fh ||= \*STDOUT;

    my $header;
    if ($is_all) {
        $header = "All recent sessions:";
    }
    else {
        my $dname = (defined $cwd_name && length($cwd_name)) ? $cwd_name : File::Basename::basename(eval { cwd() } || '.');
        $header = "Recent sessions ($dname):";
    }
    print $out_fh "$header\n";

    for (my $i = 0; $i < @$sessions; $i++) {
        my $s = $sessions->[$i];
        my $is_current = (defined $current_id && defined $s->{id} && $s->{id} eq $current_id) ? 1 : 0;
        my $row = _format_session_menu_row($s, $is_current, $is_all);
        print $out_fh sprintf("  %2d) %s\n", $i + 1, $row);
    }

    print $out_fh "Select session [1-" . scalar(@$sessions) . ", ID, or Enter to cancel]: ";
    my $line = <$in_fh>;
    return undef unless defined $line;
    $line =~ s/^\s+|\s+$//g;
    return undef if $line eq '' || $line =~ /^(?:q|quit|exit|cancel)$/i;

    if ($line =~ /^\d+$/ && $line >= 1 && $line <= @$sessions) {
        return $sessions->[$line - 1]{id};
    }

    my $lline = lc($line);
    for my $s (@$sessions) {
        return $s->{id} if defined $s->{id} && lc($s->{id}) eq $lline;
    }
    my @prefix_matches;
    for my $s (@$sessions) {
        push @prefix_matches, $s->{id} if defined $s->{id} && index(lc($s->{id}), $lline) == 0;
    }
    if (scalar(@prefix_matches) == 1) {
        return $prefix_matches[0];
    }

    return undef;
}

sub _render_session_menu_lines {
    my ($sessions, $cursor, $window_start, $page_size, $current_id, $is_all, $cwd_name, $num_buf) = @_;
    my $total = scalar(@$sessions);
    my $window_end = $window_start + $page_size - 1;
    $window_end = $total - 1 if $window_end >= $total;

    my @lines;
    my $header;
    my $dname = (defined $cwd_name && length($cwd_name)) ? $cwd_name : File::Basename::basename(eval { cwd() } || '.');
    if ($is_all) {
        $header = sprintf("All recent sessions [showing %d-%d of %d] (Up/Down or j/k, Enter: select, Esc/q: cancel):",
            $window_start + 1, $window_end + 1, $total);
    }
    else {
        $header = sprintf("Recent sessions (%s) [showing %d-%d of %d] (Up/Down or j/k, Enter: select, Esc/q: cancel):",
            $dname, $window_start + 1, $window_end + 1, $total);
    }
    push @lines, $header;

    for (my $i = $window_start; $i <= $window_end; $i++) {
        my $s = $sessions->[$i];
        my $is_current = (defined $current_id && defined $s->{id} && $s->{id} eq $current_id) ? 1 : 0;
        my $prefix = ($i == $cursor) ? "> " : "  ";
        my $row = _format_session_menu_row($s, $is_current, $is_all);
        my $line = sprintf("%s%2d) %s", $prefix, $i + 1, $row);
        if ($i == $cursor && defined $COLOR_RESET && $COLOR_RESET ne '') {
            $line = "\x1b[1;7m" . $line . $COLOR_RESET;
        }
        push @lines, $line;
    }

    if (defined $num_buf && $num_buf ne '') {
        push @lines, "Jump to: $num_buf" . "_";
    }

    return @lines;
}

sub select_session_interactive {
    my ($sessions, $current_id, $is_all, $in_fh, $out_fh, $cwd_name) = @_;
    $in_fh  = \*STDIN  unless defined $in_fh;
    $out_fh = \*STDOUT unless defined $out_fh;

    return undef unless defined $sessions && ref($sessions) eq 'ARRAY' && @$sessions;

    my $is_tty = -t $in_fh;
    if (!$is_tty && !$FORCE_RAW && !$ENV{CLAUDE_TEST_RAW}) {
        return select_session_nontty($sessions, $current_id, $is_all, $in_fh, $out_fh, $cwd_name);
    }

    cursor_show();

    my $orig_stty;
    if ($is_tty) {
        $orig_stty = `stty -g 2>/dev/null`;
        chomp $orig_stty if defined $orig_stty;
        system('stty', 'raw', '-echo', '-opost');
    }

    my $PAGE_SIZE = 15;
    my $cursor = 0;
    if (defined $current_id) {
        for (my $i = 0; $i < @$sessions; $i++) {
            if (defined $sessions->[$i]{id} && $sessions->[$i]{id} eq $current_id) {
                $cursor = $i;
                last;
            }
        }
    }

    my $window_start = 0;
    if ($cursor >= $PAGE_SIZE) {
        $window_start = $cursor - $PAGE_SIZE + 1;
    }

    my $num_buf = '';
    my $lines_drawn = 0;
    my $selected_id;

    eval {
        while (1) {
            if ($cursor < $window_start) {
                $window_start = $cursor;
            }
            elsif ($cursor >= $window_start + $PAGE_SIZE) {
                $window_start = $cursor - $PAGE_SIZE + 1;
            }

            my @menu_lines = _render_session_menu_lines($sessions, $cursor, $window_start, $PAGE_SIZE, $current_id, $is_all, $cwd_name, $num_buf);

            if ($lines_drawn > 0) {
                print $out_fh "\x1b[${lines_drawn}A\r";
            }
            for my $line (@menu_lines) {
                print $out_fh "\x1b[2K" . $line . "\r\n";
            }
            if ($lines_drawn > @menu_lines) {
                my $diff = $lines_drawn - @menu_lines;
                for (1 .. $diff) {
                    print $out_fh "\x1b[2K\r\n";
                }
                print $out_fh "\x1b[${diff}A\r";
            }
            $lines_drawn = scalar(@menu_lines);

            my ($action, $val) = _read_menu_key($in_fh);

            if ($action eq 'enter') {
                $selected_id = $sessions->[$cursor]{id};
                last;
            }
            elsif ($action eq 'cancel' || $action eq 'eof') {
                $selected_id = undef;
                last;
            }
            elsif ($action eq 'up') {
                $num_buf = '';
                $cursor-- if $cursor > 0;
            }
            elsif ($action eq 'down') {
                $num_buf = '';
                $cursor++ if $cursor < @$sessions - 1;
            }
            elsif ($action eq 'digit') {
                $num_buf .= $val;
                my $target = int($num_buf) - 1;
                if ($target >= 0 && $target < @$sessions) {
                    $cursor = $target;
                }
                elsif ($target >= @$sessions) {
                    $num_buf = $val;
                    my $t2 = int($num_buf) - 1;
                    $cursor = $t2 if ($t2 >= 0 && $t2 < @$sessions);
                }
            }
            elsif ($action eq 'backspace') {
                if (length($num_buf) > 0) {
                    chop $num_buf;
                    if (length($num_buf) > 0) {
                        my $target = int($num_buf) - 1;
                        $cursor = $target if ($target >= 0 && $target < @$sessions);
                    }
                }
            }
            elsif ($action eq 'other') {
                if (defined $val) {
                    if ($val eq 'j') {
                        $num_buf = '';
                        $cursor++ if $cursor < @$sessions - 1;
                    }
                    elsif ($val eq 'k') {
                        $num_buf = '';
                        $cursor-- if $cursor > 0;
                    }
                    elsif (lc($val) eq 'q') {
                        $selected_id = undef;
                        last;
                    }
                }
            }
        }
    };
    my $eval_err = $@;

    if ($is_tty && defined $orig_stty && $orig_stty ne '') {
        system('stty', $orig_stty);
    }

    print $out_fh "\r\n";

    die $eval_err if $eval_err;
    cursor_hide();
    return $selected_id;
}

sub handle_sessions_command {
    my ($args, $in_fh, $out_fh) = @_;
    $in_fh  ||= \*STDIN;
    $out_fh ||= \*STDOUT;

    $args =~ s/^\s+|\s+$//g if defined $args;
    my $is_all = (defined $args && lc($args) eq 'all') ? 1 : 0;

    if (defined $args && length($args) && !$is_all) {
        print $out_fh "Usage: /sessions [all]\n";
        return;
    }

    my $cwd = eval { cwd() };
    my $sessions = get_recent_sessions($is_all ? 'all' : $cwd, 15);

    if (!defined $sessions || !@$sessions) {
        if ($is_all) {
            print $out_fh "No saved sessions found.\n";
        }
        else {
            print $out_fh "No saved sessions found for this directory. Use /sessions all to see sessions from all directories.\n";
        }
        return;
    }

    my $current_id = (defined $CURRENT_SESSION && ref($CURRENT_SESSION) eq 'HASH')
        ? $CURRENT_SESSION->{id}
        : undef;

    my $cwd_name = (defined $cwd && length($cwd)) ? File::Basename::basename($cwd) : '.';
    my $selected_id = select_session_interactive($sessions, $current_id, $is_all, $in_fh, $out_fh, $cwd_name);

    if (defined $selected_id && length($selected_id)) {
        switch_to_session($selected_id, $out_fh);
    }
}

1;
