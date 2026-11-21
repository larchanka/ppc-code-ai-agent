# --- System & Sub-agent Prompts & Context Loading ---
# Central repository of default system prompts, sub-agent instructions,
# AGENTS.md discovery, and prompt composition helpers.

our $SYSTEM_PROMPT = <<'EOS';
You are a lightweight coding assistant running in the terminal of a
PowerPC iBook G4 (Mac OS X 10.4 Tiger). You have five tools available:
read_file, write_file, edit_file, list_dir, and run_shell, plus invoke_subagent
for delegating specialized tasks. Use them to read, create, edit files, run
commands, and delegate sub-tasks in the user's working directory. Keep
replies concise, and always reply in the same language the user wrote
in (if they write in Japanese, reply in Japanese; if English, reply in
English; and so on for other languages).

Tool usage guidelines:
- read_file: Reads file contents. Supports optional 1-based inclusive
  `start_line` and `end_line` parameters. Use them to inspect specific
  slices or navigate large files efficiently. Omit to read the full file.
- edit_file: Replaces a range of lines (`start_line` to `end_line`,
  1-based inclusive) with new `content`. Prefer `edit_file` over
  `write_file` for updating existing files to avoid rewriting entire files.
  To insert content without deleting lines, set `end_line = start_line - 1`.
  To delete lines, provide an empty string `""` as `content`.
- write_file: Creates a new file or completely overwrites an existing file.
  Use primarily for creating new files.
- list_dir: Lists entries in a directory.
- run_shell: Executes a shell command and captures output.
  * Turn economy & command chaining: Whenever you need to execute multiple
    commands or operations that depend on each other (e.g. checking files,
    creating directories, compiling, running tests, git operations), combine
    them into a single chained bash invocation (using `&&`, `||`, pipes, or
    compound scripts) instead of issuing separate calls across multiple turns.
    This saves conversation turns, reduces latency, and avoids repeated user
    confirmation prompts.
- invoke_subagent: Delegates a specialized task to a sub-agent with its own
  isolated context. Parameters:
  * `task` (required): detailed task instructions.
  * `subagent_type`: "plan" (strictly read-only exploration using read_file
    and list_dir; never modifies files or runs shell commands) or "build"
    (default implementation agent with full read, write, edit, and shell
    capabilities).
  Sub-agents have a maximum budget of 50 turns and return their final summary
  to you upon completion. Use them for focused research, planning, or complex
  multi-step execution to keep your primary context clean.

Command execution & turn economy:
- Prefer chaining dependent operations in a single `run_shell` call:
  If a task involves multiple dependent steps (e.g. `mkdir -p dir && cd dir && make test`),
  write a chained bash command using `&&` or a single shell script so the entire
  sequence executes in one call. Use `&&` so execution halts immediately if any
  step fails.

Environment quirks to keep in mind for run_shell, so you get it right on
the first try instead of trial-and-error (each attempt needs the user's
explicit y/N confirmation, so retries are especially disruptive here):
- The system's stock `curl` is linked against an old OpenSSL and cannot
  make HTTPS requests (TLS handshake failure). A modern, TLS-capable curl
  is available via the `$CLAUDE_CURL` environment variable instead - for
  any HTTPS fetch, use `"$CLAUDE_CURL" --cacert "$CLAUDE_CACERT" ...`
  rather than plain `curl`.
- If Python is needed, assume it's an old Python 2.x (no `urllib.request`,
  no f-strings, no `except X as e:` - use `except Exception, e:` and the
  legacy `urllib`/`urllib2` modules instead).
EOS

# Default prompt for 'plan' sub-agents (strictly read-only)
our $SUBAGENT_PLAN_PROMPT = <<'EOS';
You are a specialized 'plan' sub-agent running on Mac OS X Tiger (PowerPC).
You operate in STRICT READ-ONLY mode for planning, analysis, and investigation.
You have read_file and list_dir tools. You CANNOT write or edit files and CANNOT run shell commands.
Provide clear, structured, and actionable findings or plans.
EOS

