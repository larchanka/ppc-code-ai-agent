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

our ($COLOR_DIM, $COLOR_RESET);

# ==================================================================
# 1. Thinking block parsing across Anthropic, Gemini, and OpenAI
# ==================================================================

# Anthropic with thinking
{
    my $resp = {
        id      => 'msg_anthropic_think',
        type    => 'message',
        role    => 'assistant',
        content => [
            { type => 'thinking', thinking => 'Anthropic deep thoughts', signature => 'sig123' },
            { type => 'text',     text => 'Anthropic final answer' },
        ],
    };
    my @blocks = parse_response_anthropic($resp);
    is(scalar(@blocks), 2, 'Anthropic: parsed 2 blocks');
    is($blocks[0]{type}, 'thinking', 'Anthropic: block 0 is thinking');
    is($blocks[1]{type}, 'text', 'Anthropic: block 1 is text');
    ok(has_thinking_block(\@blocks), 'Anthropic: has_thinking_block detects thinking');
}

# Anthropic without thinking
{
    my $resp = {
        id      => 'msg_anthropic_direct',
        type    => 'message',
        role    => 'assistant',
        content => [
            { type => 'text', text => 'Anthropic direct answer' },
        ],
    };
    my @blocks = parse_response_anthropic($resp);
    is(scalar(@blocks), 1, 'Anthropic direct: parsed 1 block');
    is($blocks[0]{type}, 'text', 'Anthropic direct: block 0 is text');
    ok(!has_thinking_block(\@blocks), 'Anthropic direct: has_thinking_block returns false');
}

# Gemini with thinking (thought => 1)
{
    my $resp = {
        candidates => [
            {
                content => {
                    parts => [
                        { thought => 1, text => 'Gemini thought process', thoughtSignature => 'tsig456' },
                        { text => 'Gemini final answer' },
                    ],
                },
            },
        ],
    };
    my @blocks = parse_response_gemini($resp);
    is(scalar(@blocks), 2, 'Gemini: parsed 2 blocks');
    is($blocks[0]{type}, 'thinking', 'Gemini: block 0 is thinking');
    is($blocks[0]{text}, 'Gemini thought process', 'Gemini: block 0 has correct text');
    is($blocks[0]{thought_signature}, 'tsig456', 'Gemini: block 0 preserves thought_signature');
    is($blocks[1]{type}, 'text', 'Gemini: block 1 is text');
    is($blocks[1]{text}, 'Gemini final answer', 'Gemini: block 1 has correct text');
    ok(has_thinking_block(\@blocks), 'Gemini: has_thinking_block detects thinking');
}

# Gemini without thinking
{
    my $resp = {
        candidates => [
            {
                content => {
                    parts => [
                        { text => 'Gemini direct answer' },
                    ],
                },
            },
        ],
    };
    my @blocks = parse_response_gemini($resp);
    is(scalar(@blocks), 1, 'Gemini direct: parsed 1 block');
    is($blocks[0]{type}, 'text', 'Gemini direct: block 0 is text');
    ok(!has_thinking_block(\@blocks), 'Gemini direct: has_thinking_block returns false');
}

# OpenAI with reasoning_content
{
    my $resp = {
        choices => [
            {
                message => {
                    role              => 'assistant',
                    reasoning_content => 'OpenAI chain of thought',
                    content           => 'OpenAI final answer',
                },
            },
        ],
    };
    my @blocks = parse_response_openai($resp);
    is(scalar(@blocks), 2, 'OpenAI: parsed 2 blocks');
    is($blocks[0]{type}, 'thinking', 'OpenAI: block 0 is thinking');
    is($blocks[0]{text}, 'OpenAI chain of thought', 'OpenAI: block 0 has reasoning text');
    is($blocks[1]{type}, 'text', 'OpenAI: block 1 is text');
    is($blocks[1]{text}, 'OpenAI final answer', 'OpenAI: block 1 has content');
    ok(has_thinking_block(\@blocks), 'OpenAI: has_thinking_block detects thinking');
}

