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

# ==================================================================
# Task 1: Session Stats State & Accessors
# ==================================================================

# 1. init_session initializes stats structure
my $s1 = init_session();
ok(defined $s1 && ref($s1) eq 'HASH', "init_session() returns session hashref");
ok(defined $s1->{stats} && ref($s1->{stats}) eq 'HASH', "session contains stats hashref");
is($s1->{stats}{prompt_tokens}, 0, "stats: prompt_tokens initialized to 0");
is($s1->{stats}{completion_tokens}, 0, "stats: completion_tokens initialized to 0");
is($s1->{stats}{total_tokens}, 0, "stats: total_tokens initialized to 0");
is($s1->{stats}{tool_calls}, 0, "stats: tool_calls initialized to 0");
is($s1->{stats}{subagents}, 0, "stats: subagents initialized to 0");
is(ref($s1->{stats}{tool_counts}), 'HASH', "stats: tool_counts is empty hashref");
is(scalar(keys %{$s1->{stats}{tool_counts}}), 0, "stats: tool_counts has 0 keys");
is(ref($s1->{stats}{subagent_counts}), 'HASH', "stats: subagent_counts is empty hashref");
is(scalar(keys %{$s1->{stats}{subagent_counts}}), 0, "stats: subagent_counts has 0 keys");
is($s1->{stats}{api_calls}, 0, "stats: api_calls initialized to 0");
ok(defined $s1->{stats}{start_time} && $s1->{stats}{start_time} > 0, "stats: start_time initialized to positive timestamp");

# 2. get_session_stats accessor
my $stats1 = get_session_stats($s1);
is($stats1, $s1->{stats}, "get_session_stats(\$s1) returns stats hashref");

# Defaults to $CURRENT_SESSION
my $stats_curr = get_session_stats();
is($stats_curr, $CURRENT_SESSION->{stats}, "get_session_stats() defaults to \$CURRENT_SESSION");

# Lazy initialization if {stats} is missing from session hashref
my $raw_session = { id => 'raw-test-session', created_at => time() - 100 };
my $lazy_stats = get_session_stats($raw_session);
ok(defined $lazy_stats && ref($lazy_stats) eq 'HASH', "get_session_stats lazily creates stats when missing");
is($lazy_stats->{start_time}, $raw_session->{created_at}, "lazy stats uses session created_at if present");
is($lazy_stats->{prompt_tokens}, 0, "lazy stats prompt_tokens initialized to 0");

# Returns undef if session is undef and $CURRENT_SESSION is undef
$CURRENT_SESSION = undef;
my $no_stats = get_session_stats(undef);
is($no_stats, undef, "get_session_stats(undef) returns undef when no current session");

# Reinitialize session
init_session();

# 3. record_session_tokens
my $rec_res = record_session_tokens($CURRENT_SESSION, 120, 80, 200);
ok(defined $rec_res, "record_session_tokens returns defined");
is($CURRENT_SESSION->{stats}{prompt_tokens}, 120, "record_session_tokens recorded prompt_tokens");
is($CURRENT_SESSION->{stats}{completion_tokens}, 80, "record_session_tokens recorded completion_tokens");
is($CURRENT_SESSION->{stats}{total_tokens}, 200, "record_session_tokens recorded total_tokens");
is($CURRENT_SESSION->{stats}{api_calls}, 1, "record_session_tokens incremented api_calls");

# Second record call accumulates
record_session_tokens($CURRENT_SESSION, 50, 25, 75);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 170, "prompt_tokens accumulated (120+50)");
is($CURRENT_SESSION->{stats}{completion_tokens}, 105, "completion_tokens accumulated (80+25)");
is($CURRENT_SESSION->{stats}{total_tokens}, 275, "total_tokens accumulated (200+75)");
is($CURRENT_SESSION->{stats}{api_calls}, 2, "api_calls accumulated to 2");

# When total is omitted or undef, auto-calculated from prompt + completion
record_session_tokens($CURRENT_SESSION, 30, 40);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 200, "prompt_tokens accumulated (170+30)");
is($CURRENT_SESSION->{stats}{completion_tokens}, 145, "completion_tokens accumulated (105+40)");
is($CURRENT_SESSION->{stats}{total_tokens}, 345, "total_tokens auto-calculated (275+70)");
is($CURRENT_SESSION->{stats}{api_calls}, 3, "api_calls accumulated to 3");

# Positional tolerance: ($in, $out, $total, $session)
record_session_tokens(10, 10, 20, $CURRENT_SESSION);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 210, "prompt_tokens with session last");
is($CURRENT_SESSION->{stats}{completion_tokens}, 155, "completion_tokens with session last");
is($CURRENT_SESSION->{stats}{total_tokens}, 365, "total_tokens with session last");

