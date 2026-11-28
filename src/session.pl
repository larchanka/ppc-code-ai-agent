
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

sub _default_session_stats {
    return {
        api_calls          => 0,
        input_tokens       => 0,
        output_tokens      => 0,
        cache_read_tokens  => 0,
        cache_write_tokens => 0,
        tool_calls         => 0,
        subagent_calls     => 0,
        compact_count      => 0,
        bytes_saved        => 0,
        tools              => {},
    };
}

sub get_session_stats {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';
    if (!defined $session->{stats} || ref($session->{stats}) ne 'HASH') {
        $session->{stats} = _default_session_stats();
    }
    return $session->{stats};
}

sub record_session_api_usage {
    my ($resp, $session, $provider) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';
    $provider = $session->{provider} || $PROVIDER unless defined $provider;

    my $stats = get_session_stats($session);
    $stats->{api_calls}++;

    my $usage = extract_api_usage($resp, $provider);
    if ($usage && ref($usage) eq 'HASH') {
        $stats->{input_tokens}       += ($usage->{input_tokens} || 0);
        $stats->{output_tokens}      += ($usage->{output_tokens} || 0);
        $stats->{cache_read_tokens}  += ($usage->{cache_read_tokens} || 0);
        $stats->{cache_write_tokens} += ($usage->{cache_write_tokens} || 0);
    }
    return $stats;
}

