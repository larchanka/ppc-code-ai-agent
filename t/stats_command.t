#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";
our $CURRENT_SESSION;
our $PROVIDER;

# ==================================================================
# Task 1: Session Stats Data Structure & Provider Token Extraction
# ==================================================================

# 1. init_session initializes stats data structure
my $session = init_session("test-stats-session");
ok(defined $session->{stats}, "init_session() creates stats field");
is(ref($session->{stats}), 'HASH', "stats is a hashref");
is($session->{stats}{api_calls}, 0, "stats api_calls initialized to 0");
is($session->{stats}{input_tokens}, 0, "stats input_tokens initialized to 0");
is($session->{stats}{output_tokens}, 0, "stats output_tokens initialized to 0");
is($session->{stats}{cache_read_tokens}, 0, "stats cache_read_tokens initialized to 0");
is($session->{stats}{cache_write_tokens}, 0, "stats cache_write_tokens initialized to 0");
is($session->{stats}{tool_calls}, 0, "stats tool_calls initialized to 0");
is($session->{stats}{subagent_calls}, 0, "stats subagent_calls initialized to 0");
is($session->{stats}{compact_count}, 0, "stats compact_count initialized to 0");
is($session->{stats}{bytes_saved}, 0, "stats bytes_saved initialized to 0");
is(ref($session->{stats}{tools}), 'HASH', "stats tools is a hashref");

# 2. get_session_stats helper and lazy initialization
my $stats_direct = get_session_stats($session);
is($stats_direct, $session->{stats}, "get_session_stats returns stats ref");

my $legacy_session = {
    id         => 'legacy-session-001',
    created_at => time(),
    messages   => [],
};
my $lazy_stats = get_session_stats($legacy_session);
ok(defined $lazy_stats, "get_session_stats lazily creates stats for legacy session");
is(ref($legacy_session->{stats}), 'HASH', "legacy session now has stats hashref");
is($lazy_stats->{api_calls}, 0, "legacy stats api_calls initialized to 0");

# 3. extract_api_usage - Anthropic
my $anthropic_resp = {
    content => [{ type => 'text', text => 'Hello' }],
    usage   => {
        input_tokens                => 150,
        output_tokens               => 45,
        cache_creation_input_tokens => 20,
        cache_read_input_tokens     => 80,
    },
};
my $ant_usage = extract_api_usage($anthropic_resp, 'anthropic');
is($ant_usage->{input_tokens}, 150, "Anthropic input_tokens extracted");
is($ant_usage->{output_tokens}, 45, "Anthropic output_tokens extracted");
is($ant_usage->{cache_write_tokens}, 20, "Anthropic cache_write_tokens extracted");
is($ant_usage->{cache_read_tokens}, 80, "Anthropic cache_read_tokens extracted");

# 4. extract_api_usage - Gemini
my $gemini_resp = {
    candidates => [{ content => { parts => [{ text => 'Hello' }] } }],
    usageMetadata => {
        promptTokenCount        => 220,
        candidatesTokenCount    => 60,
        cachedContentTokenCount => 110,
    },
};
my $gem_usage = extract_api_usage($gemini_resp, 'gemini');
is($gem_usage->{input_tokens}, 220, "Gemini input_tokens (promptTokenCount) extracted");
is($gem_usage->{output_tokens}, 60, "Gemini output_tokens (candidatesTokenCount) extracted");
is($gem_usage->{cache_read_tokens}, 110, "Gemini cache_read_tokens (cachedContentTokenCount) extracted");
is($gem_usage->{cache_write_tokens}, 0, "Gemini cache_write_tokens defaults to 0");

# 5. extract_api_usage - OpenAI
my $openai_resp = {
    choices => [{ message => { role => 'assistant', content => 'Hello' } }],
    usage   => {
        prompt_tokens         => 310,
        completion_tokens     => 75,
        total_tokens          => 385,
        prompt_tokens_details => {
            cached_tokens => 95,
        },
    },
};
my $oai_usage = extract_api_usage($openai_resp, 'openai');
is($oai_usage->{input_tokens}, 310, "OpenAI input_tokens (prompt_tokens) extracted");
is($oai_usage->{output_tokens}, 75, "OpenAI output_tokens (completion_tokens) extracted");
is($oai_usage->{cache_read_tokens}, 95, "OpenAI cache_read_tokens (cached_tokens) extracted");
is($oai_usage->{cache_write_tokens}, 0, "OpenAI cache_write_tokens defaults to 0");