# Defaulting to $CURRENT_SESSION when session not passed
record_session_tokens(5, 5, 10);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 215, "prompt_tokens with default session");
is($CURRENT_SESSION->{stats}{completion_tokens}, 160, "completion_tokens with default session");
is($CURRENT_SESSION->{stats}{total_tokens}, 375, "total_tokens with default session");

# Defensive handling of non-numeric or undef inputs
record_session_tokens($CURRENT_SESSION, undef, 'abc', undef);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 215, "prompt_tokens unchanged on invalid input");
is($CURRENT_SESSION->{stats}{completion_tokens}, 160, "completion_tokens unchanged on invalid input");
is($CURRENT_SESSION->{stats}{total_tokens}, 375, "total_tokens unchanged on invalid input");
is($CURRENT_SESSION->{stats}{api_calls}, 6, "api_calls still incremented");

# 4. record_session_tool_call
record_session_tool_call($CURRENT_SESSION, 'read_file');
is($CURRENT_SESSION->{stats}{tool_calls}, 1, "record_session_tool_call incremented tool_calls");
is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 1, "read_file tool count is 1");

record_session_tool_call($CURRENT_SESSION, 'read_file');
is($CURRENT_SESSION->{stats}{tool_calls}, 2, "tool_calls incremented to 2");
is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 2, "read_file count incremented to 2");

record_session_tool_call($CURRENT_SESSION, 'edit_file');
is($CURRENT_SESSION->{stats}{tool_calls}, 3, "tool_calls incremented to 3");
is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 2, "read_file count preserved at 2");
is($CURRENT_SESSION->{stats}{tool_counts}{edit_file}, 1, "edit_file count is 1");

# Positional tolerance: ($tool_name, $session)
record_session_tool_call('run_shell', $CURRENT_SESSION);
is($CURRENT_SESSION->{stats}{tool_calls}, 4, "tool_calls incremented with session last");
is($CURRENT_SESSION->{stats}{tool_counts}{run_shell}, 1, "run_shell count is 1");

# Default to $CURRENT_SESSION
record_session_tool_call('run_shell');
is($CURRENT_SESSION->{stats}{tool_calls}, 5, "tool_calls incremented with default session");
is($CURRENT_SESSION->{stats}{tool_counts}{run_shell}, 2, "run_shell count incremented to 2");

# 5. record_session_subagent
record_session_subagent($CURRENT_SESSION, 'plan');
is($CURRENT_SESSION->{stats}{subagents}, 1, "subagents incremented to 1");
is($CURRENT_SESSION->{stats}{subagent_counts}{plan}, 1, "plan subagent count is 1");

record_session_subagent($CURRENT_SESSION, 'plan');
is($CURRENT_SESSION->{stats}{subagents}, 2, "subagents incremented to 2");
is($CURRENT_SESSION->{stats}{subagent_counts}{plan}, 2, "plan subagent count incremented to 2");

record_session_subagent($CURRENT_SESSION, 'build');
is($CURRENT_SESSION->{stats}{subagents}, 3, "subagents incremented to 3");
is($CURRENT_SESSION->{stats}{subagent_counts}{build}, 1, "build subagent count is 1");

# Positional tolerance: ($type, $session)
record_session_subagent('review', $CURRENT_SESSION);
is($CURRENT_SESSION->{stats}{subagents}, 4, "subagents incremented with session last");
is($CURRENT_SESSION->{stats}{subagent_counts}{review}, 1, "review subagent count is 1");

# Default to $CURRENT_SESSION
record_session_subagent('review');
is($CURRENT_SESSION->{stats}{subagents}, 5, "subagents incremented with default session");
is($CURRENT_SESSION->{stats}{subagent_counts}{review}, 2, "review subagent count incremented to 2");

# 6. handle_new_command cleanly resets stats and archives old session
my $old_session = $CURRENT_SESSION;
my $new_session_out = '';
open my $nfh, '>', \$new_session_out or die "Cannot open memory fh: $!";
my $new_session = handle_new_command($nfh, $old_session);
close $nfh;

ok(defined $new_session, "handle_new_command returns new session");
isnt($new_session, $old_session, "new session is distinct from old session");
is($CURRENT_SESSION, $new_session, "CURRENT_SESSION updated to new session");

# Check old session stats preserved
is($old_session->{stats}{prompt_tokens}, 215, "archived session preserved prompt_tokens");
is($old_session->{stats}{tool_calls}, 5, "archived session preserved tool_calls");
is($old_session->{stats}{subagents}, 5, "archived session preserved subagents");

