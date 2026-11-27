#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";
delete $ENV{CLAUDE_AUTO_MODE};

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our (@TOOLS, $AUTO_MODE, $CURRENT_SUBAGENT_TYPE, $COLOR_SUBAGENT, $COLOR_RESET, $COLOR_DIM);

# ==================================================================
# 1. Tool schema in @TOOLS
# ==================================================================
my ($sub_tool) = grep { $_->{name} eq 'invoke_subagent' } @TOOLS;
ok($sub_tool, "invoke_subagent exists in \@TOOLS");
is_deeply($sub_tool->{input_schema}{required}, ['task'], "invoke_subagent requires 'task'");
ok($sub_tool->{input_schema}{properties}{task}, "has 'task' property");
is($sub_tool->{input_schema}{properties}{task}{type}, 'string', "'task' is string");
ok($sub_tool->{input_schema}{properties}{subagent_type}, "has 'subagent_type' property");

# ==================================================================
# 2. Subagent Tool Permissions (plan vs build)
# ==================================================================
my $plan_tools = get_subagent_tools('plan');
my @plan_names = sort map { $_->{name} } @$plan_tools;
is_deeply(\@plan_names, ['list_dir', 'read_file'], "plan sub-agent has strictly read-only tools");

my $build_tools = get_subagent_tools('build');
my @build_names = sort map { $_->{name} } @$build_tools;
is_deeply(\@build_names, ['edit_file', 'list_dir', 'read_file', 'run_shell', 'write_file'],
    "build sub-agent has full editing and shell tools but NOT invoke_subagent");

my $default_tools = get_subagent_tools();
my @default_names = sort map { $_->{name} } @$default_tools;
is_deeply(\@default_names, \@build_names, "default subagent tools match build tools");

# Verify invoke_subagent is NOT in either toolset (prevents recursion)
ok(!grep({ $_->{name} eq 'invoke_subagent' } @$plan_tools), "invoke_subagent excluded from plan tools");
ok(!grep({ $_->{name} eq 'invoke_subagent' } @$build_tools), "invoke_subagent excluded from build tools");

# ==================================================================
# 3. UI Formatting Helpers
# ==================================================================
# format_tool_summary for invoke_subagent
my $summary_plan = format_tool_summary('invoke_subagent', { task => 'Analyze tests', subagent_type => 'plan' });
like($summary_plan, qr/invoke_subagent\s+\[plan\]\s+Analyze tests/, "format_tool_summary formats plan subagent");

my $summary_build = format_tool_summary('invoke_subagent', { task => 'Fix formatting in README.md' });
like($summary_build, qr/invoke_subagent\s+\[build\]\s+Fix formatting/, "format_tool_summary defaults to [build]");

# format_subagent_start / finish / tool_call
{
    local $COLOR_SUBAGENT = '';
    local $COLOR_DIM = '';
    local $COLOR_RESET = '';
    my $tree_start = format_subagent_start('plan', 'Inspect structure');
    like($tree_start, qr/┌── \[Sub-agent: plan\]/, "format_subagent_start includes tree header");
    like($tree_start, qr/Inspect structure/, "format_subagent_start includes task text");

    my $tree_call = format_subagent_tool_call('plan', 1, 50, 'read_file', { path => 'foo.txt' });
    like($tree_call, qr/│.*\[Turn 1\/50\]\s+read_file\s+foo\.txt/, "format_subagent_tool_call formats turn and tool");

    my $tree_finish = format_subagent_finish('plan', 3, 'Completed');
    like($tree_finish, qr/└── \[Sub-agent: plan\]\s+Completed in 3 turn\(s\)/, "format_subagent_finish includes turn count");
}

# ==================================================================
# 4. Confirmation Tagging under Sub-Agents
# ==================================================================
{
    my $captured_prompt = '';
    no warnings 'once';
    no warnings 'redefine';
    local *confirm = sub {
        ($captured_prompt) = @_;
        return 1;
    };
    use warnings 'redefine';
    use warnings 'once';

    $AUTO_MODE = 0;

    # Normal mode (no subagent)
    $CURRENT_SUBAGENT_TYPE = undef;
    confirm_tool("Delete database?");
    is($captured_prompt, "Delete database?", "Normal confirm_tool has no subagent prefix");

    # Under build subagent
    $CURRENT_SUBAGENT_TYPE = 'build';
    confirm_tool("Run command: rm -rf tmp");
    is($captured_prompt, "[Sub-agent: build] Run command: rm -rf tmp", "Subagent confirm_tool includes prefix");

    # Under auto mode
    $AUTO_MODE = 1;
    $captured_prompt = '';
    my $res = confirm_tool("Should not ask");
    is($res, 1, "confirm_tool returns 1 in auto mode");
    is($captured_prompt, '', "confirm was not invoked in auto mode");
    $AUTO_MODE = 0;
    $CURRENT_SUBAGENT_TYPE = undef;
}

