
sub get_current_model {
    return $MODEL;
}

sub get_current_provider {
    return $PROVIDER;
}

sub get_current_api_url {
    return $API_URL;
}

sub get_auto_mode {
    return $AUTO_MODE;
}

sub set_auto_mode {
    my ($val) = @_;
    $AUTO_MODE = $val ? 1 : 0;
    return $AUTO_MODE;
}

sub get_max_tokens {
    return $MAX_TOKENS;
}

sub set_max_tokens {
    my ($val) = @_;
    return undef unless defined $val;
    my $tokens = parse_context_size($val);
    return undef unless defined $tokens;
    $MAX_TOKENS = $tokens;
    $ENV{CLAUDE_MAX_TOKENS} = $tokens;
    return $MAX_TOKENS;
}

sub generate_session_id {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $SESSION_COUNTER++;
    return sprintf("session-%04d%02d%02d-%02d%02d%02d-%03d",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec, $SESSION_COUNTER);
}

sub init_session {
    my ($id) = @_;
    $id = generate_session_id() unless defined $id && length $id;
    my $now = time();
    $CURRENT_SESSION = {
        id         => $id,
        created_at => $now,
        provider   => $PROVIDER,
        model      => $MODEL,
        messages   => [],
        stats      => {
            prompt_tokens     => 0,
            completion_tokens => 0,
            total_tokens      => 0,
            tool_calls        => 0,
            subagents         => 0,
            tool_counts       => {},
            subagent_counts   => {},
            api_calls         => 0,
            start_time        => $now,
        },
    };
    return $CURRENT_SESSION;
}

sub get_session_stats {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';

    if (!defined $session->{stats} || ref($session->{stats}) ne 'HASH') {
        my $now = defined $session->{created_at} ? $session->{created_at} : time();
        $session->{stats} = {
            prompt_tokens     => 0,
            completion_tokens => 0,
            total_tokens      => 0,
            tool_calls        => 0,
            subagents         => 0,
            tool_counts       => {},
            subagent_counts   => {},
            api_calls         => 0,
            start_time        => $now,
        };
    }
    return $session->{stats};
}

sub record_session_tokens {
    my ($session, $prompt, $completion, $total);
    if (@_ && ref($_[0]) eq 'HASH') {
        ($session, $prompt, $completion, $total) = @_;
    } else {
        ($prompt, $completion, $total, $session) = @_;
    }
    my $stats = get_session_stats($session);
    return undef unless defined $stats;

    $stats->{api_calls}++;
    $prompt = 0 unless defined $prompt && $prompt =~ /^\d+$/;
    $completion = 0 unless defined $completion && $completion =~ /^\d+$/;
    if (!defined $total || $total !~ /^\d+$/) {
        $total = $prompt + $completion;
    }
    $stats->{prompt_tokens}     += $prompt;
    $stats->{completion_tokens} += $completion;
    $stats->{total_tokens}      += $total;

    return $stats;
}

sub record_session_tool_call {
    my ($session, $tool_name);
    if (@_ && ref($_[0]) eq 'HASH') {
        ($session, $tool_name) = @_;
    } else {
        ($tool_name, $session) = @_;
    }
    my $stats = get_session_stats($session);
    return undef unless defined $stats;

    $stats->{tool_calls}++;
    if (defined $tool_name && length $tool_name) {
        $stats->{tool_counts} ||= {};
        $stats->{tool_counts}{$tool_name} = ($stats->{tool_counts}{$tool_name} || 0) + 1;
    }
    return $stats;
}

sub record_session_subagent {
    my ($session, $type);
    if (@_ && ref($_[0]) eq 'HASH') {
        ($session, $type) = @_;
    } else {
        ($type, $session) = @_;
    }
    my $stats = get_session_stats($session);
    return undef unless defined $stats;

    $stats->{subagents}++;
    if (defined $type && length $type) {
        $stats->{subagent_counts} ||= {};
        $stats->{subagent_counts}{$type} = ($stats->{subagent_counts}{$type} || 0) + 1;
    }
    return $stats;
}

sub get_current_session {
    return $CURRENT_SESSION if defined $CURRENT_SESSION;
    return init_session();
}

sub archive_session {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return unless defined $session;
    # Extension hook: in future releases, serialize $session to disk
    # (e.g. ~/.code-agent-sessions/$session->{id}.json) for resume/continue.
    return $session;
}