# Check new session stats zeroed
is($new_session->{stats}{prompt_tokens}, 0, "new session prompt_tokens is 0");
is($new_session->{stats}{completion_tokens}, 0, "new session completion_tokens is 0");
is($new_session->{stats}{total_tokens}, 0, "new session total_tokens is 0");
is($new_session->{stats}{tool_calls}, 0, "new session tool_calls is 0");
is($new_session->{stats}{subagents}, 0, "new session subagents is 0");
is($new_session->{stats}{api_calls}, 0, "new session api_calls is 0");
is(scalar(keys %{$new_session->{stats}{tool_counts}}), 0, "new session tool_counts is empty");
is(scalar(keys %{$new_session->{stats}{subagent_counts}}), 0, "new session subagent_counts is empty");
ok($new_session->{stats}{start_time} >= $old_session->{stats}{start_time}, "new session start_time is updated");

# ==================================================================
# Task 2: Multi-Provider Token Usage Extraction
# ==================================================================

# 1. Anthropic usage extraction
my $anthropic_resp = {
    id      => 'msg_01XYZ',
    type    => 'message',
    role    => 'assistant',
    content => [ { type => 'text', text => 'Hello' } ],
    usage   => {
        input_tokens  => 42,
        output_tokens => 18,
    },
};
my $ant_usage = extract_token_usage($anthropic_resp);
ok(defined $ant_usage && ref($ant_usage) eq 'HASH', "Anthropic: extract_token_usage returns hashref");
is($ant_usage->{prompt_tokens}, 42, "Anthropic: prompt_tokens is 42");
is($ant_usage->{completion_tokens}, 18, "Anthropic: completion_tokens is 18");
is($ant_usage->{total_tokens}, 60, "Anthropic: total_tokens is 60 (calculated 42+18)");

# Anthropic with explicit total_tokens if present
my $anthropic_resp_total = {
    usage => {
        input_tokens  => 50,
        output_tokens => 20,
        total_tokens  => 70,
    },
};
my $ant_usage_total = extract_token_usage($anthropic_resp_total);
is($ant_usage_total->{total_tokens}, 70, "Anthropic: total_tokens respected when provided");

# 2. OpenAI usage extraction
my $openai_resp = {
    id      => 'chatcmpl-123',
    object  => 'chat.completion',
    choices => [ { message => { role => 'assistant', content => 'Hi' } } ],
    usage   => {
        prompt_tokens     => 150,
        completion_tokens => 35,
        total_tokens      => 185,
    },
};
my $oai_usage = extract_token_usage($openai_resp);
ok(defined $oai_usage && ref($oai_usage) eq 'HASH', "OpenAI: extract_token_usage returns hashref");
is($oai_usage->{prompt_tokens}, 150, "OpenAI: prompt_tokens is 150");
is($oai_usage->{completion_tokens}, 35, "OpenAI: completion_tokens is 35");
is($oai_usage->{total_tokens}, 185, "OpenAI: total_tokens is 185");

# OpenAI without total_tokens (auto-sum)
my $openai_resp_nototal = {
    usage => {
        prompt_tokens     => 100,
        completion_tokens => 50,
    },
};
my $oai_usage_nototal = extract_token_usage($openai_resp_nototal);
is($oai_usage_nototal->{total_tokens}, 150, "OpenAI: total_tokens calculated if missing");

# 3. Gemini usageMetadata extraction
my $gemini_resp = {
    candidates    => [ { content => { parts => [ { text => 'Greetings' } ] } } ],
    usageMetadata => {
        promptTokenCount     => 220,
        candidatesTokenCount => 45,
        totalTokenCount      => 265,
    },
};
my $gem_usage = extract_token_usage($gemini_resp);
ok(defined $gem_usage && ref($gem_usage) eq 'HASH', "Gemini: extract_token_usage returns hashref");
is($gem_usage->{prompt_tokens}, 220, "Gemini: prompt_tokens is 220");
is($gem_usage->{completion_tokens}, 45, "Gemini: completion_tokens is 45");
is($gem_usage->{total_tokens}, 265, "Gemini: total_tokens is 265");

# Gemini without totalTokenCount (auto-sum)
my $gemini_resp_nototal = {
    usageMetadata => {
        promptTokenCount     => 80,
        candidatesTokenCount => 20,
    },
};
my $gem_usage_nototal = extract_token_usage($gemini_resp_nototal);
is($gem_usage_nototal->{total_tokens}, 100, "Gemini: total_tokens calculated if missing");