# 6. extract_api_usage - Missing / invalid usage
my $empty_usage = extract_api_usage({}, 'anthropic');
is($empty_usage->{input_tokens}, 0, "missing usage returns 0 input_tokens");
is($empty_usage->{output_tokens}, 0, "missing usage returns 0 output_tokens");
is($empty_usage->{cache_read_tokens}, 0, "missing usage returns 0 cache_read_tokens");
is($empty_usage->{cache_write_tokens}, 0, "missing usage returns 0 cache_write_tokens");

my $undef_usage = extract_api_usage(undef, 'anthropic');
is($undef_usage->{input_tokens}, 0, "undef resp returns 0 input_tokens");

# 7. record_session_api_usage
my $test_session = init_session("test-record-session");
$test_session->{provider} = 'anthropic';
my $rec1 = record_session_api_usage($anthropic_resp, $test_session, 'anthropic');
is($test_session->{stats}{api_calls}, 1, "record_session_api_usage increments api_calls");
is($test_session->{stats}{input_tokens}, 150, "record_session_api_usage accumulates input_tokens");
is($test_session->{stats}{output_tokens}, 45, "record_session_api_usage accumulates output_tokens");
is($test_session->{stats}{cache_read_tokens}, 80, "record_session_api_usage accumulates cache_read_tokens");
is($test_session->{stats}{cache_write_tokens}, 20, "record_session_api_usage accumulates cache_write_tokens");

# Second API call accumulation
record_session_api_usage({
    usage => {
        input_tokens  => 50,
        output_tokens => 10,
    }
}, $test_session, 'anthropic');
is($test_session->{stats}{api_calls}, 2, "second call increments api_calls to 2");
is($test_session->{stats}{input_tokens}, 200, "accumulates input_tokens to 200");
is($test_session->{stats}{output_tokens}, 55, "accumulates output_tokens to 55");

# Record on legacy session without stats
my $legacy2 = { id => 'legacy-2', messages => [] };
record_session_api_usage($anthropic_resp, $legacy2, 'anthropic');
is($legacy2->{stats}{api_calls}, 1, "record_session_api_usage handles legacy session without stats");
is($legacy2->{stats}{input_tokens}, 150, "legacy session accumulates tokens");

# ==================================================================
# Task 2: Live Activity & Tool Call Tracking
# ==================================================================

# 1. record_session_tool_call
my $tool_session = init_session("test-tool-session");
record_session_tool_call("read_file", $tool_session);
is($tool_session->{stats}{tool_calls}, 1, "tool_calls incremented to 1");
is($tool_session->{stats}{tools}{read_file}, 1, "read_file count incremented to 1");

record_session_tool_call("read_file", $tool_session);
record_session_tool_call("edit_file", $tool_session);
is($tool_session->{stats}{tool_calls}, 3, "tool_calls incremented to 3");
is($tool_session->{stats}{tools}{read_file}, 2, "read_file count incremented to 2");
is($tool_session->{stats}{tools}{edit_file}, 1, "edit_file count incremented to 1");

# Default session fallback
$CURRENT_SESSION = $tool_session;
record_session_tool_call("run_shell");
is($tool_session->{stats}{tool_calls}, 4, "tool_calls incremented via CURRENT_SESSION default");
is($tool_session->{stats}{tools}{run_shell}, 1, "run_shell count incremented to 1");

# Legacy session auto-vivification
my $legacy_tool_session = { id => 'legacy-tool', messages => [] };
record_session_tool_call("list_dir", $legacy_tool_session);
is($legacy_tool_session->{stats}{tool_calls}, 1, "legacy session tool_calls incremented");
is($legacy_tool_session->{stats}{tools}{list_dir}, 1, "legacy session list_dir count incremented");