sub handle_new_command {
    my ($out_fh, $session) = @_;
    $out_fh ||= \*STDOUT;
    $session = $CURRENT_SESSION unless defined $session;

    archive_session($session);
    my $new_session = init_session();

    print $out_fh "Started a new conversation. Chat history cleared.\n";
    return $new_session;
}

sub show_help {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    print $out_fh "\nAvailable commands:\n";
    print $out_fh "  /new     - Start a new conversation (clears chat history)\n";
    print $out_fh "  /stats   - Show current session statistics and token usage\n";
    print $out_fh "  /models  - View and switch available AI models\n";
    print $out_fh "  /ctx     - View or set max output tokens per response (e.g. /ctx 64k)\n";
    print $out_fh "  /compact - Compact conversation history to free context and memory\n";
    print $out_fh "  /claude  - Switch to Anthropic Claude\n";
    print $out_fh "  /gemini  - Switch to Google Gemini\n";
    print $out_fh "  /openai  - Switch to OpenAI-compatible endpoint (alias: /local)\n";
    print $out_fh "  /auto    - Enable auto mode (run tools without confirmation)\n";
    print $out_fh "  /manual  - Enable manual mode (require tool confirmation)\n";
    print $out_fh "  /mcp     - Manage remote Model Context Protocol (MCP) servers\n";
    print $out_fh "  /help    - Show available commands\n";
    print $out_fh "  exit     - Exit the agent (or Ctrl-D)\n";
}

sub handle_ctx_command {
    my ($args, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    if (!defined $args || $args =~ /^\s*$/) {
        my $cur = get_max_tokens();
        my $formatted = format_context_size($cur);
        print $out_fh "Current max output tokens: $cur ($formatted)\n";
        print $out_fh "Usage: /ctx <tokens> (e.g. /ctx 8k, /ctx 64k, /ctx 65536)\n";
        return $cur;
    }

    $args =~ s/^\s+|\s+$//g;
    my $tokens = parse_context_size($args);
    if (!defined $tokens) {
        print $out_fh "Invalid token count '$args'. Must be a positive integer or unit (e.g. 8k, 64k, 1m, 65536).\n";
        return undef;
    }

    set_max_tokens($tokens);
    my $formatted = format_context_size($tokens);
    print $out_fh "Max output tokens set to $tokens ($formatted).\n";
    return $tokens;
}

sub handle_auto_command {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    set_auto_mode(1);
    print $out_fh "Auto mode enabled. Tools will execute without user confirmation.\n";
    return 1;
}

sub handle_manual_command {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    set_auto_mode(0);
    print $out_fh "Manual mode enabled. Tools will require user confirmation.\n";
    return 0;
}

sub handle_models_command {
    my ($in_fh, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    my ($models, $err) = fetch_models();
    if ($err || !defined $models || !@$models) {
        my $msg = defined $err ? $err : "No models found.";
        print $out_fh "Error fetching models: $msg\n";
        return undef;
    }

    my $selected = select_model_interactive($models, $MODEL, $in_fh, $out_fh);
    if (defined $selected && $selected ne '') {
        $MODEL = $selected;
        $ENV{CLAUDE_MODEL} = $selected;
        if (defined $PROVIDER && $PROVIDER eq 'gemini') {
            $API_URL = "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent";
        }
        print $out_fh "Switched model to: $MODEL\n";
    }
    else {
        print $out_fh "Cancelled. Staying on $MODEL\n";
    }
    return $MODEL;
}

sub compact_tool_result_content {
    my ($content, %opts) = @_;
    return $content unless defined $content && length($content);

    my $max_lines  = defined $opts{max_lines}  ? int($opts{max_lines})  : (defined $ENV{CLAUDE_COMPACT_MAX_LINES}  ? int($ENV{CLAUDE_COMPACT_MAX_LINES})  : 20);
    my $head_lines = defined $opts{head_lines} ? int($opts{head_lines}) : 8;
    my $tail_lines = defined $opts{tail_lines} ? int($opts{tail_lines}) : 8;
    my $max_bytes  = defined $opts{max_bytes}  ? int($opts{max_bytes})  : (defined $ENV{CLAUDE_COMPACT_MAX_BYTES}  ? int($ENV{CLAUDE_COMPACT_MAX_BYTES})  : 2000);
    my $head_bytes = defined $opts{head_bytes} ? int($opts{head_bytes}) : 500;
    my $tail_bytes = defined $opts{tail_bytes} ? int($opts{tail_bytes}) : 500;

    # Check for <untrusted_tool_output tool="..."> wrapper
    if ($content =~ /^<untrusted_tool_output tool="([^"]+)">\n([\s\S]*)\n<\/untrusted_tool_output>$/) {
        my ($tool_name, $inner) = ($1, $2);
        my $compacted_inner = compact_tool_result_content($inner, %opts);
        if ($compacted_inner ne $inner) {
            return "<untrusted_tool_output tool=\"$tool_name\">\n$compacted_inner\n</untrusted_tool_output>";
        }
        return $content;
    }

    # If already contains truncation notice, do not re-truncate
    if ($content =~ /\[\.\.\. \d+ (?:lines|bytes) truncated for context budget \.\.\.\]/) {
        return $content;
    }

    my $text = $content;

    # 1. Line-based truncation
    my @lines = split(/\n/, $text, -1);
    if (scalar(@lines) > $max_lines) {
        my $truncated_lines = scalar(@lines) - ($head_lines + $tail_lines);
        if ($truncated_lines > 0) {
            my @head = @lines[0 .. ($head_lines - 1)];
            my @tail = @lines[(scalar(@lines) - $tail_lines) .. (scalar(@lines) - 1)];
            my $notice = "[... $truncated_lines lines truncated for context budget ...]";
            $text = join("\n", @head) . "\n\n$notice\n\n" . join("\n", @tail);
        }
    }

    # 2. Byte-based truncation
    if (length($text) > $max_bytes) {
        my $excess_bytes = length($text) - ($head_bytes + $tail_bytes);
        if ($excess_bytes > 0) {
            my $head = substr($text, 0, $head_bytes);
            my $tail = substr($text, -$tail_bytes);
            my $notice = "[... $excess_bytes bytes truncated for context budget ...]";
            $text = $head . "\n\n$notice\n\n" . $tail;
        }
    }

    return $text;
}