# 4. Partial fields / edge cases
my $ant_partial = extract_token_usage({ usage => { input_tokens => 30 } });
ok(defined $ant_partial, "extract_token_usage defined for partial Anthropic usage");
is($ant_partial->{prompt_tokens}, 30, "partial: prompt_tokens is 30");
is($ant_partial->{completion_tokens}, 0, "partial: missing completion_tokens defaults to 0");
is($ant_partial->{total_tokens}, 30, "partial: total_tokens is 30");

my $oai_partial = extract_token_usage({ usage => { completion_tokens => 15 } });
ok(defined $oai_partial, "extract_token_usage defined for partial OpenAI usage");
is($oai_partial->{prompt_tokens}, 0, "partial: missing prompt_tokens defaults to 0");
is($oai_partial->{completion_tokens}, 15, "partial: completion_tokens is 15");
is($oai_partial->{total_tokens}, 15, "partial: total_tokens is 15");

my $gem_partial = extract_token_usage({ usageMetadata => { promptTokenCount => 99 } });
ok(defined $gem_partial, "extract_token_usage defined for partial Gemini usage");
is($gem_partial->{prompt_tokens}, 99, "partial: prompt_tokens is 99");
is($gem_partial->{completion_tokens}, 0, "partial: completion_tokens is 0");
is($gem_partial->{total_tokens}, 99, "partial: total_tokens is 99");

# 5. Invalid / missing usage cases (safely return undef)
is(extract_token_usage(undef), undef, "extract_token_usage(undef) returns undef");
is(extract_token_usage("string"), undef, "extract_token_usage(string) returns undef");
is(extract_token_usage([]), undef, "extract_token_usage([]) returns undef");
is(extract_token_usage({}), undef, "extract_token_usage({}) returns undef");
is(extract_token_usage({ usage => {} }), undef, "extract_token_usage({ usage => {} }) returns undef");
is(extract_token_usage({ usageMetadata => {} }), undef, "extract_token_usage({ usageMetadata => {} }) returns undef");
is(extract_token_usage({ usage => "bad" }), undef, "extract_token_usage({ usage => 'bad' }) returns undef");
is(extract_token_usage({ usageMetadata => "bad" }), undef, "extract_token_usage({ usageMetadata => 'bad' }) returns undef");

# 6. record_api_response_stats
init_session();
my $rec_ant = record_api_response_stats($anthropic_resp, $CURRENT_SESSION);
ok(defined $rec_ant, "record_api_response_stats returns stats hashref for Anthropic response");
is($CURRENT_SESSION->{stats}{prompt_tokens}, 42, "session prompt_tokens recorded from Anthropic");
is($CURRENT_SESSION->{stats}{completion_tokens}, 18, "session completion_tokens recorded from Anthropic");
is($CURRENT_SESSION->{stats}{total_tokens}, 60, "session total_tokens recorded from Anthropic");
is($CURRENT_SESSION->{stats}{api_calls}, 1, "session api_calls incremented to 1");

record_api_response_stats($openai_resp, $CURRENT_SESSION);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 192, "session prompt_tokens accumulated (42+150)");
is($CURRENT_SESSION->{stats}{completion_tokens}, 53, "session completion_tokens accumulated (18+35)");
is($CURRENT_SESSION->{stats}{total_tokens}, 245, "session total_tokens accumulated (60+185)");
is($CURRENT_SESSION->{stats}{api_calls}, 2, "session api_calls incremented to 2");

record_api_response_stats($gemini_resp);
is($CURRENT_SESSION->{stats}{prompt_tokens}, 412, "session prompt_tokens accumulated (192+220)");
is($CURRENT_SESSION->{stats}{completion_tokens}, 98, "session completion_tokens accumulated (53+45)");
is($CURRENT_SESSION->{stats}{total_tokens}, 510, "session total_tokens accumulated (245+265)");
is($CURRENT_SESSION->{stats}{api_calls}, 3, "session api_calls incremented to 3");

record_api_response_stats({ content => "no usage" });
is($CURRENT_SESSION->{stats}{prompt_tokens}, 412, "prompt_tokens unchanged when usage missing");
is($CURRENT_SESSION->{stats}{completion_tokens}, 98, "completion_tokens unchanged when usage missing");
is($CURRENT_SESSION->{stats}{total_tokens}, 510, "total_tokens unchanged when usage missing");
is($CURRENT_SESSION->{stats}{api_calls}, 4, "api_calls incremented even without usage");

my $undef_rec = record_api_response_stats(undef);
is($undef_rec, undef, "record_api_response_stats(undef) returns undef");
is($CURRENT_SESSION->{stats}{api_calls}, 4, "api_calls unchanged on undef response");