# 2. compact_session_history records stats
my $compact_session = init_session("test-compact-session");
my $long_output = join("\n", map { "Line $_ of verbose tool output" } (1 .. 100));
$compact_session->{messages} = [
    { role => 'user', content => 'Run tool' },
    { role => 'assistant', content => [ { type => 'tool_use', id => 'call_1', name => 'read_file', input => {} } ] },
    { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'call_1', name => 'read_file', content => $long_output } ] },
    { role => 'assistant', content => [ { type => 'text', text => 'Done' } ] },
    { role => 'user', content => 'Next prompt' },
    { role => 'assistant', content => [ { type => 'text', text => 'Answer' } ] },
    { role => 'user', content => 'Another prompt' },
    { role => 'assistant', content => [ { type => 'text', text => 'Answer' } ] },
];

my $c_stats = compact_session_history($compact_session, keep_turns => 1, max_lines => 10, head_lines => 2, tail_lines => 2);
is($c_stats->{compacted_count}, 1, "compacted 1 tool result");
is($compact_session->{stats}{compact_count}, 1, "session stats compact_count incremented to 1");
is($compact_session->{stats}{bytes_saved}, $c_stats->{bytes_saved}, "session stats bytes_saved matches returned bytes_saved");
ok($compact_session->{stats}{bytes_saved} > 0, "session stats bytes_saved > 0");

# Second compaction with no compactable messages does not increment stats
compact_session_history($compact_session, keep_turns => 1);
is($compact_session->{stats}{compact_count}, 1, "session stats compact_count unchanged when no items compacted");

# 3. run_subagent tracks subagent calls, API usage, and tool executions in CURRENT_SESSION
$ENV{ANTHROPIC_API_KEY} = 'test-ant-key';
configure_provider('anthropic');
my $sub_parent_session = init_session("subagent-parent-session");
$CURRENT_SESSION = $sub_parent_session;

{
    my $sub_turn = 0;
    no warnings qw(redefine once);
    local *call_api = sub {
        $sub_turn++;
        if ($sub_turn == 1) {
            return {
                content => [
                    {
                        type  => 'tool_use',
                        id    => 'sub_tool_1',
                        name  => 'read_file',
                        input => { path => 'code-agent.pl' },
                    }
                ],
                usage => {
                    input_tokens  => 100,
                    output_tokens => 25,
                },
            };
        }
        else {
            return {
                content => [
                    {
                        type => 'text',
                        text => 'Subagent completed task.',
                    }
                ],
                usage => {
                    input_tokens  => 150,
                    output_tokens => 40,
                },
            };
        }
    };
    use warnings 'redefine';

    my $sub_res = run_subagent("Review code", "plan");
    is($sub_res, "Subagent completed task.", "subagent returned final text");
    is($sub_parent_session->{stats}{subagent_calls}, 1, "parent session recorded 1 subagent_call");
    is($sub_parent_session->{stats}{api_calls}, 2, "parent session recorded 2 API calls from subagent");
    is($sub_parent_session->{stats}{input_tokens}, 250, "parent session accumulated input tokens from subagent");
    is($sub_parent_session->{stats}{output_tokens}, 65, "parent session accumulated output tokens from subagent");
    is($sub_parent_session->{stats}{tool_calls}, 1, "parent session recorded 1 tool call from subagent");
    is($sub_parent_session->{stats}{tools}{read_file}, 1, "parent session recorded read_file from subagent");
}

# ==================================================================
# Task 3: Formatting Engine & handle_stats_command
# ==================================================================

# 1. format_duration
is(format_duration(0), "0s", "format_duration(0) returns 0s");
is(format_duration(14), "14s", "format_duration(14) returns 14s");
is(format_duration(59), "59s", "format_duration(59) returns 59s");
is(format_duration(60), "1m 0s", "format_duration(60) returns 1m 0s");
is(format_duration(202), "3m 22s", "format_duration(202) returns 3m 22s");
is(format_duration(3600), "1h 0m 0s", "format_duration(3600) returns 1h 0m 0s");
is(format_duration(4500), "1h 15m 0s", "format_duration(4500) returns 1h 15m 0s");
is(format_duration(7325), "2h 2m 5s", "format_duration(7325) returns 2h 2m 5s");
is(format_duration(undef), "0s", "format_duration(undef) returns 0s");
is(format_duration(-15), "0s", "format_duration negative returns 0s");

