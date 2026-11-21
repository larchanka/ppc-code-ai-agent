# --- System & Sub-agent Prompts & Context Loading ---
# Central repository of default system prompts, sub-agent instructions,
# AGENTS.md discovery, and prompt composition helpers.

my $FILE_EDITING_RULES = <<'EOS';
<file_editing>
- Always read_file (supports 1-based start_line..end_line slices) before editing to verify exact line numbers.
- Prefer edit_file over write_file (1-based inclusive start_line..end_line) for updating existing files; use write_file mainly for new files.
- In edit_file: set end_line = start_line - 1 to insert without deleting; set content = "" to delete lines.
- When making multiple edits to one file, edit bottom-to-top (highest line numbers first) or re-read so line shifts do not corrupt code.
- Make surgical changes matching existing code style.
</file_editing>
EOS

my $TIGER_ENV_RULES = <<'EOS';
<tiger_env>
- Shell: Bash 2.05b (no `declare -A` or `|&`), BSD userland (`sed -i ''`, `find .`, no `grep -P`).
- HTTPS: Stock curl fails TLS; always use `"$CLAUDE_CURL" --cacert "$CLAUDE_CACERT" ...`.
- Toolchain: Perl 5.8.6 (core modules only), Python 2.3 (use `except X, e:` and `urllib2`, no f-strings), GCC 4.0 (C89/C99, ObjC 1.0).
</tiger_env>
EOS

our $SYSTEM_PROMPT = <<'EOS' . "\n" . $FILE_EDITING_RULES . "\n" . $TIGER_ENV_RULES;
You are a concise coding agent on a PowerPC G4 Mac (Mac OS X 10.4 Tiger).
Tools: read_file, write_file, edit_file, list_dir, run_shell, invoke_subagent.
Reply in the user's language. Keep output brief and 80-col terminal-friendly.

<turn_economy>
- Batch independent tool calls (e.g. multiple read_file or list_dir calls) in one turn to minimize API round-trips.
- Use command chaining (`&&`, `||`, pipes) in a single run_shell call for dependent steps to save turns and user y/N confirmations.
- Use invoke_subagent ("plan" for read-only exploration, "build" for multi-step implementation; 50-turn max) to keep main context small.
</turn_economy>
EOS

# Default prompt for 'plan' sub-agents (strictly read-only)
our $SUBAGENT_PLAN_PROMPT = <<'EOS';
You are a read-only 'plan' sub-agent on Mac OS X 10.4 Tiger (PowerPC).
Tools: read_file, list_dir only (no file edits or shell commands).

<turn_economy>
- Batch independent read_file and list_dir calls in a single turn to conserve your turn budget.
- Use start_line and end_line in read_file to inspect large files efficiently.
- Return a concise, actionable summary citing exact file paths and 1-based line numbers.
</turn_economy>
EOS

# Default prompt for 'build' sub-agents (implementation with full tools)
our $SUBAGENT_BUILD_PROMPT = <<'EOS' . "\n" . $FILE_EDITING_RULES . "\n" . $TIGER_ENV_RULES;
You are a 'build' implementation sub-agent on Mac OS X 10.4 Tiger (PowerPC).
Tools: read_file, write_file, edit_file, list_dir, run_shell.

<turn_economy>
- Batch independent tool calls in one turn to conserve your turn budget.
- Chain dependent shell commands with `&&` in a single run_shell call to save turns and user y/N confirmations.
</turn_economy>
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

# Formats an epoch timestamp into a human-readable date and time string.
# Defaults to time() if no epoch is provided.
sub get_current_datetime_string {
    my ($epoch) = @_;
    $epoch = time() unless defined $epoch;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($epoch);
    my @days   = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @months = qw(January February March April May June July August September October November December);
    return sprintf("%s, %s %d, %04d %02d:%02d:%02d",
        $days[$wday], $months[$mon], $mday, $year + 1900, $hour, $min, $sec);
}

# Composes base system prompt with current date/time and discovered AGENTS.md instructions.
sub get_effective_system_prompt {
    my ($base_prompt, $home_dir, $cwd, $now) = @_;
    $base_prompt = $SYSTEM_PROMPT unless defined $base_prompt;

    my $prompt = $base_prompt;
    $prompt =~ s/\s+$//;

    my $dt_str = "Current date and time: " . get_current_datetime_string($now);
    $prompt .= "\n\n" . $dt_str . "\n";

    my $context = get_agents_context($home_dir, $cwd);
    if (length $context) {
        $prompt .= "\n" . $context . "\n";
    }

    return $prompt;
}

1;