# ==================================================================
# Task 3: Instrument Tool Execution & Sub-Agent Aggregation
# ==================================================================

# 1. run_tool increments session tool_calls and tool_counts breakdown
{
    init_session();
    is($CURRENT_SESSION->{stats}{tool_calls}, 0, "fresh session: tool_calls is 0");
    is(scalar(keys %{$CURRENT_SESSION->{stats}{tool_counts}}), 0, "fresh session: tool_counts is empty");

    # Call run_tool with read_file (non-existent file will return error, but still counts as a tool call)
    my $res1 = run_tool('read_file', { path => 'non_existent_file_xyz_123.txt' });
    like($res1, qr/Error:/, "read_file returned error for nonexistent file");
    is($CURRENT_SESSION->{stats}{tool_calls}, 1, "run_tool incremented session tool_calls to 1");
    is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 1, "tool_counts for read_file is 1");

    # Call run_tool with list_dir
    my $res2 = run_tool('list_dir', { path => '.' });
    ok(length($res2) > 0, "list_dir returned content");
    is($CURRENT_SESSION->{stats}{tool_calls}, 2, "run_tool incremented session tool_calls to 2");
    is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 1, "tool_counts for read_file unchanged at 1");
    is($CURRENT_SESSION->{stats}{tool_counts}{list_dir}, 1, "tool_counts for list_dir is 1");

    # Call run_tool with unknown tool
    my $res3 = run_tool('unknown_tool_xyz', {});
    like($res3, qr/Unknown tool/, "unknown tool returned error message");
    is($CURRENT_SESSION->{stats}{tool_calls}, 3, "run_tool incremented tool_calls even on unknown tool");
    is($CURRENT_SESSION->{stats}{tool_counts}{unknown_tool_xyz}, 1, "tool_counts tracks unknown tool call");
}