sub record_session_tool_call {
    my ($tool_name, $session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';

    my $stats = get_session_stats($session);
    $stats->{tool_calls}++;
    if (defined $tool_name && length($tool_name)) {
        $stats->{tools}{$tool_name}++;
    }
    return $stats;
}

sub record_session_subagent_call {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';

    my $stats = get_session_stats($session);
    $stats->{subagent_calls}++;
    return $stats;
}

sub generate_session_id {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $prefix = sprintf("%02d%02d", $mon + 1, $mday);
    my $dir = eval { get_sessions_dir() };

    for (my $attempt = 0; $attempt < 100; $attempt++) {
        my $suffix = sprintf("%04x", int(rand(65536)));
        my $id = "$prefix-$suffix";
        if (defined $dir && -d $dir && -f File::Spec->catfile($dir, "$id.json")) {
            next;
        }
        $SESSION_COUNTER++;
        return $id;
    }

    $SESSION_COUNTER++;
    return sprintf("%s-%04x", $prefix, ($SESSION_COUNTER & 0xffff));
}

sub init_session {
    my ($id) = @_;
    $id = generate_session_id() unless defined $id && length $id;
    my $now = time();
    my $cwd = eval { cwd() };
    $cwd = '' unless defined $cwd;
    $CURRENT_SESSION = {
        id              => $id,
        title           => '',
        title_attempted => 0,
        cwd             => $cwd,
        created_at      => $now,
        updated_at      => $now,
        provider        => $PROVIDER,
        model           => $MODEL,
        messages        => [],
        stats           => _default_session_stats(),
    };
    return $CURRENT_SESSION;
}

sub get_current_session {
    return $CURRENT_SESSION if defined $CURRENT_SESSION;
    return init_session();
}

sub archive_session {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return unless defined $session;
    save_session($session);
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
    print $out_fh "  /new      - Start a new conversation (clears chat history)\n";
    print $out_fh "  /session  - Switch, delete, or manage sessions (/session <id>, /session delete <id>)\n";
    print $out_fh "  /sessions - Browse and resume recent sessions (/sessions, /sessions all)\n";
    print $out_fh "  /models   - View and switch available AI models\n";
    print $out_fh "  /ctx      - View or set max output tokens per response (e.g. /ctx 64k)\n";
    print $out_fh "  /compact  - Compact conversation history to free context and memory\n";
    print $out_fh "  /stats    - View current session statistics (duration, tokens, turns, tools)\n";
    print $out_fh "  /claude   - Switch to Anthropic Claude\n";
    print $out_fh "  /gemini   - Switch to Google Gemini\n";
    print $out_fh "  /openai   - Switch to OpenAI-compatible endpoint (alias: /local)\n";
    print $out_fh "  /auto     - Enable auto mode (run tools without confirmation)\n";
    print $out_fh "  /manual   - Enable manual mode (require tool confirmation)\n";
    print $out_fh "  /mcp      - Manage remote Model Context Protocol (MCP) servers\n";
    print $out_fh "  /help     - Show available commands\n";
    print $out_fh "  exit      - Exit the agent (or Ctrl-D)\n";
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

sub count_assistant_turns {
    my ($session) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return 0 unless defined $session && ref($session->{messages}) eq 'ARRAY';
    my $count = 0;
    for my $m (@{ $session->{messages} }) {
        if (ref($m) eq 'HASH' && defined $m->{role} && $m->{role} eq 'assistant') {
            $count++;
        }
    }
    return $count;
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

    if ($compacted_count > 0) {
        my $stats = get_session_stats($session);
        if ($stats) {
            $stats->{compact_count} += $compacted_count;
            $stats->{bytes_saved}   += $bytes_saved;
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
        save_session($session);
        print $out_fh sprintf("Compacted session history: %d tool result(s) truncated, saved %d bytes.\n",
            $stats->{compacted_count}, $stats->{bytes_saved});
    }
    else {
        print $out_fh "Session history is already compact (no older tool outputs to truncate).\n";
    }
    return $stats;
}

sub handle_stats_command {
    my ($out_fh, $session) = @_;
    $out_fh ||= \*STDOUT;
    $session = $CURRENT_SESSION unless defined $session;

    if (!defined $session) {
        print $out_fh "No active session.\n";
        return undef;
    }

    my $report = format_session_stats($session);
    print $out_fh $report;
    return 1;
}

# ------------------------------------------------------------------
# Auto-Title Generation via LLM with Fallback
# ------------------------------------------------------------------

sub _sanitize_session_title {
    my ($raw) = @_;
    return '' unless defined $raw;
    my $title = $raw;
    $title =~ s/[^A-Za-z0-9 ]//g;
    $title =~ s/\s+/ /g;
    $title =~ s/^\s+|\s+$//g;
    if (length($title) > 25) {
        $title = substr($title, 0, 25);
        $title =~ s/\s+$//;
    }
    return $title;
}

sub sanitize_session_title {
    return _sanitize_session_title(@_);
}

sub _generate_fallback_title {
    my ($first_prompt, $session_or_id) = @_;
    my $session_id = ref($session_or_id) eq 'HASH' ? $session_or_id->{id} : $session_or_id;
    my $sanitized = _sanitize_session_title($first_prompt);
    if (defined $sanitized && length($sanitized)) {
        return $sanitized;
    }
    $session_id = '' unless defined $session_id;
    return "Session $session_id";
}

sub _extract_first_user_prompt {
    my ($session) = @_;
    return '' unless defined $session && ref($session->{messages}) eq 'ARRAY';
    for my $msg (@{ $session->{messages} }) {
        next unless ref($msg) eq 'HASH' && defined $msg->{role} && $msg->{role} eq 'user';
        if (!ref($msg->{content})) {
            return $msg->{content} if defined $msg->{content} && $msg->{content} ne '';
        }
        elsif (ref($msg->{content}) eq 'ARRAY') {
            for my $block (@{ $msg->{content} }) {
                if (ref($block) eq 'HASH' && defined $block->{type} && $block->{type} eq 'text') {
                    return $block->{text} if defined $block->{text} && $block->{text} ne '';
                }
            }
        }
    }
    return '';
}

sub _has_assistant_message {
    my ($session) = @_;
    return 0 unless defined $session && ref($session->{messages}) eq 'ARRAY';
    for my $msg (@{ $session->{messages} }) {
        return 1 if ref($msg) eq 'HASH' && defined $msg->{role} && $msg->{role} eq 'assistant';
    }
    return 0;
}

sub generate_and_set_session_title {
    my ($session, $first_prompt) = @_;
    $session = $CURRENT_SESSION unless defined $session;
    return undef unless defined $session && ref($session) eq 'HASH';

    # Return early if title already set or title generation already attempted
    if ((defined $session->{title} && length($session->{title})) || $session->{title_attempted}) {
        return $session->{title};
    }
    $session->{title_attempted} = 1;

    # Extract first prompt from session messages if not provided
    if (!defined $first_prompt || $first_prompt eq '') {
        $first_prompt = _extract_first_user_prompt($session);
    }

    # Check CLAUDE_SESSION_AUTO_TITLE environment variable
    my $auto_title_disabled = 0;
    if (defined $ENV{CLAUDE_SESSION_AUTO_TITLE}) {
        if ($ENV{CLAUDE_SESSION_AUTO_TITLE} eq '0' || $ENV{CLAUDE_SESSION_AUTO_TITLE} =~ /^(?:false|no|off)$/i) {
            $auto_title_disabled = 1;
        }
    }

    if ($auto_title_disabled || $first_prompt =~ /^\s*$/) {
        $session->{title} = _generate_fallback_title($first_prompt, $session->{id});
        save_session($session);
        return $session->{title};
    }

    # Truncate prompt sample for title request to prevent huge context
    my $prompt_sample = length($first_prompt) > 500 ? substr($first_prompt, 0, 500) . '...' : $first_prompt;
    my $title_prompt = "Generate a short English title (max 25 characters, ASCII letters, digits, spaces only, no punctuation, no quotes) that summarizes this user request:\n\n$prompt_sample\n\nTitle:";

    my $raw_title = '';
    eval {
        my $body = build_request(
            [{ role => 'user', content => $title_prompt }],
            [],
            "You are a helpful assistant that generates extremely concise session titles.",
            32
        );
        my $resp = call_api(
            $API_URL,
            build_headers(),
            MiniJSON::encode($body),
            'POST',
            { silent => 1, no_retry => 1 }
        );
        if ($resp) {
            my @blocks = parse_response($resp);
            for my $block (@blocks) {
                if (ref($block) eq 'HASH' && defined $block->{type} && $block->{type} eq 'text') {
                    $raw_title .= $block->{text} if defined $block->{text};
                }
            }
        }
    };

    my $sanitized = _sanitize_session_title($raw_title);
    if (defined $sanitized && length($sanitized)) {
        $session->{title} = $sanitized;
    }
    else {
        $session->{title} = _generate_fallback_title($first_prompt, $session->{id});
    }

    save_session($session);
    return $session->{title};
}

sub generate_session_title {
    return generate_and_set_session_title(@_);
}

sub switch_to_session {
    my ($target_id, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    my $res = resolve_session_id($target_id);
    if (!$res->{ok}) {
        print $out_fh "$res->{error}\n";
        return undef;
    }

    my $resolved_id = $res->{id};
    if (defined $CURRENT_SESSION && ref($CURRENT_SESSION) eq 'HASH' &&
        defined $CURRENT_SESSION->{id} && $CURRENT_SESSION->{id} eq $resolved_id) {
        print $out_fh "Session '$resolved_id' is already the current session.\n";
        return $CURRENT_SESSION;
    }

    # Auto-save current session before switching if non-empty
    if (defined $CURRENT_SESSION && ref($CURRENT_SESSION) eq 'HASH') {
        my $msgs = $CURRENT_SESSION->{messages};
        if (ref($msgs) eq 'ARRAY' && scalar(@$msgs) > 0) {
            save_session($CURRENT_SESSION);
        }
    }

    my $loaded = load_session($resolved_id);
    if (!defined $loaded || ref($loaded) ne 'HASH') {
        print $out_fh "Failed to load session '$resolved_id'.\n";
        return undef;
    }

    # Ensure stats and structure are initialized
    get_session_stats($loaded);

    # Preserve current active provider & model
    $CURRENT_SESSION = $loaded;

    format_session_resume_summary($CURRENT_SESSION, $out_fh);
    return $CURRENT_SESSION;
}

sub delete_session_command {
    my ($target_id, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    my $res = resolve_session_id($target_id);
    if (!$res->{ok}) {
        print $out_fh "$res->{error}\n";
        return 0;
    }

    my $resolved_id = $res->{id};
    my $is_current = (defined $CURRENT_SESSION && ref($CURRENT_SESSION) eq 'HASH' &&
                      defined $CURRENT_SESSION->{id} && $CURRENT_SESSION->{id} eq $resolved_id) ? 1 : 0;

    my $ok = delete_session($resolved_id);
    if (!$ok) {
        print $out_fh "Failed to delete session '$resolved_id'.\n";
        return 0;
    }

    print $out_fh "Deleted session '$resolved_id'.\n";

    if ($is_current) {
        my $new_session = init_session();
        print $out_fh "Started a fresh session ($new_session->{id}).\n";
    }

    return 1;
}

sub handle_session_command {
    my ($args, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    if (!defined $args || $args =~ /^\s*$/) {
        print $out_fh "Usage:\n";
        print $out_fh "  /session <id>        - Switch to a saved session (exact ID or prefix)\n";
        print $out_fh "  /session delete <id> - Delete a saved session\n";
        print $out_fh "  /sessions            - List saved sessions\n";
        return;
    }

    $args =~ s/^\s+|\s+$//g;

    if ($args =~ /^delete(?:\s+(.*))?$/i) {
        my $del_id = $1;
        if (!defined $del_id || $del_id =~ /^\s*$/) {
            print $out_fh "Usage: /session delete <id>\n";
            return;
        }
        $del_id =~ s/^\s+|\s+$//g;
        return delete_session_command($del_id, $out_fh);
    }

    return switch_to_session($args, $out_fh);
}

1;