# OpenAI without reasoning_content
{
    my $resp = {
        choices => [
            {
                message => {
                    role    => 'assistant',
                    content => 'OpenAI direct answer',
                },
            },
        ],
    };
    my @blocks = parse_response_openai($resp);
    is(scalar(@blocks), 1, 'OpenAI direct: parsed 1 block');
    is($blocks[0]{type}, 'text', 'OpenAI direct: block 0 is text');
    ok(!has_thinking_block(\@blocks), 'OpenAI direct: has_thinking_block returns false');
}

# ==================================================================
# 2. Thinking line formatting and ANSI dimming / no-color toggles
# ==================================================================
{
    # Save original color state
    local $COLOR_DIM   = "\x1b[2m";
    local $COLOR_RESET = "\x1b[0m";

    is(format_thinking_status(1), "\x1b[2m* Thinking 1s...\x1b[0m", 'format_thinking_status: 1s with color');
    is(format_thinking_status(5), "\x1b[2m* Thinking 5s...\x1b[0m", 'format_thinking_status: 5s with color');
    is(format_thinking_status(0), "\x1b[2m* Thinking 1s...\x1b[0m", 'format_thinking_status: 0s clamped to 1s with color');
    is(format_thinking_status(undef), "\x1b[2m* Thinking 1s...\x1b[0m", 'format_thinking_status: undef clamped to 1s with color');

    # No color mode
    $COLOR_DIM   = '';
    $COLOR_RESET = '';

    is(format_thinking_status(1), "* Thinking 1s...", 'format_thinking_status: 1s without color');
    is(format_thinking_status(12), "* Thinking 12s...", 'format_thinking_status: 12s without color');
    is(format_thinking_status(0), "* Thinking 1s...", 'format_thinking_status: 0s clamped to 1s without color');
}

# ==================================================================
# 3. Timer finalization vs line clearing behavior
# ==================================================================
{
    # Finalize with color
    {
        local $COLOR_DIM   = "\x1b[2m";
        local $COLOR_RESET = "\x1b[0m";

        is(finalize_thinking_line(3), "\r\x1b[2m* Thinking 3s...\x1b[0m\n", 'finalize_thinking_line: with color ends with newline and starts with CR');
    }

    # Finalize without color
    {
        local $COLOR_DIM   = '';
        local $COLOR_RESET = '';

        is(finalize_thinking_line(7), "\r* Thinking 7s...\n", 'finalize_thinking_line: without color');
    }

    # Clear line completely
    {
        my $clear = clear_thinking_line();
        is($clear, "\r\033[K", 'clear_thinking_line returns \r\033[K');
    }

    # Finalize vs Clear decision logic
    {
        my @blocks_with_thinking = ({ type => 'thinking', text => 'hmmm' }, { type => 'text', text => 'ok' });
        my @blocks_direct        = ({ type => 'text', text => 'ok' });

        my $out_thinking = has_thinking_block(\@blocks_with_thinking)
            ? finalize_thinking_line(4)
            : clear_thinking_line();
        like($out_thinking, qr/\* Thinking 4s\.\.\./, 'Finalize chosen when thinking block present');
        like($out_thinking, qr/\n$/, 'Finalize ends with newline');

        my $out_direct = has_thinking_block(\@blocks_direct)
            ? finalize_thinking_line(4)
            : clear_thinking_line();
        is($out_direct, "\r\033[K", 'Clear line chosen when no thinking block present');
    }
}

