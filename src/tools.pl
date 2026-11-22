# --- Tool definitions and tool execution ---
our @TOOLS = (
    {
        name => 'read_file',
        description => 'Read file contents, optionally between start_line and end_line (1-based, inclusive)',
        input_schema => {
            type => 'object',
            properties => {
                path       => { type => 'string', description => 'Path to the file to read' },
                start_line => { type => 'integer', description => 'Optional 1-based start line number (inclusive)' },
                end_line   => { type => 'integer', description => 'Optional 1-based end line number (inclusive)' },
            },
            required => ['path'],
        },
    },
    {
        name => 'write_file',
        description => 'Write content to a file (overwrite)',
        input_schema => {
            type => 'object',
            properties => {
                path    => { type => 'string', description => 'Target file path' },
                content => { type => 'string', description => 'Content to write' },
            },
            required => ['path', 'content'],
        },
    },
    {
        name => 'edit_file',
        description => 'Edit a range of lines in a file (1-based, inclusive)',
        input_schema => {
            type => 'object',
            properties => {
                path       => { type => 'string', description => 'Target file path' },
                start_line => { type => 'integer', description => '1-based start line number (inclusive)' },
                end_line   => { type => 'integer', description => '1-based end line number (inclusive)' },
                content    => { type => 'string', description => 'Replacement content (empty string to delete lines)' },
            },
            required => ['path', 'start_line', 'end_line', 'content'],
        },
    },
    {
        name => 'list_dir',
        description => 'List contents of a directory',
        input_schema => {
            type => 'object',
            properties => { path => { type => 'string', description => 'Directory to list (defaults to current directory if omitted)' } },
            required => [],
        },
    },
    {
        name => 'run_shell',
        description => 'Execute a shell command and return stdout/stderr',
        input_schema => {
            type => 'object',
            properties => { command => { type => 'string', description => 'Shell command to execute' } },
            required => ['command'],
        },
    },
    {
        name => 'invoke_subagent',
        description => 'Delegate a specialized task to a sub-agent with its own isolated context. Returns the sub-agent\'s final summary.',
        input_schema => {
            type => 'object',
            properties => {
                task => {
                    type => 'string',
                    description => 'Clear, detailed task description and instructions for the sub-agent',
                },
                subagent_type => {
                    type => 'string',
                    description => 'Sub-agent role: "plan" (strictly read-only exploration using read_file and list_dir) or "build" (default, full read, write, edit, and shell access)',
                },
            },
            required => ['task'],
        },
    },
);

sub confirm {
    my ($msg) = @_;
    print "\n[Confirm] $msg\nProceed? [y/N] ";
    my $ans = read_line_interactive('', 0);
    return defined($ans) && $ans =~ /^y/i;
}

sub confirm_tool {
    my ($prompt) = @_;
    return 1 if $AUTO_MODE;
    if (defined $CURRENT_SUBAGENT_TYPE && length $CURRENT_SUBAGENT_TYPE) {
        $prompt = "[Sub-agent: $CURRENT_SUBAGENT_TYPE] $prompt";
    }
    return confirm($prompt);
}

sub get_subagent_tools {
    my ($type) = @_;
    $type ||= 'build';
    if ($type eq 'plan') {
        my @plan_tools = grep { $_->{name} eq 'read_file' || $_->{name} eq 'list_dir' } @TOOLS;
        return \@plan_tools;
    }
    # 'build' or any other: all tools EXCEPT invoke_subagent (prevent recursive delegation)
    my @build_tools = grep { $_->{name} ne 'invoke_subagent' } @TOOLS;
    return \@build_tools;
}

# Display responses incrementally like a typewriter. Added based on feedback
# from physical PowerBook G4 where fast output scrolls too quickly to read.
# CLAUDE_TYPE_DELAY (seconds per char) adjusts speed; setting to 0 restores
# immediate display (original behavior). Pauses slightly longer on newlines.
# select(undef,undef,undef,$t) is a fractional second sleep without Time::HiRes.

