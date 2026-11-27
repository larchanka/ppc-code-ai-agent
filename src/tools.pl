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
        description => 'Edit a range of lines in a file (1-based, inclusive) or replace matching target text',
        input_schema => {
            type => 'object',
            properties => {
                path       => { type => 'string', description => 'Target file path' },
                start_line => { type => 'integer', description => '1-based start line number (inclusive)' },
                end_line   => { type => 'integer', description => '1-based end line number (inclusive)' },
                content    => { type => 'string', description => 'Replacement content (empty string to delete lines)' },
                target     => { type => 'string', description => 'Exact target text to replace or verify at specified lines' },
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

# Prompt whether to save key to ~/.code-agent/env; if confirmed,
# strip existing GEMINI_API_KEY line and append new one.
sub _maybe_save_gemini_key {
    my ($key) = @_;
    my $target_file = get_env_file_path();
    print "\n  Save this key to $target_file so future runs pick it up automatically? [Y/n] ";
    my $a = read_line_interactive('', 0);
    return unless defined $a;
    return if $a =~ /^\s*n/i;

    (my $dir = $target_file) =~ s{/[^/]+$}{};
    if (length $dir && !-d $dir) {
        mkdir $dir, 0700;
        chmod 0700, $dir;
    }

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
    return _read_prompt_or_cancel($prompt, 0);
}

# Read a single line of visible input with prompt, allowing Esc or Ctrl+C to cancel.
# Echoes characters as typed. undef on cancel.
sub read_line_or_cancel {
    my ($prompt) = @_;
    return _read_prompt_or_cancel($prompt, 1);
}

sub _read_prompt_or_cancel {
    my ($prompt, $echo) = @_;
    cursor_show();
    print $prompt if defined $prompt;

    my $is_tty = -t STDIN;
    my $orig_stty;
    if ($is_tty) {
        $orig_stty = `stty -g 2>/dev/null`;
        chomp $orig_stty if defined $orig_stty;
        system('stty', 'raw', '-echo', '-opost');
    }

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
            if (length($buf) > 0) {
                substr($buf, -1, 1, '');
                print "\b \b" if $echo && $is_tty;
            }
        }
        elsif ($b >= 0x20) {
            $buf .= $ch;
            print $ch if $echo && $is_tty;
        }
    }

    if ($is_tty && defined $orig_stty && $orig_stty ne '') {
        system('stty', $orig_stty);
    }
    print "\n";
    cursor_hide();
    return $cancelled ? undef : $buf;
}

%UNTRUSTED_OUTPUT_TOOLS = (
    read_file       => 1,
    list_dir        => 1,
    run_shell       => 1,
    invoke_subagent => 1,
);

sub format_tool_result {
    my ($name, $result) = @_;
    $result = '' unless defined $result;
    return $result unless defined $name && ($UNTRUSTED_OUTPUT_TOOLS{$name} || exists $MCP_TOOLS{$name} || $name =~ /^mcp__/);

    my $sanitized = $result;
    $sanitized =~ s{<(/(?i:untrusted_tool_output)\b)}{<\\$1}g;
    return "<untrusted_tool_output tool=\"$name\">\n$sanitized\n</untrusted_tool_output>";
}

sub _first_nonempty_param {
    my ($input, @keys) = @_;
    return undef unless ref($input) eq 'HASH';
    for my $key (@keys) {
        return $input->{$key} if defined $input->{$key} && length($input->{$key});
    }
    return undef;
}

sub resolve_path_param {
    my ($input) = @_;
    return _first_nonempty_param($input, 'path', 'file_path', 'filepath', 'filename', 'file', 'dir', 'directory');
}

sub resolve_content_param {
    my ($input, @extra_keys) = @_;
    return undef unless ref($input) eq 'HASH';
    for my $key ('content', @extra_keys, 'text', 'data', 'body') {
        return $input->{$key} if defined $input->{$key};
    }
    return undef;
}

sub resolve_command_param {
    my ($input) = @_;
    return _first_nonempty_param($input, 'command', 'cmd', 'script', 'shell_command');
}

sub _ensure_parent_dir {
    my ($path) = @_;
    my $dir = File::Basename::dirname($path);
    return undef unless defined $dir && length($dir) && $dir ne '.' && !-d $dir;
    eval { File::Path::mkpath($dir) };
    if ($@ || !-d $dir) {
        my $err = $@ ? $@ : $!;
        return "Error: cannot create directory '$dir': $err";
    }
    return undef;
}