# ==================================================================
# 4. Live fork execution in call_api with CLAUDE_TEST_TTY=1
# ==================================================================
{
    local $ENV{CLAUDE_TEST_TTY} = 1;
    $ENV{MOCK_CURL_RESPONSE} = '{"id":"msg_live","type":"message","content":[{"type":"text","text":"live test"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    our $LAST_API_ELAPSED = 0;
    my $resp = call_api("http://localhost:8080/v1/chat", ["custom-header: live"], '{"prompt":"hello"}');
    print "\n";

    is_deeply($resp, {
        id      => "msg_live",
        type    => "message",
        content => [{ type => "text", text => "live test" }],
    }, "call_api with live timer via fork returns decoded JSON");

    cmp_ok($LAST_API_ELAPSED, '>=', 1, "LAST_API_ELAPSED recorded and >= 1");
    ok(!-e "/tmp/code-agent-status-$$.txt", "Temporary status file cleaned up");
}

# ==================================================================
# 5. Gate live timer to requests with body (GET bypasses timer)
# ==================================================================
{
    local $ENV{CLAUDE_TEST_TTY} = 1;
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"claude-3-5-sonnet"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # GET request with no body
    my $resp = call_api("http://localhost:8080/v1/models", [], undef, 'GET');

    is_deeply($resp, { data => [{ id => "claude-3-5-sonnet" }] }, "GET request returns decoded JSON");
    ok(!-e "/tmp/code-agent-status-$$.txt", "GET request does not use status file (synchronous)");
}

# ==================================================================
# 6. Sanitize cross-provider thinking blocks for Anthropic
# ==================================================================
{
    my $messages = [
        {
            role    => 'user',
            content => 'Solve this math problem',
        },
        {
            role    => 'assistant',
            content => [
                # Signed Anthropic thinking block: should be retained
                { type => 'thinking', thinking => 'valid thoughts', signature => 'valid_sig_123' },
                # Unsigned Gemini/OpenAI thinking block: should be filtered out
                { type => 'thinking', text => 'unsigned thoughts from Gemini' },
                # Empty signature thinking block: should be filtered out
                { type => 'thinking', text => 'empty sig', signature => '' },
                # Regular text block: should be retained
                { type => 'text', text => 'Here is the answer: 42' },
            ],
        },
    ];

    my $req = build_request_anthropic($messages, [], 'system prompt');
    my $assistant_msg = $req->{messages}[1];
    is(ref($assistant_msg->{content}), 'ARRAY', 'assistant content is arrayref');
    is(scalar(@{ $assistant_msg->{content} }), 2, 'Filtered out 2 unsigned thinking blocks, keeping 2 blocks');
    is($assistant_msg->{content}[0]{type}, 'thinking', 'Block 0 is signed thinking block');
    is($assistant_msg->{content}[0]{signature}, 'valid_sig_123', 'Block 0 has valid signature');
    is($assistant_msg->{content}[1]{type}, 'text', 'Block 1 is text block');
}

# ==================================================================
# 7. Cursor visibility control (hide while working, show for user)
# ==================================================================
{
    local $ENV{CLAUDE_TEST_TTY} = 1;

    # Capture output of cursor_hide
    my $out_hide = '';
    {
        open my $fh, '>', \$out_hide;
        my $old = select($fh);
        cursor_hide();
        select($old);
        close $fh;
    }
    is($out_hide, "\x1b[?25l", "cursor_hide emits ESC[?25l on TTY");

    # Capture output of cursor_show
    my $out_show = '';
    {
        open my $fh, '>', \$out_show;
        my $old = select($fh);
        cursor_show();
        select($old);
        close $fh;
    }
    is($out_show, "\x1b[?25h", "cursor_show emits ESC[?25h on TTY");

    # When not TTY, no escape sequence emitted
    local $ENV{CLAUDE_TEST_TTY} = 0;
    my $out_nontty = '';
    {
        open my $fh, '>', \$out_nontty;
        my $old = select($fh);
        cursor_hide();
        cursor_show();
        select($old);
        close $fh;
    }
    is($out_nontty, "", "cursor_hide/show emits nothing when not a TTY");
}