# ==================================================================
# 5. run_tool invoke_subagent validations
# ==================================================================
my $err_no_task = run_tool('invoke_subagent', {});
like($err_no_task, qr/missing required 'task'/i, "Missing task returns clean error message");

# ==================================================================
# 6. Synchronous run_subagent execution with mock responses
# ==================================================================
$ENV{ANTHROPIC_API_KEY} = "sk-test-key";
configure_provider('anthropic');

my $temp_dir = tempdir(CLEANUP => 1);
my $test_file = "$temp_dir/sample.txt";
open my $tf, '>', $test_file or die $!;
print $tf "Hello PowerPC Subagent!\nLine 2\n";
close $tf;

# Test Case 6a: Direct answer (1 turn, no tool calls)
{
    $ENV{MOCK_CURL_RESPONSE} = '{"content":[{"type":"text","text":"Plan completed: everything looks solid."}]}';
    my $out = run_subagent("Analyze files", "plan");
    is($out, "Plan completed: everything looks solid.", "Direct response returned from subagent in 1 turn");
}

# Test Case 6b: Multi-turn tool execution with turn countdown in context
{
    # First turn: subagent calls read_file
    # Second turn: subagent outputs final text
    my $turn_count = 0;
    my $captured_countdown = '';

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            return {
                content => [
                    {
                        type  => 'tool_use',
                        id    => 'toolu_1',
                        name  => 'read_file',
                        input => { path => $test_file },
                    }
                ]
            };
        }
        else {
            # In turn 2, inspect the payload to verify countdown note was injected in user message!
            if ($payload_json =~ /(\[Turn 1 of 50\. Turns remaining: 49\])/) {
                $captured_countdown = $1;
            }
            return {
                content => [
                    {
                        type => 'text',
                        text => 'File contents reviewed successfully.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Read the sample file", "plan");
    is($turn_count, 2, "Subagent ran 2 turns to execute tool and summarize");
    is($out, "File contents reviewed successfully.", "Subagent final text returned");
    is($captured_countdown, "[Turn 1 of 50. Turns remaining: 49]", "Turn countdown correctly injected into context");
}

# Test Case 6c: Plan subagent attempts mutating tool (write_file) -> blocked
{
    my $turn_count = 0;
    my $tool_result_content = '';

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            return {
                content => [
                    {
                        type  => 'tool_use',
                        id    => 'toolu_2',
                        name  => 'write_file',
                        input => { path => 'fake.txt', content => 'bad' },
                    }
                ]
            };
        }
        else {
            if ($payload_json =~ /(Error: tool 'write_file' is not permitted for 'plan' sub-agent)/) {
                $tool_result_content = $1;
            }
            return {
                content => [
                    {
                        type => 'text',
                        text => 'Acknowledged write error.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Try to write", "plan");
    like($tool_result_content, qr/not permitted for 'plan' sub-agent/, "Plan subagent prevented from mutating filesystem");
}

# Test Case 6d: Subagent attempting invoke_subagent -> blocked
{
    my $turn_count = 0;
    my $tool_result_content = '';

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            return {
                content => [
                    {
                        type  => 'tool_use',
                        id    => 'toolu_3',
                        name  => 'invoke_subagent',
                        input => { task => 'nested subagent' },
                    }
                ]
            };
        }
        else {
            if ($payload_json =~ /(Error: sub-agents cannot invoke sub-agents)/) {
                $tool_result_content = $1;
            }
            return {
                content => [
                    {
                        type => 'text',
                        text => 'Acknowledged recursion error.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Try to nest", "build");
    like($tool_result_content, qr/sub-agents cannot invoke sub-agents/, "Subagents prevented from recursive self-invocation");
}

# Test Case 6e: Turn limit guard (50 turns max)
{
    my $turns_executed = 0;

    no warnings 'redefine';
    local *call_api = sub {
        $turns_executed++;
        return {
            content => [
                {
                    type  => 'tool_use',
                    id    => 'toolu_loop_' . $turns_executed,
                    name  => 'list_dir',
                    input => { path => '.' },
                }
            ]
        };
    };
    use warnings 'redefine';

    my $out = run_subagent("Infinite loop task", "plan");
    is($turns_executed, 50, "Subagent stopped exactly at 50 turns");
    like($out, qr/reached maximum turn limit \(50\)/, "Timeout message returned when max turns reached");
}

# Test Case 6f: Subagent completes without returning text summary
{
    $ENV{MOCK_CURL_RESPONSE} = '{"content":[{"type":"text","text":""}]}';
    my $out = run_subagent("Empty summary task", "plan");
    is($out, "(Sub-agent completed without returning text summary)",
        "Explicit notice returned when subagent completes with empty text summary");

    $ENV{MOCK_CURL_RESPONSE} = '{"content":[{"type":"text","text":"   \n\t  "}]}';
    my $out_ws = run_subagent("Whitespace summary task", "plan");
    is($out_ws, "(Sub-agent completed without returning text summary)",
        "Explicit notice returned when subagent completes with whitespace-only text summary");
}

# ==================================================================
# 7. Prompt guidelines for build sub-agent
# ==================================================================
{
    our ($SUBAGENT_BUILD_PROMPT, $SUBAGENT_PLAN_PROMPT, $SYSTEM_PROMPT);
    ok(defined $SUBAGENT_BUILD_PROMPT, "SUBAGENT_BUILD_PROMPT is defined");
    like($SUBAGENT_BUILD_PROMPT, qr/chain.*run_shell/i, "SUBAGENT_BUILD_PROMPT instructs command chaining");
    like($SUBAGENT_BUILD_PROMPT, qr/<turn_economy>.*<\/turn_economy>/s, "SUBAGENT_BUILD_PROMPT includes <turn_economy> section");
    like($SUBAGENT_BUILD_PROMPT, qr/<file_editing>.*<\/file_editing>/s, "SUBAGENT_BUILD_PROMPT includes shared <file_editing> section");
    like($SUBAGENT_BUILD_PROMPT, qr/<tool_boundaries>.*<\/tool_boundaries>/s, "SUBAGENT_BUILD_PROMPT includes <tool_boundaries> section");
    like($SUBAGENT_BUILD_PROMPT, qr/<tiger_env>.*<\/tiger_env>/s, "SUBAGENT_BUILD_PROMPT includes shared <tiger_env> section");
    like($SUBAGENT_PLAN_PROMPT, qr/<turn_economy>.*<\/turn_economy>/s, "SUBAGENT_PLAN_PROMPT includes <turn_economy> section");
    like($SUBAGENT_PLAN_PROMPT, qr/<tool_boundaries>.*<\/tool_boundaries>/s, "SUBAGENT_PLAN_PROMPT includes <tool_boundaries> section");
    like($SYSTEM_PROMPT, qr/<tool_boundaries>.*<\/tool_boundaries>/s, "SYSTEM_PROMPT includes <tool_boundaries> section");
}

# ==================================================================
# 8. MCP Tools in Sub-Agents (plan excludes, build includes)
# ==================================================================
{
    my $mcp_tool_def = {
        name         => 'mcp__git__status',
        description  => 'Show git status via MCP',
        server       => 'git',
        input_schema => { type => 'object', properties => {} },
    };
    push @TOOLS, $mcp_tool_def;

    my $plan_tools_with_mcp = get_subagent_tools('plan');
    my @plan_tool_names = sort map { $_->{name} } @$plan_tools_with_mcp;
    is_deeply(\@plan_tool_names, ['list_dir', 'read_file'],
        "plan sub-agent strictly excludes remote MCP tools");

    my $build_tools_with_mcp = get_subagent_tools('build');
    my @build_tool_names = sort map { $_->{name} } @$build_tools_with_mcp;
    ok(grep({ $_ eq 'mcp__git__status' } @build_tool_names),
        "build sub-agent includes registered remote MCP tools");
    ok(!grep({ $_ eq 'invoke_subagent' } @build_tool_names),
        "build sub-agent still excludes invoke_subagent");

    # Subagent confirmation with MCP tool
    my $captured_prompt = '';
    no warnings 'once', 'redefine';
    local *confirm = sub {
        ($captured_prompt) = @_;
        return 1;
    };
    use warnings 'once', 'redefine';

    $AUTO_MODE = 0;
    $CURRENT_SUBAGENT_TYPE = 'build';
    confirm_tool("Call remote MCP tool 'mcp__git__status'?");
    is($captured_prompt, "[Sub-agent: build] Call remote MCP tool 'mcp__git__status'?",
        "Subagent confirmation prefix correctly applied to MCP tool confirmation");
    $CURRENT_SUBAGENT_TYPE = undef;

    # Clean up test tool from @TOOLS
    @TOOLS = grep { $_->{name} ne 'mcp__git__status' } @TOOLS;
}

# ==================================================================
# 9. Truncated Response & Thinking-Only Turn Auto-Continuation
# ==================================================================
# 9a. Thinking-only turn followed by tool call and final summary
{
    my $turn_count = 0;
    my $second_turn_payload = '';

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            return {
                content => [
                    {
                        type      => 'thinking',
                        text      => 'Let me think carefully about the plan...',
                        signature => 'sig_1',
                    }
                ]
            };
        }
        elsif ($turn_count == 2) {
            $second_turn_payload = $payload_json;
            return {
                content => [
                    {
                        type => 'text',
                        text => 'Finished thinking: here is the final summary.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Reasoning task", "plan");
    is($turn_count, 2, "Subagent continued automatically after thinking-only turn");
    is($out, "Finished thinking: here is the final summary.", "Subagent returned final summary from continuation turn");
    like($second_turn_payload, qr/continue/i, "Continuation user prompt sent on turn 2");
    like($second_turn_payload, qr/\[Turn 1 of 50\. Turns remaining: 49\]/, "Continuation user prompt includes turn countdown note");
}

# 9b. Truncated response (stop_reason => 'max_tokens') with partial text accumulated across turns
{
    my $turn_count = 0;

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            return {
                stop_reason => 'max_tokens',
                content     => [
                    {
                        type => 'text',
                        text => 'Part 1 of summary. ',
                    }
                ]
            };
        }
        else {
            return {
                stop_reason => 'end_turn',
                content     => [
                    {
                        type => 'text',
                        text => 'Part 2 of summary.',
                    }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Long summary task", "plan");
    is($turn_count, 2, "Subagent continued automatically after truncated max_tokens response");
    is($out, "Part 1 of summary. Part 2 of summary.", "Partial text across truncated continuation turns is accumulated cleanly");
}

# 9c. Continuation cap ($max_continuations = 3) prevents infinite loops on repeated thinking-only turns
{
    my $turn_count = 0;

    no warnings 'redefine';
    local *call_api = sub {
        $turn_count++;
        return {
            content => [
                {
                    type      => 'thinking',
                    text      => "Still thinking on turn $turn_count...",
                    signature => "sig_$turn_count",
                }
            ]
        };
    };
    use warnings 'redefine';

    my $out = run_subagent("Stuck thinking task", "plan");
    is($turn_count, 4, "Subagent stops after 1 initial turn + 3 consecutive continuations (4 turns total)");
    is($out, "(Sub-agent completed without returning text summary)", "Clean fallback summary returned when continuation cap is reached with no text");
}

# 9d. Continuation counter resets when a tool call is executed
{
    my $turn_count = 0;

    no warnings 'redefine';
    local *call_api = sub {
        $turn_count++;
        if ($turn_count == 1 || $turn_count == 2) {
            # 2 consecutive thinking-only turns
            return {
                content => [
                    { type => 'thinking', text => "Thinking $turn_count", signature => "s$turn_count" }
                ]
            };
        }
        elsif ($turn_count == 3) {
            # Tool call resets consecutive continuation counter!
            return {
                content => [
                    { type => 'tool_use', id => 'toolu_reset', name => 'list_dir', input => { path => '.' } }
                ]
            };
        }
        elsif ($turn_count == 4 || $turn_count == 5) {
            # Another 2 consecutive thinking-only turns (would exceed 3 if not reset)
            return {
                content => [
                    { type => 'thinking', text => "Thinking $turn_count", signature => "s$turn_count" }
                ]
            };
        }
        else {
            return {
                content => [
                    { type => 'text', text => 'Completed after reset.' }
                ]
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Reset continuation counter task", "plan");
    is($turn_count, 6, "Subagent allowed full continuation budget again after tool call turn");
    is($out, "Completed after reset.", "Subagent completed normally after reset");
}

# 9e. is_response_truncated unit tests across OpenAI, Anthropic, and Gemini
{
    is(is_response_truncated({ choices => [ { finish_reason => 'length' } ] }, 'openai'), 1,
        "is_response_truncated: OpenAI finish_reason => 'length' returns 1");
    is(is_response_truncated({ choices => [ { finish_reason => 'max_tokens' } ] }, 'openai'), 1,
        "is_response_truncated: OpenAI finish_reason => 'max_tokens' returns 1");
    is(is_response_truncated({ choices => [ { finish_reason => 'stop' } ] }, 'openai'), 0,
        "is_response_truncated: OpenAI finish_reason => 'stop' returns 0");

    is(is_response_truncated({ stop_reason => 'max_tokens' }, 'anthropic'), 1,
        "is_response_truncated: Anthropic stop_reason => 'max_tokens' returns 1");
    is(is_response_truncated({ stop_reason => 'end_turn' }, 'anthropic'), 0,
        "is_response_truncated: Anthropic stop_reason => 'end_turn' returns 0");

    is(is_response_truncated({ candidates => [ { finishReason => 'MAX_TOKENS' } ] }, 'gemini'), 1,
        "is_response_truncated: Gemini finishReason => 'MAX_TOKENS' returns 1");
    is(is_response_truncated({ candidates => [ { finishReason => 'STOP' } ] }, 'gemini'), 0,
        "is_response_truncated: Gemini finishReason => 'STOP' returns 0");
    is(is_response_truncated(undef, 'openai'), 0,
        "is_response_truncated: undef response returns 0");
}

# 9f. OpenAI sub-agent recovery from truncated tool call JSON and finish_reason => 'length' continuation
{
    local $ENV{OPENAI_BASE_URL} = 'http://localhost:11434/v1';
    local $ENV{OPENAI_API_KEY}  = 'test-openai-key';
    configure_provider('openai');
    set_auto_mode(1);

    my $recovered_file = "$temp_dir/openai_recovered.txt";
    my $turn_count = 0;
    my $turn2_payload = '';
    my $turn3_payload = '';

    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $headers, $payload_json) = @_;
        $turn_count++;
        if ($turn_count == 1) {
            # Turn 1: OpenAI reasoning model hits max_tokens while emitting write_file arguments
            return {
                choices => [
                    {
                        finish_reason => 'length',
                        message       => {
                            reasoning_content => 'Drafting long file content...',
                            tool_calls        => [
                                {
                                    id       => 'call_trunc_sub_1',
                                    type     => 'function',
                                    function => {
                                        name      => 'write_file',
                                        arguments => '{"path":"' . $recovered_file . '","content":"truncated',
                                    },
                                },
                            ],
                        },
                    },
                ],
            };
        }
        elsif ($turn_count == 2) {
            # Turn 2: Model receives _arg_parse_error tool result, retries with valid JSON using aliases
            $turn2_payload = $payload_json;
            return {
                choices => [
                    {
                        finish_reason => 'tool_calls',
                        message       => {
                            tool_calls => [
                                {
                                    id       => 'call_valid_sub_2',
                                    type     => 'function',
                                    function => {
                                        name      => 'write_file',
                                        arguments => MiniJSON::encode({
                                            file_path => $recovered_file,
                                            text      => "Recovered content!\n",
                                        }),
                                    },
                                },
                            ],
                        },
                    },
                ],
            };
        }
        elsif ($turn_count == 3) {
            # Turn 3: Model starts emitting final summary but hits finish_reason => 'length'
            $turn3_payload = $payload_json;
            return {
                choices => [
                    {
                        finish_reason => 'length',
                        message       => {
                            content => 'File written successfully. ',
                        },
                    },
                ],
            };
        }
        else {
            # Turn 4: Model finishes summary after continuation prompt
            return {
                choices => [
                    {
                        finish_reason => 'stop',
                        message       => {
                            content => 'All steps complete.',
                        },
                    },
                ],
            };
        }
    };
    use warnings 'redefine';

    my $out = run_subagent("Write file and summarize under OpenAI", "build");
    is($turn_count, 4, "OpenAI sub-agent executed 4 turns (truncated tool call -> valid retry -> truncated summary -> final summary)");
    like($turn2_payload, qr/truncated or invalid JSON/, "Turn 2 payload delivered _arg_parse_error message to OpenAI model");
    like($turn3_payload, qr/Write complete:/, "Turn 3 payload confirmed successful retry write");
    ok(-f $recovered_file, "Recovered file was created on turn 2");
    is($out, "File written successfully. All steps complete.", "OpenAI truncated summary turns were continued and concatenated");

    configure_provider('anthropic');
}

done_testing();