sub estimate_session_chars {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return 0 unless defined $session && ref($session->{messages}) eq 'ARRAY';

    my $total = 0;
    for my $m (@{ $session->{messages} }) {
        if (!ref($m->{content})) {
            $total += length($m->{content}) if defined $m->{content};
        }
        elsif (ref($m->{content}) eq 'ARRAY') {
            for my $b (@{ $m->{content} }) {
                if (ref($b) eq 'HASH') {
                    if (defined $b->{text} && !ref($b->{text})) {
                        $total += length($b->{text});
                    }
                    if (defined $b->{content} && !ref($b->{content})) {
                        $total += length($b->{content});
                    }
                }
            }
        }
    }
    return $total;
}

sub _find_user_turn_indices {
    my ($messages) = @_;
    my @indices;
    for (my $i = 0; $i < scalar(@$messages); $i++) {
        my $m = $messages->[$i];
        if ($m->{role} eq 'user') {
            my $is_tool_result = 0;
            if (ref($m->{content}) eq 'ARRAY') {
                for my $b (@{ $m->{content} }) {
                    if (ref($b) eq 'HASH' && defined $b->{type} && $b->{type} eq 'tool_result') {
                        $is_tool_result = 1;
                        last;
                    }
                }
            }
            push @indices, $i unless $is_tool_result;
        }
    }
    if (!@indices) {
        for (my $i = 0; $i < scalar(@$messages); $i++) {
            push @indices, $i if $messages->[$i]{role} eq 'user';
        }
    }
    return @indices;
}

sub count_user_turns {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return 0 unless defined $session && ref($session->{messages}) eq 'ARRAY';
    my @indices = _find_user_turn_indices($session->{messages});
    return scalar(@indices);
}

sub compact_session_history {
    my ($session, %opts) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return { compacted_count => 0, bytes_saved => 0 } unless defined $session && ref($session->{messages}) eq 'ARRAY';

    my $keep_turns = defined $opts{keep_turns} ? int($opts{keep_turns})
        : (defined $ENV{CLAUDE_COMPACT_KEEP_TURNS} ? int($ENV{CLAUDE_COMPACT_KEEP_TURNS}) : 2);
    $keep_turns = 0 if $keep_turns < 0;

    my $messages = $session->{messages};
    my $total_msgs = scalar(@$messages);
    return { compacted_count => 0, bytes_saved => 0 } if $total_msgs == 0;

    my @user_turn_indices = _find_user_turn_indices($messages);
    my $cutoff_idx;
    if ($keep_turns == 0) {
        $cutoff_idx = $total_msgs;
    }
    elsif (@user_turn_indices <= $keep_turns) {
        $cutoff_idx = 0;
    }
    else {
        my $target = scalar(@user_turn_indices) - $keep_turns;
        $cutoff_idx = $user_turn_indices[$target];
    }

    my $compacted_count = 0;
    my $bytes_saved = 0;

    for (my $i = 0; $i < $cutoff_idx; $i++) {
        my $m = $messages->[$i];
        next unless ref($m->{content}) eq 'ARRAY';

        for my $block (@{ $m->{content} }) {
            next unless ref($block) eq 'HASH' && defined $block->{type} && $block->{type} eq 'tool_result';
            next unless defined $block->{content} && !ref($block->{content});

            my $orig = $block->{content};
            my $compacted = compact_tool_result_content($orig, %opts);
            if ($compacted ne $orig) {
                $block->{content} = $compacted;
                $compacted_count++;
                $bytes_saved += (length($orig) - length($compacted));
            }
        }
    }

    return {
        compacted_count => $compacted_count,
        bytes_saved     => $bytes_saved,
    };
}

