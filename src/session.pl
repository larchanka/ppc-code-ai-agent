
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
    $CURRENT_SESSION = {
        id         => $id,
        created_at => time(),
        provider   => $PROVIDER,
        model      => $MODEL,
        messages   => [],
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
    print $out_fh "  /models  - View and switch available AI models\n";
    print $out_fh "  /ctx     - View or set max output tokens per response (e.g. /ctx 64k)\n";
    print $out_fh "  /claude  - Switch to Anthropic Claude\n";
    print $out_fh "  /gemini  - Switch to Google Gemini\n";
    print $out_fh "  /openai  - Switch to OpenAI-compatible endpoint\n";
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