# Gemini with fragmented text parts (split across parts)
{
    my $resp = {
        candidates => [
            {
                content => {
                    parts => [
                        { text => 'Employs patched Firefox and Web' },
                        { text => 'Kit builds alongside standard Chromium.' },
                    ],
                },
            },
        ],
    };
    local $ENV{GEMINI_API_KEY} = 'test-gem-key';
    configure_provider('gemini');
    my @blocks = parse_response($resp);
    is(scalar(@blocks), 1, 'Gemini fragmented text: merged into 1 block');
    is($blocks[0]{type}, 'text', 'Gemini fragmented text: type is text');
    is($blocks[0]{text}, 'Employs patched Firefox and WebKit builds alongside standard Chromium.',
       'Gemini fragmented text: text correctly joined');
}

# Gemini with fragmented thinking parts
{
    my $resp = {
        candidates => [
            {
                content => {
                    parts => [
                        { thought => 1, text => 'Thinking part 1. ' },
                        { thought => 1, text => 'Thinking part 2.' },
                        { text => 'Final answer' },
                    ],
                },
            },
        ],
    };
    local $ENV{GEMINI_API_KEY} = 'test-gem-key';
    configure_provider('gemini');
    my @blocks = parse_response($resp);
    is(scalar(@blocks), 2, 'Gemini fragmented thinking: merged thinking into 1 block');
    is($blocks[0]{type}, 'thinking', 'Block 0 is thinking');
    is($blocks[0]{text}, 'Thinking part 1. Thinking part 2.', 'Thinking parts joined');
    is($blocks[1]{type}, 'text', 'Block 1 is text');
    is($blocks[1]{text}, 'Final answer', 'Final answer is text');
}

# Anthropic / generic consecutive text blocks
{
    my $resp = {
        content => [
            { type => 'text', text => 'Hello ' },
            { type => 'text', text => 'World!' },
        ],
    };
    local $ENV{ANTHROPIC_API_KEY} = 'test-ant-key';
    configure_provider('anthropic');
    my @blocks = parse_response($resp);
    is(scalar(@blocks), 1, 'Anthropic consecutive text: merged into 1 block');
    is($blocks[0]{text}, 'Hello World!', 'Anthropic consecutive text: text joined');
}

# ==================================================================
# 8. Response truncation detection across providers
# ==================================================================
{
    # OpenAI truncation
    is(is_response_truncated({ choices => [{ finish_reason => 'length' }] }, 'openai'), 1,
       'OpenAI finish_reason length is truncated');
    is(is_response_truncated({ choices => [{ finish_reason => 'max_tokens' }] }, 'openai'), 1,
       'OpenAI finish_reason max_tokens is truncated');
    is(is_response_truncated({ choices => [{ finish_reason => 'stop' }] }, 'openai'), 0,
       'OpenAI finish_reason stop is not truncated');
    is(is_response_truncated({ choices => [{ finish_reason => 'tool_calls' }] }, 'openai'), 0,
       'OpenAI finish_reason tool_calls is not truncated');

    # Anthropic truncation
    is(is_response_truncated({ stop_reason => 'max_tokens' }, 'anthropic'), 1,
       'Anthropic stop_reason max_tokens is truncated');
    is(is_response_truncated({ stop_reason => 'end_turn' }, 'anthropic'), 0,
       'Anthropic stop_reason end_turn is not truncated');
    is(is_response_truncated({ stop_reason => 'tool_use' }, 'anthropic'), 0,
       'Anthropic stop_reason tool_use is not truncated');

    # Gemini truncation
    is(is_response_truncated({ candidates => [{ finishReason => 'MAX_TOKENS' }] }, 'gemini'), 1,
       'Gemini finishReason MAX_TOKENS is truncated');
    is(is_response_truncated({ candidates => [{ finishReason => 'STOP' }] }, 'gemini'), 0,
       'Gemini finishReason STOP is not truncated');

    # Default provider fallback & invalid inputs
    {
        local $ENV{ANTHROPIC_API_KEY} = 'test-ant-key';
        configure_provider('anthropic');
        is(is_response_truncated({ stop_reason => 'max_tokens' }), 1,
           'is_response_truncated defaults to current $PROVIDER');
    }
    is(is_response_truncated(undef, 'openai'), 0, 'undef response is not truncated');
    is(is_response_truncated({}, 'openai'), 0, 'empty response is not truncated');
}