sub auto_compact_session_if_needed {
    my ($session, %opts) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session->{messages}) eq 'ARRAY';

    my $enabled = defined $ENV{CLAUDE_AUTO_COMPACT} ? ($ENV{CLAUDE_AUTO_COMPACT} =~ /^(?:0|false|no|off)$/i ? 0 : 1) : 1;
    return undef unless $enabled;

    my $threshold_chars = defined $opts{threshold_chars} ? $opts{threshold_chars}
        : (defined $ENV{CLAUDE_COMPACT_THRESHOLD_CHARS} ? int($ENV{CLAUDE_COMPACT_THRESHOLD_CHARS}) : 100000);
    my $threshold_turns = defined $opts{threshold_turns} ? $opts{threshold_turns}
        : (defined $ENV{CLAUDE_COMPACT_THRESHOLD_TURNS} ? int($ENV{CLAUDE_COMPACT_THRESHOLD_TURNS}) : 10);

    my $total_chars = estimate_session_chars($session);
    my $total_turns = count_user_turns($session);

    if ($total_chars > $threshold_chars || $total_turns > $threshold_turns) {
        return compact_session_history($session, %opts);
    }
    return undef;
}

sub handle_compact_command {
    my ($out_fh, $session, %opts) = @_;
    $out_fh ||= \*STDOUT;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session;

    my $stats = compact_session_history($session, %opts);
    if ($stats->{compacted_count} > 0) {
        print $out_fh sprintf("Compacted session history: %d tool result(s) truncated, saved %d bytes.\n",
            $stats->{compacted_count}, $stats->{bytes_saved});
    }
    else {
        print $out_fh "Session history is already compact (no older tool outputs to truncate).\n";
    }
    return $stats;
}

sub _commify {
    my ($num) = @_;
    return '0' unless defined $num && length($num);
    my $val = "$num";
    1 while $val =~ s/^(-?\d+)(\d{3})/$1,$2/;
    return $val;
}

sub format_uptime {
    my ($seconds) = @_;
    $seconds = 0 unless defined $seconds && $seconds =~ /^-?\d+$/;
    $seconds = 0 if $seconds < 0;

    my $s = $seconds % 60;
    my $m = int($seconds / 60) % 60;
    my $h = int($seconds / 3600);

    if ($h > 0) {
        return sprintf("%dh %dm %ds", $h, $m, $s);
    }
    elsif ($m > 0) {
        return sprintf("%dm %ds", $m, $s);
    }
    return sprintf("%ds", $s);
}

sub get_context_window_size {
    my ($provider) = @_;
    $provider = (defined &get_current_provider ? get_current_provider() : undef) || $PROVIDER || 'anthropic'
        unless defined $provider && length($provider);
    $provider = lc($provider);

    if ($provider eq 'gemini') {
        return 1048576; # 1m
    }
    elsif ($provider eq 'openai') {
        return 131072;  # 128k
    }
    elsif ($provider eq 'anthropic') {
        return 204800;  # 200k
    }
    return 204800;
}