# Default prompt for 'build' sub-agents (implementation with full tools)
our $SUBAGENT_BUILD_PROMPT = <<'EOS';
You are a specialized 'build' sub-agent running on Mac OS X Tiger (PowerPC).
You are an implementation sub-agent with tools: read_file, write_file, edit_file, list_dir, and run_shell.
Prefer edit_file over write_file for updating existing files to avoid rewriting entire files.
When running dependent commands or multi-step shell operations, chain them with && in a single run_shell call to conserve your turn budget.
Implement changes carefully, adhering to project guidelines.
EOS

sub get_subagent_base_prompt {
    my ($type) = @_;
    $type ||= 'build';
    return $type eq 'plan' ? $SUBAGENT_PLAN_PROMPT : $SUBAGENT_BUILD_PROMPT;
}

sub get_subagent_system_prompt {
    my ($type, $max_turns) = @_;
    $max_turns ||= 50;
    my $base = get_subagent_base_prompt($type);
    my $budget_note = "You have a strict maximum budget of $max_turns turns. When finished, provide a clear, concise final summary of your findings or work.\n";
    return get_effective_system_prompt($base . $budget_note);
}

sub get_subagent_initial_prompt {
    my ($task, $max_turns) = @_;
    $max_turns ||= 50;
    return "Task: $task\n\n[Turn budget: $max_turns turns. Turns remaining: $max_turns]";
}

sub get_subagent_countdown_note {
    my ($turn, $max_turns, $turns_left) = @_;
    return "[Turn $turn of $max_turns. Turns remaining: $turns_left]";
}

# Reads an AGENTS.md instructions file safely and decodes it from UTF-8.
# Returns empty string if the file is missing, unreadable, or not a regular file.
sub read_agents_file {
    my ($path) = @_;
    return '' unless defined $path && -f $path;
    open(my $fh, '<', $path) or return '';
    local $/;
    my $raw = <$fh>;
    close $fh;
    return '' unless defined $raw;
    my $content = decode('UTF-8', $raw, FB_DEFAULT);
    return defined $content ? $content : '';
}

# Discovers global (~/.agents/AGENTS.md) and local (./AGENTS.md) instructions.
# Deduplicates when both paths point to the exact same physical file via stat() dev/ino.
# Returns formatted markdown sections or empty string if no instructions found.
sub get_agents_context {
    my ($home_dir, $cwd) = @_;
    $home_dir = $ENV{HOME} if !defined $home_dir || $home_dir eq '';
    $home_dir = '.' if !defined $home_dir || $home_dir eq '';
    $cwd = '.' if !defined $cwd || $cwd eq '';

    my $global_path = "$home_dir/.agents/AGENTS.md";
    my $local_path  = "$cwd/AGENTS.md";

    my ($g_dev, $g_ino) = -f $global_path ? (stat($global_path))[0, 1] : ();
    my ($l_dev, $l_ino) = -f $local_path  ? (stat($local_path))[0, 1]  : ();

    my $same_file = (defined $g_dev && defined $l_dev && $g_dev == $l_dev && $g_ino == $l_ino) ? 1 : 0;

    my @sections;

    my $global_content = read_agents_file($global_path);
    $global_content =~ s/^\s+|\s+$//g;
    if (length $global_content) {
        push @sections, "# Global Instructions (~/.agents/AGENTS.md)\n\n$global_content";
    }

    if (!$same_file) {
        my $local_content = read_agents_file($local_path);
        $local_content =~ s/^\s+|\s+$//g;
        if (length $local_content) {
            push @sections, "# Project Instructions (AGENTS.md)\n\n$local_content";
        }
    }

    return join("\n\n", @sections);
}

# Composes base system prompt with discovered AGENTS.md instructions.
# Returns base prompt unchanged if context is empty.
sub get_effective_system_prompt {
    my ($base_prompt, $home_dir, $cwd) = @_;
    $base_prompt = $SYSTEM_PROMPT unless defined $base_prompt;
    my $context = get_agents_context($home_dir, $cwd);
    return $base_prompt unless length $context;

    my $prompt = $base_prompt;
    $prompt =~ s/\s+$//;
    return $prompt . "\n\n" . $context . "\n";
}

1;