# --- Gemini API key setup helper ---
# Displays numbered steps, optionally opens the page in a browser, and validates
# the pasted key by calling the API live. Returns the key string on success
# (caller sets $ENV{GEMINI_API_KEY} and calls configure_provider).
# Returns undef on cancel/failure.
sub gemini_key_setup {
    my $url = 'https://ai.google.dev/gemini-api/docs/api-key';
    print <<"GUIDE";

──────────────────────────────────────────────
 Get a Gemini API key
   (free tier, no credit card)
──────────────────────────────────────────────
 GEMINI_API_KEY is not set yet. Here is how to get a free key:

  1. Open this page in a browser:
       $url
  2. Sign in with a Google account (top right)
  3. Click the blue "Get a Gemini API key" button
     -> it takes you to Google AI Studio, "API keys"
  4. Click "Create API key" (top right)
  5. In the "Create API key" dialog, leave the defaults
     (key name as-is, project "Default Gemini Project")
     and click "Create API key" / "Create key"
  6. Copy the string it shows (starts with AIza...)



GUIDE

    if (-x '/usr/bin/open') {
        print "  Open this page in your browser now? [Y/n] ";
        my $a = read_line_interactive('', 0);
        return undef unless defined $a;
        if ($a !~ /^\s*n/i) {
            my $rc = system('open', $url);
            print $rc == 0
                ? "  -> opened.\n"
                : "  -> could not open it automatically; open the URL above by hand.\n";
        }
    }

    for my $attempt (1 .. 3) {
        my $key = read_secret_or_cancel(
            "\n  Paste the key and press Enter (Esc or Ctrl+C to cancel)\n"
          . "  key> ");
        return undef unless defined $key;
        $key =~ s/\A[\s"']+//;
        $key =~ s/[\s"']+\z//;
        if ($key eq '') {
            print "  Nothing entered.\n";
            next;
        }
        if ($key !~ /\AAIza[0-9A-Za-z_\-]{20,}\z/) {
            print "  * That does not look like a Gemini key (starts with AIza, ~39 chars).\n";
            print "    Try it anyway? [y/N] ";
            my $a = read_line_interactive('', 0);
            next unless defined $a && $a =~ /^\s*y/i;
        }

        print "  Checking the key...\n";
        my ($status, $detail) = _validate_gemini_key($key);
        if ($status eq 'ok') {
            print "  OK - the key works.\n";
            _maybe_save_gemini_key($key);
            return $key;
        }
        elsif ($status eq 'skip') {
            print "  (verification skipped: $detail)\n";
            _maybe_save_gemini_key($key);
            return $key;
        }
        elsif ($status eq 'bad_key') {
            print "  X - the key was rejected ($detail).\n";
            print "      Check for a copy/paste slip and that the whole key is there.\n";
        }
        elsif ($status eq 'api_disabled') {
            print "  X - the key is valid but the Generative Language API is not enabled ($detail).\n";
            print "      Recreate the key in AI Studio, or wait a bit and retry.\n";
        }
        else {
            print "  X - could not reach the API ($detail).\n";
            print "      Check that you are online.\n";
        }
        print "  (" . (3 - $attempt) . " left)\n" if $attempt < 3;
    }
    print "\n  Could not set up a key.\n";
    return undef;
}

# Send pasted key to Generative Language API models list endpoint to verify validity.
# Return value: ('ok'|'bad_key'|'api_disabled'|'network'|'skip', detail)
sub _validate_gemini_key {
    my ($key) = @_;
    return ('skip', 'curl not found')   unless -x $CURL;
    return ('skip', 'cacert not found') unless -f $CACERT;

    my $tmp_resp   = "/tmp/code-agent-keychk-resp-$$.json";
    my $tmp_config = "/tmp/code-agent-keychk-cfg-$$.txt";
    open(my $cf, '>', $tmp_config) or return ('network', "cannot create temp file: $!");
    chmod 0600, $tmp_config;
    print $cf qq(url = "https://generativelanguage.googleapis.com/v1beta/models"\n);
    print $cf qq(header = "x-goog-api-key: $key"\n);
    print $cf qq(cacert = "$CACERT"\n);
    print $cf qq(output = "$tmp_resp"\n);
    print $cf qq(write-out = "%{http_code}"\n);
    print $cf qq(max-time = "20"\n);
    print $cf qq(silent\n);
    print $cf qq(show-error\n);
    close $cf;

    my $http = `@{[quote($CURL)]} -K @{[quote($tmp_config)]} 2>/dev/null`;
    unlink $tmp_config;
    my $body = '';
    if (open(my $rf, '<', $tmp_resp)) { local $/; $body = <$rf>; close $rf; }
    unlink $tmp_resp;
    $body = '' unless defined $body;
    $http = '' unless defined $http;

    return ('ok', "HTTP $http")            if $http =~ /^2\d\d$/;
    return ('network', 'no response from curl') if $http eq '' || $http eq '000';
    return ('bad_key', "HTTP $http")       if $body =~ /API_KEY_INVALID/ || $http eq '400';
    return ('api_disabled', "HTTP $http")  if $body =~ /SERVICE_DISABLED|PERMISSION_DENIED|has not been used|is disabled/;
    return ('bad_key', "HTTP $http");
}

# Prompt whether to save key to ~/.code-agent-env; if confirmed,
# strip existing GEMINI_API_KEY line and append new one.
sub _maybe_save_gemini_key {
    my ($key) = @_;
    my $target_file = get_env_file_path();
    print "\n  Save this key to $target_file so future runs pick it up automatically? [Y/n] ";
    my $a = read_line_interactive('', 0);
    return unless defined $a;
    return if $a =~ /^\s*n/i;

    my @keep;
    if (open(my $rf, '<', $target_file)) {
        while (my $l = <$rf>) {
            next if $l =~ /^\s*export\s+GEMINI_API_KEY=/;
            push @keep, $l;
        }
        close $rf;
    }
    push @keep, "export GEMINI_API_KEY=$key\n";
    if (open(my $wf, '>', $target_file)) {
        print $wf @keep;
        close $wf;
        chmod 0600, $target_file;
        print "  -> saved. It will be loaded automatically from now on.\n";
    }
    else {
        print "  -> could not save (cannot write $target_file).\n";
        print "     Please add the following line manually:\n";
        print "       export GEMINI_API_KEY=$key\n";
    }
}

# Read a single line secret (such as an API key) without echoing to screen.
# Unlike read_line_interactive, arrow keys are not supported (only key pasting
# is expected); instead, either Esc or Ctrl+C immediately returns undef to cancel
# (Esc is standard for canceling uncommitted input, Ctrl+C is standard for interrupting
# in terminal). Treating standalone ESC as cancel without waiting for following bytes
# is a simplification valid here because escape sequences like arrow keys do not need
# to be parsed. In stty raw mode, ISIG is disabled, so Ctrl+C (0x03) arrives as a raw byte.
# Return value: input string (raw bytes, without newline). undef on cancel.
sub read_secret_or_cancel {
    my ($prompt) = @_;
    cursor_show();
    print $prompt;

    my $orig_stty = `stty -g`;
    chomp $orig_stty;
    system('stty', 'raw', '-echo', '-opost');

    my $buf = '';
    my $cancelled = 0;
    while (1) {
        my $ch;
        my $n = sysread(STDIN, $ch, 1);
        last unless defined $n && $n > 0;
        my $b = ord($ch);
        if ($b == 0x1b || $b == 0x03) {  # Esc or Ctrl+C -> cancel
            $cancelled = 1;
            last;
        }
        elsif ($b == 0x0d || $b == 0x0a) {  # Enter
            last;
        }
        elsif ($b == 0x7f || $b == 0x08) {  # Backspace/Delete
            substr($buf, -1, 1, '') if length($buf) > 0;
        }
        elsif ($b >= 0x20) {
            $buf .= $ch;
        }
    }

    system('stty', $orig_stty) if defined $orig_stty && $orig_stty ne '';
    print "\n";
    cursor_hide();
    return $cancelled ? undef : $buf;
}

sub run_tool {
    my ($name, $input) = @_;

    # The return value of run_tool is not shown directly to user, but sent to the model
    # as tool_result log. The user only directly sees the confirm() prompt.
    if ($name eq 'read_file') {
        my $path = $input->{path};
        if (defined $input->{start_line} && defined $input->{end_line} && $input->{start_line} > $input->{end_line}) {
            return "Error: start_line ($input->{start_line}) cannot be greater than end_line ($input->{end_line})";
        }
        open(my $fh, '<:encoding(UTF-8)', $path) or return "Error: cannot open $path: $!";
        if (!defined $input->{start_line} && !defined $input->{end_line}) {
            local $/;
            my $content = <$fh>;
            close $fh;
            return defined $content ? $content : '';
        }
        my @lines = <$fh>;
        close $fh;

        my $total = scalar @lines;
        my $start = defined $input->{start_line} ? int($input->{start_line}) : 1;
        my $end   = defined $input->{end_line}   ? int($input->{end_line})   : $total;

        $start = 1 if $start < 1;
        $end   = $total if $end > $total;

        return '' if $start > $total || $start > $end;

        return join('', @lines[ ($start - 1) .. ($end - 1) ]);
    }
    elsif ($name eq 'write_file') {
        my $path = $input->{path};
        unless (confirm_tool("Write to file '$path'?")) {
            return "Cancelled by user.";
        }
        open(my $fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
        print $fh $input->{content};
        close $fh;
        return "Write complete: $path";
    }
    elsif ($name eq 'edit_file') {
        my $path = $input->{path};
        my $content = defined $input->{content} ? $input->{content}
                    : defined $input->{replacement} ? $input->{replacement}
                    : '';
        my $start_line = defined $input->{start_line} ? int($input->{start_line}) : 1;
        my $end_line   = defined $input->{end_line}   ? int($input->{end_line})   : 0;

        if ($start_line < 1) {
            return "Error: invalid start_line ($start_line): must be >= 1";
        }

        open(my $fh, '<:encoding(UTF-8)', $path) or return "Error: cannot open $path: $!";
        my @lines = <$fh>;
        close $fh;

        my $total = scalar @lines;
        if ($start_line > $total + 1) {
            return "Error: start_line ($start_line) exceeds total lines ($total) + 1";
        }
        if ($end_line < $start_line - 1) {
            return "Error: end_line ($end_line) cannot be less than start_line - 1 (" . ($start_line - 1) . ")";
        }

        $end_line = $total if $end_line > $total;

        unless (confirm_tool("Edit file '$path' (lines $start_line-$end_line)?")) {
            return "Cancelled by user.";
        }

        $content .= "\n" if $content ne '' && $content !~ /\n\z/;

        my $offset = $start_line - 1;
        my $length = $end_line >= $start_line ? ($end_line - $start_line + 1) : 0;

        if ($content eq '') {
            splice(@lines, $offset, $length);
        }
        else {
            splice(@lines, $offset, $length, $content);
        }

        open(my $out_fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
        print $out_fh @lines;
        close $out_fh;

        return "Edit complete: $path";
    }
    elsif ($name eq 'list_dir') {
        my $path = $input->{path} || '.';
        opendir(my $dh, $path) or return "Error: cannot open $path: $!";
        my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
        closedir $dh;
        return join("\n", @entries);
    }
    elsif ($name eq 'run_shell') {
        my $command = $input->{command};
        unless (confirm_tool("Run this command: $command")) {
            return "Cancelled by user.";
        }
        my $output = `$command 2>&1`;
        return (!defined $output || $output eq '') ? '(no output)' : $output;
    }
    elsif ($name eq 'invoke_subagent') {
        my $task = $input->{task};
        return "Error: missing required 'task' parameter" unless defined $task && length $task;
        my $subagent_type = defined $input->{subagent_type} ? $input->{subagent_type} : 'build';
        return run_subagent($task, $subagent_type);
    }
    else {
        return "Unknown tool: $name";
    }
}

sub run_subagent {
    my ($task, $subagent_type) = @_;
    $subagent_type = 'build' unless defined $subagent_type && length $subagent_type;
    $subagent_type = 'build' unless $subagent_type eq 'plan' || $subagent_type eq 'build';

    my $max_turns = 50;
    my $tools_ref = get_subagent_tools($subagent_type);
    my $effective_prompt = get_subagent_system_prompt($subagent_type, $max_turns);
    my $initial_prompt   = get_subagent_initial_prompt($task, $max_turns);

    my $sub_session = {
        id       => generate_session_id(),
        messages => [ { role => 'user', content => $initial_prompt } ],
    };

    local $CURRENT_SUBAGENT_TYPE = $subagent_type;

    print format_subagent_start($subagent_type, $task);

    my $turn = 0;
    my $final_text = '';

    while ($turn < $max_turns) {
        $turn++;
        my $turns_left = $max_turns - $turn;

        my $body = build_request($sub_session->{messages}, $tools_ref, $effective_prompt);
        my $resp = eval { call_api($API_URL, build_headers(), MiniJSON::encode($body)) };
        if ($@) {
            print clear_thinking_line() if -t STDOUT;
            cursor_show();
            my $err = "API error in sub-agent: $@";
            print format_subagent_finish($subagent_type, $turn, "Failed: API error");
            return $err;
        }

        my @content_blocks = eval { parse_response($resp) };
        if ($@) {
            print clear_thinking_line() if -t STDOUT;
            cursor_show();
            my $err = "Response parsing error in sub-agent: $@";
            print format_subagent_finish($subagent_type, $turn, "Failed: parse error");
            return $err;
        }

        if (-t STDOUT) {
            print clear_thinking_line();
        }

        push @{$sub_session->{messages}}, { role => 'assistant', content => \@content_blocks };

        my @tool_calls;
        my $turn_text = '';
        for my $block (@content_blocks) {
            if ($block->{type} eq 'text') {
                $turn_text .= $block->{text};
            }
            elsif ($block->{type} eq 'tool_use') {
                push @tool_calls, $block;
            }
        }

        if (!@tool_calls) {
            $final_text = $turn_text;
            print format_subagent_finish($subagent_type, $turn, "Completed");
            last;
        }

        my @tool_results;
        for my $call (@tool_calls) {
            my $t_name  = $call->{name};
            my $t_input = $call->{input};

            print format_subagent_tool_call($subagent_type, $turn, $max_turns, $t_name, $t_input);

            my $result;
            if ($subagent_type eq 'plan' && $t_name ne 'read_file' && $t_name ne 'list_dir') {
                $result = "Error: tool '$t_name' is not permitted for 'plan' sub-agent (read-only mode).";
            }
            elsif ($t_name eq 'invoke_subagent') {
                $result = "Error: sub-agents cannot invoke sub-agents.";
            }
            else {
                $result = run_tool($t_name, $t_input);
            }

            my $countdown_note = get_subagent_countdown_note($turn, $max_turns, $turns_left);
            my $content_with_countdown = "$result\n\n$countdown_note";

            push @tool_results, {
                type        => 'tool_result',
                tool_use_id => $call->{id},
                name        => $t_name,
                content     => $content_with_countdown,
            };
        }

        push @{$sub_session->{messages}}, { role => 'user', content => \@tool_results };

        if ($turn >= $max_turns) {
            print format_subagent_finish($subagent_type, $turn, "Reached max turns ($max_turns)");
            $final_text = "Sub-agent reached maximum turn limit ($max_turns). Last output: " . ($turn_text || '(no text output)');
            last;
        }
    }

    return $final_text;
}