# 2. format_number_comma
is(format_number_comma(0), "0", "format_number_comma(0) returns 0");
is(format_number_comma(42), "42", "format_number_comma(42) returns 42");
is(format_number_comma(999), "999", "format_number_comma(999) returns 999");
is(format_number_comma(1000), "1,000", "format_number_comma(1000) returns 1,000");
is(format_number_comma(12345), "12,345", "format_number_comma(12345) returns 12,345");
is(format_number_comma(1234567), "1,234,567", "format_number_comma(1234567) returns 1,234,567");
is(format_number_comma(undef), "0", "format_number_comma(undef) returns 0");
is(format_number_comma(-12345), "-12,345", "format_number_comma(-12345) returns -12,345");

# 3. count_assistant_turns
my $turn_session = init_session("turns-test-session");
is(count_assistant_turns($turn_session), 0, "empty session has 0 assistant turns");
$turn_session->{messages} = [
    { role => 'user', content => 'Hello' },
    { role => 'assistant', content => [ { type => 'tool_use', id => 'c1', name => 'read_file', input => {} } ] },
    { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'c1', name => 'read_file', content => 'data' } ] },
    { role => 'assistant', content => [ { type => 'text', text => 'Answer' } ] },
    { role => 'user', content => 'Second turn' },
    { role => 'assistant', content => [ { type => 'text', text => 'Second answer' } ] },
];
is(count_user_turns($turn_session), 2, "count_user_turns returns 2 actual user turns");
is(count_assistant_turns($turn_session), 3, "count_assistant_turns returns 3 assistant responses");

# 4. format_session_stats output verification
my $stats_session = {
    id         => 'test-stats-session-999',
    created_at => time() - 202, # 3m 22s ago
    provider   => 'anthropic',
    model      => 'claude-3-5-sonnet-20241022',
    messages   => $turn_session->{messages},
    stats      => {
        api_calls          => 5,
        input_tokens       => 12500,
        output_tokens      => 3400,
        cache_read_tokens  => 5000,
        cache_write_tokens => 1200,
        tool_calls         => 4,
        subagent_calls     => 2,
        compact_count      => 1,
        bytes_saved        => 8192,
        tools              => {
            read_file => 3,
            edit_file => 1,
        },
    },
};

my $formatted_report = format_session_stats($stats_session);
ok(defined $formatted_report && length($formatted_report) > 0, "format_session_stats returns non-empty string");
like($formatted_report, qr/Session Statistics/i, "report contains Session Statistics header");
like($formatted_report, qr/Session ID:\s+test-stats-session-999/, "report contains Session ID");
like($formatted_report, qr/Provider:\s+anthropic/, "report contains Provider");
like($formatted_report, qr/Model:\s+claude-3-5-sonnet-20241022/, "report contains Model");
like($formatted_report, qr/Duration:\s+3m 22s/, "report contains formatted Duration");
like($formatted_report, qr/Started:/, "report contains Started timestamp");

# Activity section
like($formatted_report, qr/Activity:/i, "report contains Activity section");
like($formatted_report, qr/User turns:\s+2/, "report contains User turns");
like($formatted_report, qr/Assistant turns:\s+3/, "report contains Assistant turns");
like($formatted_report, qr/Total messages:\s+6/, "report contains Total messages");
like($formatted_report, qr/API calls:\s+5/, "report contains API calls");
like($formatted_report, qr/Context size:/, "report contains Context size");

# Token Usage section
like($formatted_report, qr/Token Usage:/i, "report contains Token Usage section");
like($formatted_report, qr/Input tokens:\s+12,500/, "report contains formatted Input tokens");
like($formatted_report, qr/Output tokens:\s+3,400/, "report contains formatted Output tokens");
like($formatted_report, qr/Total tokens:\s+15,900/, "report contains formatted Total tokens");
like($formatted_report, qr/Cache read:\s+5,000/, "report contains formatted Cache read tokens");
like($formatted_report, qr/Cache write:\s+1,200/, "report contains formatted Cache write tokens");

# Tool Invocations section
like($formatted_report, qr/Tool Invocations:/i, "report contains Tool Invocations section");
like($formatted_report, qr/Total tool calls:\s+4/, "report contains Total tool calls");
like($formatted_report, qr/Sub-agents:\s+2/, "report contains Sub-agents count");
# Alphabetical breakdown
like($formatted_report, qr/edit_file:\s+1.*read_file:\s+3/s, "report lists tools in alphabetical order");