sub format_session_stats {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    $session = get_current_session() unless defined $session;
    return '' unless defined $session && ref($session) eq 'HASH';

    my $stats = get_session_stats($session);
    my $now = time();
    my $start_time = defined $stats->{start_time} ? $stats->{start_time}
                   : (defined $session->{created_at} ? $session->{created_at} : $now);
    my $uptime_sec = $now - $start_time;
    my $uptime_str = format_uptime($uptime_sec);

    my $prov = defined $session->{provider} ? $session->{provider}
             : ((defined &get_current_provider ? get_current_provider() : undef) || $PROVIDER || 'anthropic');
    my $mod  = defined $session->{model} ? $session->{model}
             : ((defined &get_current_model ? get_current_model() : undef) || $MODEL || 'default');

    my $msgs = ref($session->{messages}) eq 'ARRAY' ? $session->{messages} : [];
    my $msg_count = scalar(@$msgs);
    my $char_count = estimate_session_chars($session);
    my $est_tokens = int($char_count / 4);

    my $window_size = get_context_window_size($prov);
    my $window_fmt  = format_context_size($window_size);
    my $util_pct    = ($window_size > 0) ? (($est_tokens / $window_size) * 100) : 0;

    my $max_tokens  = defined &get_max_tokens ? get_max_tokens() : $MAX_TOKENS;
    my $max_fmt     = format_context_size($max_tokens);

    my $c_reset  = defined $COLOR_RESET  ? $COLOR_RESET  : '';
    my $c_hdr    = defined $COLOR_HEADER ? $COLOR_HEADER : '';

    my @lines;
    push @lines, $c_hdr . "Session Statistics:" . $c_reset;
    push @lines, sprintf("  Session ID:      %s", $session->{id} || 'unknown');
    push @lines, sprintf("  Provider / Model: %s / %s", $prov, $mod);
    push @lines, sprintf("  Uptime:          %s", $uptime_str);
    push @lines, "";

    push @lines, $c_hdr . "Active Context:" . $c_reset;
    push @lines, sprintf("  Active Messages:    %s", _commify($msg_count));
    push @lines, sprintf("  Active Characters:  %s", _commify($char_count));
    push @lines, sprintf("  Estimated Tokens:   %s (~4 chars/token)", _commify($est_tokens));
    push @lines, sprintf("  Context Window:     %s (%s) [utilization: %.2f%%]",
        _commify($window_size), $window_fmt, $util_pct);
    push @lines, sprintf("  Max Output Tokens:  %s (%s)", _commify($max_tokens), $max_fmt);
    push @lines, "";

    push @lines, $c_hdr . "Cumulative Token Usage:" . $c_reset;
    push @lines, sprintf("  API Calls:         %s", _commify($stats->{api_calls}));
    push @lines, sprintf("  Prompt Tokens:     %s", _commify($stats->{prompt_tokens}));
    push @lines, sprintf("  Completion Tokens: %s", _commify($stats->{completion_tokens}));
    push @lines, sprintf("  Total Tokens:      %s", _commify($stats->{total_tokens}));
    push @lines, "";

    my $tool_calls = $stats->{tool_calls} || 0;
    if ($tool_calls == 0) {
        push @lines, $c_hdr . "Tool Calls:" . $c_reset . " 0 (none)";
    }
    else {
        push @lines, $c_hdr . "Tool Calls:" . $c_reset . sprintf(" %s", _commify($tool_calls));
        my $counts = ref($stats->{tool_counts}) eq 'HASH' ? $stats->{tool_counts} : {};
        my @sorted_tools = sort { ($counts->{$b} || 0) <=> ($counts->{$a} || 0) || $a cmp $b } keys %$counts;
        for my $tool (@sorted_tools) {
            push @lines, sprintf("  - %s: %s", $tool, _commify($counts->{$tool}));
        }
    }
    push @lines, "";

    my $subagents = $stats->{subagents} || 0;
    if ($subagents == 0) {
        push @lines, $c_hdr . "Sub-Agents:" . $c_reset . " 0 (none)";
    }
    else {
        push @lines, $c_hdr . "Sub-Agents:" . $c_reset . sprintf(" %s", _commify($subagents));
        my $sa_counts = ref($stats->{subagent_counts}) eq 'HASH' ? $stats->{subagent_counts} : {};
        my @sorted_sa = sort { ($sa_counts->{$b} || 0) <=> ($sa_counts->{$a} || 0) || $a cmp $b } keys %$sa_counts;
        for my $type (@sorted_sa) {
            push @lines, sprintf("  - %s: %s", $type, _commify($sa_counts->{$type}));
        }
    }

    return join("\n", @lines);
}

sub handle_stats_command {
    my ($out_fh, $session) = @_;
    $out_fh ||= \*STDOUT;
    $session = $CURRENT_SESSION unless defined $session;
    $session = get_current_session() unless defined $session;

    my $formatted = format_session_stats($session);
    print $out_fh $formatted . "\n";
    return 1;
}