# 2. run_subagent records subagent execution, tool calls, and token usage into session
{
    $ENV{ANTHROPIC_API_KEY} = "sk-test-key";
    configure_provider('anthropic');
    init_session();
    is($CURRENT_SESSION->{stats}{subagents}, 0, "fresh session: subagents is 0");
    is($CURRENT_SESSION->{stats}{api_calls}, 0, "fresh session: api_calls is 0");
    is($CURRENT_SESSION->{stats}{total_tokens}, 0, "fresh session: total_tokens is 0");

    # Create temporary file for subagent to read
    my $tmp_file = "$root_dir/t_subagent_stats_test.txt";
    open my $tfh, '>', $tmp_file or die "Cannot create temp file: $!";
    print $tfh "Subagent stats test content\n";
    close $tfh;

    my $mock_calls = 0;
    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $mock_calls++;
        if ($mock_calls == 1) {
            # Turn 1: Subagent calls read_file
            return {
                usage => {
                    input_tokens  => 60,
                    output_tokens => 25,
                    total_tokens  => 85,
                },
                content => [
                    {
                        type  => 'tool_use',
                        id    => 'tool_sub_1',
                        name  => 'read_file',
                        input => { path => $tmp_file },
                    }
                ]
            };
        }
        else {
            # Turn 2: Subagent returns final summary
            return {
                usage => {
                    input_tokens  => 90,
                    output_tokens => 35,
                    total_tokens  => 125,
                },
                content => [
                    {
                        type => 'text',
                        text => 'Subagent finished analyzing the test file.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $sub_result = run_subagent("Analyze test file", "plan");
    unlink $tmp_file if -f $tmp_file;

    is($mock_calls, 2, "Subagent executed 2 turns via call_api");
    is($sub_result, "Subagent finished analyzing the test file.", "Subagent completed successfully");

    # Verify session stats aggregated subagent spawns
    is($CURRENT_SESSION->{stats}{subagents}, 1, "Subagent launch recorded in session stats");
    is($CURRENT_SESSION->{stats}{subagent_counts}{plan}, 1, "Subagent type breakdown recorded 'plan'");

    # Verify subagent tool call recorded in session
    is($CURRENT_SESSION->{stats}{tool_calls}, 1, "Subagent tool call recorded in session tool_calls");
    is($CURRENT_SESSION->{stats}{tool_counts}{read_file}, 1, "Subagent tool call recorded in tool_counts{read_file}");

    # Verify tokens from both subagent API turns accumulated in session stats
    is($CURRENT_SESSION->{stats}{api_calls}, 2, "Session api_calls accumulated 2 subagent calls");
    is($CURRENT_SESSION->{stats}{prompt_tokens}, 150, "Session prompt_tokens accumulated (60 + 90 = 150)");
    is($CURRENT_SESSION->{stats}{completion_tokens}, 60, "Session completion_tokens accumulated (25 + 35 = 60)");
    is($CURRENT_SESSION->{stats}{total_tokens}, 210, "Session total_tokens accumulated (85 + 125 = 210)");
}

# 3. Invoking subagent via run_tool('invoke_subagent') records both tool and subagent
{
    init_session();

    my $mock_calls = 0;
    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $mock_calls++;
        return {
            usageMetadata => {
                promptTokenCount     => 110,
                candidatesTokenCount => 40,
                totalTokenCount      => 150,
            },
            content => [
                {
                    type => 'text',
                    text => 'Task completed by build subagent.',
                }
            ]
        };
    };
    use warnings 'redefine';

    my $tool_sub_res = run_tool('invoke_subagent', { task => "Build something", subagent_type => "build" });
    is($tool_sub_res, "Task completed by build subagent.", "invoke_subagent returned summary");

    # Both invoke_subagent tool call and subagent launch are recorded
    is($CURRENT_SESSION->{stats}{tool_calls}, 1, "tool_calls recorded invoke_subagent invocation");
    is($CURRENT_SESSION->{stats}{tool_counts}{invoke_subagent}, 1, "tool_counts{invoke_subagent} is 1");
    is($CURRENT_SESSION->{stats}{subagents}, 1, "subagents recorded 1 launch");
    is($CURRENT_SESSION->{stats}{subagent_counts}{build}, 1, "subagent_counts{build} is 1");

    # Gemini tokens recorded into session
    is($CURRENT_SESSION->{stats}{api_calls}, 1, "Session api_calls incremented to 1");
    is($CURRENT_SESSION->{stats}{prompt_tokens}, 110, "Session prompt_tokens is 110");
    is($CURRENT_SESSION->{stats}{completion_tokens}, 40, "Session completion_tokens is 40");
    is($CURRENT_SESSION->{stats}{total_tokens}, 150, "Session total_tokens is 150");
}

# 4. Main turnaround loop records API response stats into the active session
{
    init_session();
    is($CURRENT_SESSION->{stats}{api_calls}, 0, "session api_calls starts at 0");

    my $mock_resp_1 = {
        usage => {
            input_tokens  => 100,
            output_tokens => 50,
            total_tokens  => 150,
        },
        content => [ { type => 'text', text => 'Main turn 1 answer' } ],
    };

    record_api_response_stats($mock_resp_1, $CURRENT_SESSION);
    is($CURRENT_SESSION->{stats}{api_calls}, 1, "first turn incremented api_calls");
    is($CURRENT_SESSION->{stats}{prompt_tokens}, 100, "first turn prompt_tokens");
    is($CURRENT_SESSION->{stats}{completion_tokens}, 50, "first turn completion_tokens");
    is($CURRENT_SESSION->{stats}{total_tokens}, 150, "first turn total_tokens");

    my $mock_resp_2 = {
        usage => {
            input_tokens  => 120,
            output_tokens => 60,
            total_tokens  => 180,
        },
        content => [ { type => 'text', text => 'Main turn 2 answer' } ],
    };

    record_api_response_stats($mock_resp_2, $CURRENT_SESSION);
    is($CURRENT_SESSION->{stats}{api_calls}, 2, "second turn incremented api_calls");
    is($CURRENT_SESSION->{stats}{prompt_tokens}, 220, "accumulated prompt_tokens");
    is($CURRENT_SESSION->{stats}{completion_tokens}, 110, "accumulated completion_tokens");
    is($CURRENT_SESSION->{stats}{total_tokens}, 330, "accumulated total_tokens");
}

# ==================================================================
# Task 4: Implement `/stats` Command & Terminal Formatting
# ==================================================================

# 1. _commify helper tests
{
    is(_commify(0), '0', '_commify: 0');
    is(_commify(42), '42', '_commify: 42');
    is(_commify(999), '999', '_commify: 999');
    is(_commify(1000), '1,000', '_commify: 1,000');
    is(_commify(1234567), '1,234,567', '_commify: 1,234,567');
    is(_commify(-12345), '-12,345', '_commify: -12,345');
    is(_commify(undef), '0', '_commify: undef returns 0');
    is(_commify(''), '0', '_commify: empty string returns 0');
}

# 2. format_uptime helper tests
{
    is(format_uptime(0), '0s', 'format_uptime: 0 seconds');
    is(format_uptime(45), '45s', 'format_uptime: 45 seconds');
    is(format_uptime(60), '1m 0s', 'format_uptime: 60 seconds');
    is(format_uptime(125), '2m 5s', 'format_uptime: 125 seconds');
    is(format_uptime(3600), '1h 0m 0s', 'format_uptime: 3600 seconds');
    is(format_uptime(3661), '1h 1m 1s', 'format_uptime: 3661 seconds');
    is(format_uptime(7325), '2h 2m 5s', 'format_uptime: 7325 seconds');
    is(format_uptime(-10), '0s', 'format_uptime: negative seconds handled safely');
}

# 3. get_context_window_size helper tests
{
    is(get_context_window_size('anthropic'), 204800, 'get_context_window_size: anthropic is 204,800 (200k)');
    is(get_context_window_size('gemini'), 1048576, 'get_context_window_size: gemini is 1,048,576 (1m)');
    is(get_context_window_size('openai'), 131072, 'get_context_window_size: openai is 131,072 (128k)');
}

# 4. format_session_stats on empty/default session
{
    our ($COLOR_HEADER, $COLOR_RESET);
    local $COLOR_HEADER = '';
    local $COLOR_RESET  = '';
    my $fresh_session = init_session();
    my $out = format_session_stats($fresh_session);
    ok(defined $out && length($out) > 0, 'format_session_stats returns non-empty string');
    like($out, qr/Session ID:\s+\Q$fresh_session->{id}\E/, 'includes session ID');
    like($out, qr/Provider \/ Model:\s+\w+ \/ [\w\.\-]+/, 'includes provider and model');
    like($out, qr/Uptime:\s+\d+[smh]/, 'includes uptime');
    like($out, qr/Active Messages:\s+0/, 'includes 0 active messages');
    like($out, qr/Active Characters:\s+0/, 'includes 0 active characters');
    like($out, qr/Estimated Tokens:\s+0/, 'includes 0 estimated tokens');
    like($out, qr/Context Window:\s+[\d,]+/, 'includes context window size');
    like($out, qr/0\.00%/, 'includes 0.00% context utilization');
    like($out, qr/Max Output Tokens:\s+[\d,]+/, 'includes max output tokens');
    like($out, qr/API Calls:\s+0/, 'includes 0 API calls');
    like($out, qr/Prompt Tokens:\s+0/, 'includes 0 prompt tokens');
    like($out, qr/Completion Tokens:\s+0/, 'includes 0 completion tokens');
    like($out, qr/Total Tokens:\s+0/, 'includes 0 total tokens');
    like($out, qr/Tool Calls:(?:\x1b\[[0-9;]*m|\s)+0(?:\s+\(none\))?/, 'includes 0 tool calls');
    like($out, qr/Sub-Agents:(?:\x1b\[[0-9;]*m|\s)+0(?:\s+\(none\))?/, 'includes 0 subagents');
}

# 5. format_session_stats on populated session with breakdowns
{
    our ($COLOR_HEADER, $COLOR_RESET);
    local $COLOR_HEADER = '';
    local $COLOR_RESET  = '';
    my $sess = init_session();
    $sess->{provider} = 'anthropic';
    $sess->{model} = 'claude-sonnet-4-5-20250929';
    $sess->{stats}{start_time} = time() - 3665; # 1h 1m 5s ago
    $sess->{stats}{api_calls} = 5;
    $sess->{stats}{prompt_tokens} = 12500;
    $sess->{stats}{completion_tokens} = 3400;
    $sess->{stats}{total_tokens} = 15900;
    $sess->{stats}{tool_calls} = 8;
    $sess->{stats}{tool_counts} = {
        'read_file'  => 5,
        'edit_file'  => 2,
        'list_dir'   => 1,
    };
    $sess->{stats}{subagents} = 3;
    $sess->{stats}{subagent_counts} = {
        'plan'  => 2,
        'build' => 1,
    };

    # Add messages with text content
    push @{$sess->{messages}}, { role => 'user', content => "Hello, world!" }; # 13 chars
    push @{$sess->{messages}}, { role => 'assistant', content => [
        { type => 'text', text => "Here is a response with some code." } # 34 chars -> total 47 chars
    ] };

    my $out = format_session_stats($sess);
    like($out, qr/Uptime:\s+1h 1m 5s/, 'uptime formatted as 1h 1m 5s');
    like($out, qr/Active Messages:\s+2/, 'active messages: 2');
    like($out, qr/Active Characters:\s+47/, 'active characters: 47');
    like($out, qr/Estimated Tokens:\s+11/, 'estimated tokens: 11 (~47/4)');
    like($out, qr/Context Window:\s+204,800\s+\(200k\)/, 'context window formatted with 200k');
    like($out, qr/utilization:\s+0\.01%/, 'utilization calculated (11/204800 = ~0.005% -> 0.01%)');
    like($out, qr/API Calls:\s+5/, 'API calls: 5');
    like($out, qr/Prompt Tokens:\s+12,500/, 'Prompt tokens commified');
    like($out, qr/Completion Tokens:\s+3,400/, 'Completion tokens commified');
    like($out, qr/Total Tokens:\s+15,900/, 'Total tokens commified');
    like($out, qr/Tool Calls:(?:\x1b\[[0-9;]*m|\s)+8/, 'Tool calls total: 8');
    like($out, qr/read_file:\s+5/, 'tool breakdown: read_file 5');
    like($out, qr/edit_file:\s+2/, 'tool breakdown: edit_file 2');
    like($out, qr/list_dir:\s+1/, 'tool breakdown: list_dir 1');
    like($out, qr/Sub-Agents:(?:\x1b\[[0-9;]*m|\s)+3/, 'Subagents total: 3');
    like($out, qr/plan:\s+2/, 'subagent breakdown: plan 2');
    like($out, qr/build:\s+1/, 'subagent breakdown: build 1');

    # Tool breakdown order: read_file (5) appears before list_dir (1)
    my $pos_read = index($out, 'read_file');
    my $pos_list = index($out, 'list_dir');
    ok($pos_read > 0 && $pos_list > $pos_read, 'tool breakdown is sorted by frequency descending');
}

# 6. format_session_stats defaults to $CURRENT_SESSION
{
    init_session();
    $CURRENT_SESSION->{stats}{prompt_tokens} = 777;
    my $out_def = format_session_stats();
    like($out_def, qr/Prompt Tokens:\s+777/, 'format_session_stats() defaults to $CURRENT_SESSION');
}

# 6b. Section headers consistency with ANSI formatting
{
    init_session();
    our ($COLOR_HEADER, $COLOR_RESET);
    local $COLOR_HEADER = "\x1b[1;35m";
    local $COLOR_RESET  = "\x1b[0m";

    my $colored_out = format_session_stats();
    my $exp_stats = "$COLOR_HEADER" . "Session Statistics:" . "$COLOR_RESET";
    my $exp_ctx   = "$COLOR_HEADER" . "Active Context:" . "$COLOR_RESET";
    my $exp_usage = "$COLOR_HEADER" . "Cumulative Token Usage:" . "$COLOR_RESET";
    my $exp_tools = "$COLOR_HEADER" . "Tool Calls:" . "$COLOR_RESET";
    my $exp_sub   = "$COLOR_HEADER" . "Sub-Agents:" . "$COLOR_RESET";

    like($colored_out, qr/\Q$exp_stats\E/, 'header: Session Statistics formatted with $c_hdr');
    like($colored_out, qr/\Q$exp_ctx\E/, 'header: Active Context formatted with $c_hdr');
    like($colored_out, qr/\Q$exp_usage\E/, 'header: Cumulative Token Usage formatted with $c_hdr');
    like($colored_out, qr/\Q$exp_tools\E/, 'header: Tool Calls formatted with $c_hdr');
    like($colored_out, qr/\Q$exp_sub\E/, 'header: Sub-Agents formatted with $c_hdr');
}

# 7. handle_stats_command prints to filehandle and returns 1
{
    my $sess = init_session();
    $sess->{stats}{prompt_tokens} = 999;
    my $printed = '';
    open my $fh, '>', \$printed or die "Cannot open scalar fh: $!";
    my $ret = handle_stats_command($fh, $sess);
    close $fh;

    is($ret, 1, 'handle_stats_command returns 1 on success');
    like($printed, qr/Prompt Tokens:\s+999/, 'handle_stats_command printed stats to handle');
}

# 8. show_help contains /stats command
{
    my $help_out = '';
    open my $hfh, '>', \$help_out or die "Cannot open scalar fh: $!";
    show_help($hfh);
    close $hfh;

    like($help_out, qr{/stats\s+-\s+Show current session statistics and token usage},
        'show_help includes /stats with correct description');
}

# 9. Slash command dispatcher regex in main.pl matches /stats
{
    my $regex = qr{^/stats\b}i;
    ok('/stats' =~ $regex, '/stats matches command regex');
    ok('/STATS' =~ $regex, '/STATS matches case-insensitively');
    ok('/stats verbose' =~ $regex, '/stats with trailing args matches');
    ok('/status' !~ $regex, '/status does NOT match /stats');
    ok('hello /stats' !~ $regex, 'non-leading /stats does NOT match');
}

done_testing();