# Compaction section
like($formatted_report, qr/Context Compaction:/i, "report contains Compaction section when compact_count > 0");
like($formatted_report, qr/Compactions:\s+1/, "report contains Compactions count");
like($formatted_report, qr/Bytes saved:\s+8,192/, "report contains formatted Bytes saved");

# Clean session without compaction or cache tokens
my $clean_session = {
    id         => 'clean-session-001',
    created_at => time() - 14,
    provider   => 'openai',
    model      => 'gpt-4o',
    messages   => [],
    stats      => {
        api_calls          => 1,
        input_tokens       => 100,
        output_tokens      => 20,
        cache_read_tokens  => 0,
        cache_write_tokens => 0,
        tool_calls         => 0,
        subagent_calls     => 0,
        compact_count      => 0,
        bytes_saved        => 0,
        tools              => {},
    },
};
my $clean_report = format_session_stats($clean_session);
unlike($clean_report, qr/Context Compaction:/i, "clean report omits Compaction section when 0");
unlike($clean_report, qr/Cache read:/i, "clean report omits Cache read when 0");
unlike($clean_report, qr/Sub-agents:/i, "clean report omits Sub-agents when 0");

# 5. handle_stats_command
{
    my $output_buf = '';
    open(my $mem_fh, '>', \$output_buf);
    my $ret = handle_stats_command($mem_fh, $stats_session);
    close($mem_fh);
    is($ret, 1, "handle_stats_command returns 1 on success");
    like($output_buf, qr/Session Statistics/i, "handle_stats_command writes report to output handle");
    like($output_buf, qr/test-stats-session-999/, "output contains session ID");
}

# handle_stats_command with undef session
{
    my $output_buf = '';
    open(my $mem_fh, '>', \$output_buf);
    $CURRENT_SESSION = undef;
    my $ret = handle_stats_command($mem_fh, undef);
    close($mem_fh);
    is($ret, undef, "handle_stats_command returns undef when no session");
    like($output_buf, qr/No active session/i, "handle_stats_command reports No active session");
}

# ==================================================================
# Task 4: CLI Command Dispatch & Help Documentation
# ==================================================================

# 1. show_help documentation includes /stats
{
    my $help_buf = '';
    open(my $hfh, '>', \$help_buf);
    show_help($hfh);
    close($hfh);
    like($help_buf, qr{/stats\s+-\s+View current session statistics}, "show_help includes /stats with description");
}

# 2. handle_new_command resets session stats
{
    my $dirty_session = init_session("dirty-session");
    $dirty_session->{stats}{api_calls} = 10;
    $dirty_session->{stats}{input_tokens} = 5000;
    $CURRENT_SESSION = $dirty_session;

    my $new_buf = '';
    open(my $nfh, '>', \$new_buf);
    handle_new_command($nfh);
    close($nfh);

    isnt($CURRENT_SESSION->{id}, "dirty-session", "handle_new_command generated a new session");
    my $new_stats = get_session_stats($CURRENT_SESSION);
    is($new_stats->{api_calls}, 0, "new session stats api_calls reset to 0");
    is($new_stats->{input_tokens}, 0, "new session stats input_tokens reset to 0");
    is($new_stats->{output_tokens}, 0, "new session stats output_tokens reset to 0");
    is($new_stats->{tool_calls}, 0, "new session stats tool_calls reset to 0");
}

# 3. Interactive CLI dispatch of /stats
{
    my $script = "$root_dir/code-agent.pl";
    my $cmd = qq{printf "/stats\\nexit\\n" | } .
              qq{HOME="/nonexistent" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
              qq{$^X $script 2>&1};
    my $output = `$cmd`;
    like($output, qr{=== Session Statistics ===}, "Interactive loop dispatched /stats command");
    like($output, qr{Activity:}, "Interactive /stats output contains Activity section");
    like($output, qr{Token Usage:}, "Interactive /stats output contains Token Usage section");
    like($output, qr{Tool Invocations:}, "Interactive /stats output contains Tool Invocations section");
}

done_testing();


