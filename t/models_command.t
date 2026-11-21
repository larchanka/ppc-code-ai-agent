#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

sub make_input_pipe {
    my ($data) = @_;
    pipe(my $reader, my $writer) or die "Cannot create pipe: $!";
    if (defined $data && length($data) > 0) {
        syswrite($writer, $data);
    }
    close $writer;
    return $reader;
}

# Ensure non-TTY fallback for predictable unit testing of interactive selection
our $FORCE_RAW;
$FORCE_RAW = 0;

# ==================================================================
# 1. show_help documents /models and other commands
# ==================================================================
{
    open my $out, '>', \my $captured;
    show_help($out);
    close $out;

    like($captured, qr{/models\b}, "show_help documents /models command");
    like($captured, qr{/claude\b}, "show_help documents /claude command");
    like($captured, qr{/gemini\b}, "show_help documents /gemini command");
    like($captured, qr{/openai\b}, "show_help documents /openai command");
    like($captured, qr{/help\b}, "show_help documents /help command");
}

# ==================================================================
# 2. handle_models_command: Anthropic model switch
# ==================================================================
{
    $ENV{ANTHROPIC_API_KEY} = 'test-ant-key';
    configure_provider('anthropic');
    my $orig_model = get_current_model();

    $ENV{MOCK_CURL_RESPONSE} = '{"data":[' .
        '{"id":"claude-3-5-sonnet-20241022","display_name":"Claude 3.5 Sonnet"},' .
        '{"id":"claude-3-5-haiku-20241022","display_name":"Claude 3.5 Haiku"}' .
    ']}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # Select item 2: claude-3-5-haiku-20241022
    my $in = make_input_pipe("2\n");
    open my $out, '>', \my $captured;

    my $res = handle_models_command($in, $out);
    close $out;

    is($res, 'claude-3-5-haiku-20241022', "handle_models_command returned selected model ID");
    is(get_current_model(), 'claude-3-5-haiku-20241022', "\$MODEL updated to selected model");
    is($ENV{CLAUDE_MODEL}, 'claude-3-5-haiku-20241022', "\$ENV{CLAUDE_MODEL} updated to selected model");
    like($captured, qr/Switched model to: claude-3-5-haiku-20241022/, "Printed switch confirmation message");
}

# ==================================================================
# 3. handle_models_command: Gemini model switch updates $API_URL
# ==================================================================
{
    $ENV{GEMINI_API_KEY} = 'test-gem-key';
    configure_provider('gemini');

    $ENV{MOCK_CURL_RESPONSE} = '{"models":[' .
        '{"name":"models/gemini-2.5-flash","displayName":"Gemini 2.5 Flash","supportedGenerationMethods":["generateContent"]},' .
        '{"name":"models/gemini-2.5-pro","displayName":"Gemini 2.5 Pro","supportedGenerationMethods":["generateContent"]}' .
    ']}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # Select item 2: gemini-2.5-pro
    my $in = make_input_pipe("2\n");
    open my $out, '>', \my $captured;

    my $res = handle_models_command($in, $out);
    close $out;

    is($res, 'gemini-2.5-pro', "handle_models_command returned selected Gemini model ID");
    is(get_current_model(), 'gemini-2.5-pro', "\$MODEL updated to gemini-2.5-pro");
    is($ENV{CLAUDE_MODEL}, 'gemini-2.5-pro', "\$ENV{CLAUDE_MODEL} updated to gemini-2.5-pro");
    is(get_current_api_url(), 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent',
       "\$API_URL updated with new Gemini model endpoint");
    like($captured, qr/Switched model to: gemini-2.5-pro/, "Printed Gemini switch confirmation");
}

# ==================================================================
# 4. handle_models_command: Cancellation retains current model
# ==================================================================
{
    $ENV{ANTHROPIC_API_KEY} = 'test-ant-key';
    configure_provider('anthropic');
    my $current_model = get_current_model();

    $ENV{MOCK_CURL_RESPONSE} = '{"data":[' .
        '{"id":"claude-3-5-sonnet-20241022","display_name":"Claude 3.5 Sonnet"}' .
    ']}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # Cancel with 'q'
    my $in = make_input_pipe("q\n");
    open my $out, '>', \my $captured;

    my $res = handle_models_command($in, $out);
    close $out;

    is(get_current_model(), $current_model, "Model unchanged on cancellation");
    like($captured, qr/Cancelled\. Staying on \Q$current_model\E/, "Printed cancellation message");
}

# ==================================================================
# 5. handle_models_command: Error in fetch_models handled cleanly
# ==================================================================
{
    $ENV{MOCK_CURL_RESPONSE} = '{"error":"Unauthorized"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '401';

    my $current_model = get_current_model();
    my $in = make_input_pipe("1\n");
    open my $out, '>', \my $captured;

    my $res = handle_models_command($in, $out);
    close $out;

    is($res, undef, "handle_models_command returns undef on fetch error");
    is(get_current_model(), $current_model, "Model unchanged on fetch error");
    like($captured, qr/Error fetching models:/, "Printed error fetching models message");
}

# ==================================================================
# 6. Integration: Interactive conversation loop with /models and /help
# ==================================================================
{
    my $perl = $^X;
    my $script = "$root_dir/code-agent.pl";

    # Test 6a: Banner and /help output in interactive loop
    {
        my $cmd = qq{printf "/help\\nexit\\n" | } .
                  qq{HOME="/nonexistent" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
                  qq{$perl $script 2>&1};
        my $output = `$cmd`;

        like($output, qr{/models}, "Startup banner or help text advertises /models");
        like($output, qr{Available commands:}, "Command loop routed /help");
        like($output, qr{Goodbye\.}, "Clean exit from conversation loop");
    }

    # Test 6b: /models command routing and cancellation in interactive loop
    {
        $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"claude-3-5-sonnet-20241022","display_name":"Claude 3.5 Sonnet"}]}';
        $ENV{MOCK_CURL_HTTP_CODE} = '200';

        my $cmd = qq{printf "/models\\nq\\nexit\\n" | } .
                  qq{HOME="/nonexistent" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
                  qq{MOCK_CURL_RESPONSE='$ENV{MOCK_CURL_RESPONSE}' MOCK_CURL_HTTP_CODE='200' } .
                  qq{$perl $script 2>&1};
        my $output = `$cmd`;

        like($output, qr{Cancelled\. Staying on}, "Loop handled /models and printed cancellation");
        like($output, qr{Goodbye\.}, "Clean exit after /models cancellation");
    }
}

# Cleanup test logs
unlink $ENV{MOCK_CURL_LOG} if defined $ENV{MOCK_CURL_LOG} && -e $ENV{MOCK_CURL_LOG};
unlink $ENV{MOCK_CURL_REQ_CHECK} if defined $ENV{MOCK_CURL_REQ_CHECK} && -e $ENV{MOCK_CURL_REQ_CHECK};

done_testing();