# ==================================================================
# 9. Malformed / truncated tool-call JSON detection in parse_response_openai
# ==================================================================
{
    # Valid JSON object string
    my $resp_valid = {
        choices => [{
            message => {
                role => 'assistant',
                tool_calls => [{
                    id => 'call_ok',
                    function => {
                        name => 'write_file',
                        arguments => '{"path":"foo.txt","content":"hello"}',
                    },
                }],
            },
        }],
    };
    my @b_valid = parse_response_openai($resp_valid);
    is($b_valid[0]{type}, 'tool_use', 'Valid tool call parsed as tool_use');
    is_deeply($b_valid[0]{input}, { path => 'foo.txt', content => 'hello' }, 'Valid JSON decoded into hashref');
    ok(!exists $b_valid[0]{input}{_arg_parse_error}, 'No _arg_parse_error on valid JSON');

    # Empty / whitespace / undef arguments -> empty hashref {}
    for my $empty_arg (undef, '', '   ') {
        my $resp_empty = {
            choices => [{
                message => {
                    role => 'assistant',
                    tool_calls => [{
                        id => 'call_empty',
                        function => {
                            name => 'list_dir',
                            arguments => $empty_arg,
                        },
                    }],
                },
            }],
        };
        my @b_empty = parse_response_openai($resp_empty);
        is_deeply($b_empty[0]{input}, {}, 'Empty/undef arguments default to {} without error');
    }

    # Truncated / malformed JSON string -> _arg_parse_error
    my $truncated_json = '{"path":"tasks/plan.md","content":"# Plan\nThis was cut off mid-str';
    my $resp_trunc = {
        choices => [{
            message => {
                role => 'assistant',
                tool_calls => [{
                    id => 'call_trunc',
                    function => {
                        name => 'write_file',
                        arguments => $truncated_json,
                    },
                }],
            },
        }],
    };
    my @b_trunc = parse_response_openai($resp_trunc);
    is($b_trunc[0]{type}, 'tool_use', 'Truncated tool call still creates tool_use block');
    ok(exists $b_trunc[0]{input}{_arg_parse_error}, '_arg_parse_error is populated on truncated JSON');
    like($b_trunc[0]{input}{_arg_parse_error}, qr/\S/, '_arg_parse_error contains non-empty error message');
    is($b_trunc[0]{input}{_raw_arguments}, $truncated_json, '_raw_arguments preserves original string');

    # Non-HASH JSON (e.g. array) -> _arg_parse_error
    my $resp_arr = {
        choices => [{
            message => {
                role => 'assistant',
                tool_calls => [{
                    id => 'call_arr',
                    function => {
                        name => 'write_file',
                        arguments => '["not","an","object"]',
                    },
                }],
            },
        }],
    };
    my @b_arr = parse_response_openai($resp_arr);
    ok(exists $b_arr[0]{input}{_arg_parse_error}, '_arg_parse_error is populated when JSON decodes to non-HASH');

    # Already-decoded HASH reference -> passed through directly
    my $resp_hash = {
        choices => [{
            message => {
                role => 'assistant',
                tool_calls => [{
                    id => 'call_hash',
                    function => {
                        name => 'read_file',
                        arguments => { path => 'already_decoded.txt' },
                    },
                }],
            },
        }],
    };
    my @b_hash = parse_response_openai($resp_hash);
    is_deeply($b_hash[0]{input}, { path => 'already_decoded.txt' }, 'Already-decoded HASH arguments preserved as-is');
}

done_testing();