sub _slice_file_lines {
    my ($lines_ref, $raw_start, $raw_end) = @_;
    my $total = scalar @$lines_ref;
    my $start = defined $raw_start ? int($raw_start) : 1;
    my $end   = defined $raw_end   ? int($raw_end)   : $total;
    $start = 1      if $start < 1;
    $end   = $total if $end > $total;
    return '' if $start > $total || $start > $end;
    return join('', @{$lines_ref}[ ($start - 1) .. ($end - 1) ]);
}

sub _tool_read_file {
    my ($input) = @_;
    my $path = resolve_path_param($input);
    return "Error: missing required 'path' parameter" unless defined $path;
    my ($s, $e) = ($input->{start_line}, $input->{end_line});
    return "Error: start_line ($s) cannot be greater than end_line ($e)"
        if defined $s && defined $e && $s > $e;

    open(my $fh, '<:encoding(UTF-8)', $path) or return "Error: cannot open $path: $!";
    my @lines = <$fh>;
    close $fh;
    return join('', @lines) if !defined $s && !defined $e;
    return _slice_file_lines(\@lines, $s, $e);
}

sub _tool_write_file {
    my ($input) = @_;
    my $path = resolve_path_param($input);
    return "Error: missing required 'path' parameter" unless defined $path;
    my $content = resolve_content_param($input);
    return "Error: missing required 'content' parameter" unless defined $content;
    return "Cancelled by user." unless confirm_tool("Write to file '$path'?");

    my $mkdir_err = _ensure_parent_dir($path);
    return $mkdir_err if defined $mkdir_err;

    open(my $fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
    print $fh $content;
    close $fh;
    return "Write complete: $path";
}

sub _count_substring_occurrences {
    my ($text, $sub) = @_;
    my $count = 0;
    my $p = 0;
    while (($p = index($text, $sub, $p)) >= 0) {
        $count++;
        $p += length($sub);
    }
    return $count;
}

sub _edit_file_by_target {
    my ($path, $lines_ref, $target, $content) = @_;
    my $norm_raw = join('', @$lines_ref);
    my $norm_target = $target;
    $norm_raw =~ s/\r\n/\n/g;
    $norm_target =~ s/\r\n/\n/g;

    my $pos = index($norm_raw, $norm_target);
    return "Error: target text not found in '$path'" if $pos < 0;

    if (index($norm_raw, $norm_target, $pos + length($norm_target)) >= 0) {
        my $count = _count_substring_occurrences($norm_raw, $norm_target);
        return "Error: target text appears $count times in '$path'. Please provide more surrounding lines to make target unique.";
    }

    return "Cancelled by user." unless confirm_tool("Edit file '$path' (target replace)?");

    substr($norm_raw, $pos, length($norm_target), $content);
    open(my $out_fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
    print $out_fh $norm_raw;
    close $out_fh;
    return "Edit complete: $path";
}

sub _expected_line_slice {
    my ($lines_ref, $start_line, $end_line) = @_;
    my $total = scalar @$lines_ref;
    return '' unless $end_line >= $start_line && $start_line <= $total;
    my $clamped_end = $end_line > $total ? $total : $end_line;
    return join('', @{$lines_ref}[ ($start_line - 1) .. ($clamped_end - 1) ]);
}

sub _compute_relocated_range {
    my ($raw_text, $pos, $len) = @_;
    my $before = substr($raw_text, 0, $pos);
    my $match_str = substr($raw_text, $pos, $len);
    my $new_start = ($before =~ tr/\n//) + 1;
    my $new_end = $new_start + ($match_str =~ tr/\n//);
    $new_end-- if $match_str =~ /\n\z/;
    return ($new_start, $new_end < $new_start ? $new_start : $new_end);
}

sub _relocate_target_lines {
    my ($path, $lines_ref, $start_line, $end_line, $target) = @_;
    my $expected_slice = _expected_line_slice($lines_ref, $start_line, $end_line);
    my $norm_slice = $expected_slice;
    my $norm_target = $target;
    $norm_slice =~ s/\r\n/\n/g;
    $norm_target =~ s/\r\n/\n/g;

    return ($start_line, $end_line, undef)
        if $norm_slice eq $norm_target || $norm_slice eq "$norm_target\n";

    my $raw_text = join('', @$lines_ref);
    $raw_text =~ s/\r\n/\n/g;
    my $pos = index($raw_text, $norm_target);
    return ($start_line, $end_line, "Error: target text does not match lines $start_line-$end_line in '$path'.\nExpected: $target\nFound: $expected_slice")
        if $pos < 0;
    return ($start_line, $end_line, "Error: target text does not match lines $start_line-$end_line in '$path', and target is ambiguous (appears multiple times in file).")
        if index($raw_text, $norm_target, $pos + length($norm_target)) >= 0;

    my ($new_start, $new_end) = _compute_relocated_range($raw_text, $pos, length($norm_target));
    return ($new_start, $new_end, undef);
}

sub _validate_edit_line_bounds {
    my ($start_line, $end_line, $total) = @_;
    return "Error: invalid start_line ($start_line): must be >= 1" if $start_line < 1;
    return "Error: start_line ($start_line) exceeds total lines ($total) + 1" if $start_line > $total + 1;
    return "Error: end_line ($end_line) cannot be less than start_line - 1 (" . ($start_line - 1) . ")"
        if $end_line < $start_line - 1;
    return undef;
}

sub _apply_line_edit {
    my ($path, $lines_ref, $start_line, $end_line, $content) = @_;
    $content .= "\n" if $content ne '' && $content !~ /\n\z/;
    my $offset = $start_line - 1;
    my $length = $end_line >= $start_line ? ($end_line - $start_line + 1) : 0;
    if ($content eq '') {
        splice(@$lines_ref, $offset, $length);
    }
    else {
        splice(@$lines_ref, $offset, $length, $content);
    }
    open(my $out_fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
    print $out_fh @$lines_ref;
    close $out_fh;
    return "Edit complete: $path";
}

sub _edit_file_by_range {
    my ($path, $lines_ref, $input, $target, $content) = @_;
    my $total      = scalar @$lines_ref;
    my $start_line = defined $input->{start_line} ? int($input->{start_line}) : 1;
    my $end_line   = defined $input->{end_line}   ? int($input->{end_line})   : 0;

    my $bounds_err = _validate_edit_line_bounds($start_line, $end_line, $total);
    return $bounds_err if defined $bounds_err;

    if (defined $target && length($target)) {
        my $err;
        ($start_line, $end_line, $err) = _relocate_target_lines($path, $lines_ref, $start_line, $end_line, $target);
        return $err if defined $err;
    }

    $end_line = $total if $end_line > $total;
    return "Cancelled by user." unless confirm_tool("Edit file '$path' (lines $start_line-$end_line)?");
    return _apply_line_edit($path, $lines_ref, $start_line, $end_line, $content);
}

sub _tool_edit_file {
    my ($input) = @_;
    my $path = resolve_path_param($input);
    return "Error: missing required 'path' parameter" unless defined $path;

    my $resolved_content = resolve_content_param($input, 'replacement', 'new_text');
    my $content = defined $resolved_content ? $resolved_content : '';
    my $target = _first_nonempty_param($input, 'target');

    open(my $fh, '<:encoding(UTF-8)', $path) or return "Error: cannot open $path: $!";
    my @lines = <$fh>;
    close $fh;

    my $has_both_lines = defined $input->{start_line} && defined $input->{end_line};
    if (defined $target && !$has_both_lines) {
        return _edit_file_by_target($path, \@lines, $target, $content);
    }
    return _edit_file_by_range($path, \@lines, $input, $target, $content);
}

sub _tool_list_dir {
    my ($input) = @_;
    my $resolved_path = resolve_path_param($input);
    my $path = defined $resolved_path ? $resolved_path : '.';
    opendir(my $dh, $path) or return "Error: cannot open $path: $!";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir $dh;
    return join("\n", @entries);
}

sub _tool_run_shell {
    my ($input) = @_;
    my $command = resolve_command_param($input);
    return "Error: missing required 'command' parameter" unless defined $command;
    return "Cancelled by user." unless confirm_tool("Run this command: $command");
    my $output = `$command 2>&1`;
    return (!defined $output || $output eq '') ? '(no output)' : $output;
}

sub _tool_invoke_subagent {
    my ($input) = @_;
    my $task = $input->{task};
    return "Error: missing required 'task' parameter" unless defined $task && length $task;
    my $subagent_type = defined $input->{subagent_type} ? $input->{subagent_type} : 'build';
    return run_subagent($task, $subagent_type);
}

my %BUILTIN_TOOL_HANDLERS = (
    read_file       => \&_tool_read_file,
    write_file      => \&_tool_write_file,
    edit_file       => \&_tool_edit_file,
    list_dir        => \&_tool_list_dir,
    run_shell       => \&_tool_run_shell,
    invoke_subagent => \&_tool_invoke_subagent,
);

sub run_tool {
    my ($name, $input) = @_;
    $input = {} unless ref($input) eq 'HASH';

    if (exists $input->{_arg_parse_error}) {
        my $err = defined $input->{_arg_parse_error} ? $input->{_arg_parse_error} : 'invalid JSON';
        return "Error: tool arguments for '$name' were truncated or invalid JSON ($err). Please retry the tool call with valid JSON and more concise arguments or smaller chunks.";
    }

    if (my $handler = $BUILTIN_TOOL_HANDLERS{$name}) {
        return $handler->($input);
    }
    if (exists $MCP_TOOLS{$name} || (defined $name && $name =~ /^mcp__/)) {
        return mcp_execute_tool($name, $input);
    }
    return "Unknown tool: $name";
}

sub _normalize_subagent_type {
    my ($type) = @_;
    return (defined $type && ($type eq 'plan' || $type eq 'build')) ? $type : 'build';
}

sub _extract_subagent_turn_blocks {
    my ($content_blocks_ref) = @_;
    my @tool_calls;
    my $turn_text = '';
    for my $block (@$content_blocks_ref) {
        if ($block->{type} eq 'text') {
            $turn_text .= $block->{text};
        }
        elsif ($block->{type} eq 'tool_use') {
            push @tool_calls, $block;
        }
    }
    return ($turn_text, \@tool_calls);
}

sub _should_continue_subagent_turn {
    my ($resp, $content_blocks_ref, $turn_text) = @_;
    return 1 if is_response_truncated($resp);
    return 1 if has_thinking_block($content_blocks_ref) && $turn_text !~ /\S/;
    return 0;
}

sub _build_subagent_continuation_prompt {
    my ($turn, $max_turns, $turns_left) = @_;
    my $countdown_note = get_subagent_countdown_note($turn, $max_turns, $turns_left);
    return "Your previous response ended or was cut off before emitting any tool calls or final summary. "
         . "Please continue directly from where you left off and emit your next tool calls or final summary concisely without repeating your previous reasoning.\n\n$countdown_note";
}

sub _execute_subagent_tool_call {
    my ($subagent_type, $t_name, $t_input) = @_;
    if ($subagent_type eq 'plan' && $t_name ne 'read_file' && $t_name ne 'list_dir') {
        return "Error: tool '$t_name' is not permitted for 'plan' sub-agent (read-only mode).";
    }
    if ($t_name eq 'invoke_subagent') {
        return "Error: sub-agents cannot invoke sub-agents.";
    }
    record_session_tool_call($t_name, $CURRENT_SESSION);
    return run_tool($t_name, $t_input);
}

sub _run_subagent_tool_calls {
    my ($subagent_type, $turn, $max_turns, $turns_left, $tool_calls_ref) = @_;
    my $countdown_note = get_subagent_countdown_note($turn, $max_turns, $turns_left);
    my @tool_results;

    for my $call (@$tool_calls_ref) {
        my $t_name  = $call->{name};
        my $t_input = $call->{input};

        print format_subagent_tool_call($subagent_type, $turn, $max_turns, $t_name, $t_input);

        my $result = _execute_subagent_tool_call($subagent_type, $t_name, $t_input);
        my $fenced_result = format_tool_result($t_name, $result);

        push @tool_results, {
            type        => 'tool_result',
            tool_use_id => $call->{id},
            name        => $t_name,
            content     => "$fenced_result\n\n$countdown_note",
        };
    }
    return \@tool_results;
}

sub _handle_subagent_error {
    my ($subagent_type, $turn, $status, $prefix, $err_msg) = @_;
    print clear_thinking_line() if -t STDOUT;
    cursor_show();
    print format_subagent_finish($subagent_type, $turn, $status);
    return "$prefix: $err_msg";
}

sub _fetch_subagent_turn {
    my ($subagent_type, $turn, $messages_ref, $tools_ref, $effective_prompt) = @_;
    my $body = build_request($messages_ref, $tools_ref, $effective_prompt);
    my $resp = eval { call_api($API_URL, build_headers(), MiniJSON::encode($body)) };
    if ($@) {
        return (undef, undef, _handle_subagent_error($subagent_type, $turn, "Failed: API error", "API error in sub-agent", $@));
    }

    record_session_api_usage($resp, $CURRENT_SESSION);

    my @content_blocks = eval { parse_response($resp) };
    if ($@) {
        return (undef, undef, _handle_subagent_error($subagent_type, $turn, "Failed: parse error", "Response parsing error in sub-agent", $@));
    }

    print clear_thinking_line() if -t STDOUT;
    push @$messages_ref, { role => 'assistant', content => \@content_blocks };
    return ($resp, \@content_blocks, undef);
}

sub _finalize_subagent_text {
    my ($text) = @_;
    return $text if defined $text && $text =~ /\S/;
    return "(Sub-agent completed without returning text summary)";
}

sub _format_subagent_max_turns_summary {
    my ($max_turns, $turn_text) = @_;
    my $last = (defined $turn_text && length $turn_text) ? $turn_text : '(no text output)';
    return "Sub-agent reached maximum turn limit ($max_turns). Last output: $last";
}

sub _can_continue_subagent {
    my ($turn, $max_turns, $cont_count, $max_cont, $resp, $blocks_ref, $turn_text) = @_;
    return 0 unless $turn < $max_turns && $cont_count < $max_cont;
    return _should_continue_subagent_turn($resp, $blocks_ref, $turn_text);
}

sub run_subagent {
    my ($task, $subagent_type) = @_;
    $subagent_type = _normalize_subagent_type($subagent_type);

    my $max_turns = 50;
    my $max_continuations = 3;
    my $tools_ref = get_subagent_tools($subagent_type);
    my $effective_prompt = get_subagent_system_prompt($subagent_type, $max_turns);
    my $initial_prompt   = get_subagent_initial_prompt($task, $max_turns);

    my $sub_session = {
        id       => generate_session_id(),
        messages => [ { role => 'user', content => $initial_prompt } ],
    };

    local $CURRENT_SUBAGENT_TYPE = $subagent_type;
    record_session_subagent_call($CURRENT_SESSION);
    print format_subagent_start($subagent_type, $task);

    my $turn = 0;
    my $continuation_count = 0;
    my $accumulated_text = '';
    my $final_text = '';

    while ($turn < $max_turns) {
        $turn++;
        my $turns_left = $max_turns - $turn;

        my ($resp, $blocks_ref, $err) = _fetch_subagent_turn(
            $subagent_type, $turn, $sub_session->{messages}, $tools_ref, $effective_prompt
        );
        return $err if defined $err;

        my ($turn_text, $tool_calls_ref) = _extract_subagent_turn_blocks($blocks_ref);

        if (!@$tool_calls_ref) {
            $accumulated_text .= $turn_text;
            if (_can_continue_subagent($turn, $max_turns, $continuation_count, $max_continuations, $resp, $blocks_ref, $turn_text)) {
                $continuation_count++;
                my $cont_prompt = _build_subagent_continuation_prompt($turn, $max_turns, $turns_left);
                push @{$sub_session->{messages}}, { role => 'user', content => $cont_prompt };
                next;
            }
            $final_text = $accumulated_text;
            print format_subagent_finish($subagent_type, $turn, "Completed");
            last;
        }

        $continuation_count = 0;
        $accumulated_text = '';
        my $tool_results_ref = _run_subagent_tool_calls($subagent_type, $turn, $max_turns, $turns_left, $tool_calls_ref);
        push @{$sub_session->{messages}}, { role => 'user', content => $tool_results_ref };

        if ($turn >= $max_turns) {
            print format_subagent_finish($subagent_type, $turn, "Reached max turns ($max_turns)");
            $final_text = _format_subagent_max_turns_summary($max_turns, $turn_text);
            last;
        }
    }

    return _finalize_subagent_text($final_text);
}

