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

done_testing();
