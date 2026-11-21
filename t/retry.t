#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use Time::HiRes qw(time);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL}      = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT}    = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG}    = "$root_dir/t/test_retry_curl.log";
$ENV{MOCK_CURL_REQ_CHECK} = "$root_dir/t/test_retry_curl_req.log";
$ENV{MOCK_CURL_COUNT_FILE} = "$root_dir/t/test_retry_curl_count.log";

delete $ENV{CLAUDE_MAX_RETRIES};
delete $ENV{CLAUDE_RETRY_DELAY};

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our ($MAX_RETRIES, $RETRY_DELAY, $COLOR_DIM, $COLOR_RESET);

sub read_file_content {
    my ($file) = @_;
    return '' unless defined $file && -f $file;
    open my $fh, '<', $file or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return defined $content ? $content : '';
}

sub get_attempt_count {
    my $raw = read_file_content($ENV{MOCK_CURL_COUNT_FILE});
    $raw =~ s/^\s+|\s+$//g;
    return length($raw) ? int($raw) : 0;
}

sub reset_mock {
    unlink $ENV{MOCK_CURL_COUNT_FILE} if -e $ENV{MOCK_CURL_COUNT_FILE};
    unlink $ENV{MOCK_CURL_LOG}        if -e $ENV{MOCK_CURL_LOG};
    unlink $ENV{MOCK_CURL_REQ_CHECK}  if -e $ENV{MOCK_CURL_REQ_CHECK};
    delete $ENV{MOCK_CURL_HTTP_SEQUENCE};
    delete $ENV{MOCK_CURL_RESP_SEQUENCE};
    delete $ENV{MOCK_CURL_HTTP_CODE};
    delete $ENV{MOCK_CURL_RESPONSE};
}

# ==================================================================
# 1. Default Configuration & Environment Variable Overrides
# ==================================================================
{
    local $ENV{CLAUDE_MAX_RETRIES} = undef;
    local $ENV{CLAUDE_RETRY_DELAY} = undef;
    delete $ENV{CLAUDE_MAX_RETRIES};
    delete $ENV{CLAUDE_RETRY_DELAY};

    is($MAX_RETRIES, 3, "Default \$MAX_RETRIES is 3");
    is($RETRY_DELAY, 5, "Default \$RETRY_DELAY is 5");
    is(get_max_retries(), 3, "get_max_retries() defaults to 3");
    is(get_retry_delay(), 5, "get_retry_delay() defaults to 5");

    # Custom overrides via environment variables
    local $ENV{CLAUDE_MAX_RETRIES} = '4';
    local $ENV{CLAUDE_RETRY_DELAY} = '2.5';
    is(get_max_retries(), 4, "get_max_retries() respects CLAUDE_MAX_RETRIES=4");
    is(get_retry_delay(), 2.5, "get_retry_delay() respects CLAUDE_RETRY_DELAY=2.5");

    # Zero overrides
    $ENV{CLAUDE_MAX_RETRIES} = '0';
    $ENV{CLAUDE_RETRY_DELAY} = '0';
    is(get_max_retries(), 0, "get_max_retries() allows 0");
    is(get_retry_delay(), 0, "get_retry_delay() allows 0");

    # Negative values clamped to 0
    $ENV{CLAUDE_MAX_RETRIES} = '-2';
    $ENV{CLAUDE_RETRY_DELAY} = '-5';
    is(get_max_retries(), 0, "Negative CLAUDE_MAX_RETRIES clamped to 0");
    is(get_retry_delay(), 0, "Negative CLAUDE_RETRY_DELAY clamped to 0");

    # Invalid values fall back to globals
    $ENV{CLAUDE_MAX_RETRIES} = 'abc';
    $ENV{CLAUDE_RETRY_DELAY} = 'xyz';
    is(get_max_retries(), 3, "Invalid CLAUDE_MAX_RETRIES falls back to \$MAX_RETRIES");
    is(get_retry_delay(), 5, "Invalid CLAUDE_RETRY_DELAY falls back to \$RETRY_DELAY");

    # load_env_file integration
    my $tmp_dir = tempdir(CLEANUP => 1);
    my $env_file = "$tmp_dir/.code-agent-env";
    open my $ef, '>', $env_file or die $!;
    print $ef "export CLAUDE_MAX_RETRIES=2\n";
    print $ef "export CLAUDE_RETRY_DELAY=7\n";
    close $ef;

    delete $ENV{CLAUDE_MAX_RETRIES};
    delete $ENV{CLAUDE_RETRY_DELAY};
    load_env_file($env_file);
    is($MAX_RETRIES, 2, "load_env_file updates \$MAX_RETRIES");
    is($RETRY_DELAY, 7, "load_env_file updates \$RETRY_DELAY");

    # Restore defaults
    delete $ENV{CLAUDE_MAX_RETRIES};
    delete $ENV{CLAUDE_RETRY_DELAY};
    $MAX_RETRIES = 3;
    $RETRY_DELAY = 5;
}

# ==================================================================
# 2. UI Retry Status Formatting
# ==================================================================
{
    local $COLOR_DIM   = '';
    local $COLOR_RESET = '';
    is(
        format_retry_status(1, 3, 5),
        "* API error, retrying in 5s (1/3)...",
        "format_retry_status plain text without color"
    );

    local $COLOR_DIM   = "\x1b[33m";
    local $COLOR_RESET = "\x1b[0m";
    is(
        format_retry_status(2, 3, 5),
        "\x1b[33m* API error, retrying in 5s (2/3)...\x1b[0m",
        "format_retry_status wraps with COLOR_DIM and COLOR_RESET"
    );
}

# Use 0 delay for fast functional retry tests
local $ENV{CLAUDE_RETRY_DELAY} = 0;

# ==================================================================
# 3. Immediate Success on First Attempt (0 retries, 1 total call)
# ==================================================================
{
    reset_mock();
    $ENV{MOCK_CURL_HTTP_CODE} = '200';
    $ENV{MOCK_CURL_RESPONSE}  = '{"id":"msg_1","type":"message","content":[{"type":"text","text":"Immediate success"}]}';

    my $resp = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"hi"}');
    is($resp->{id}, 'msg_1', "Immediate success returns decoded payload");
    is(get_attempt_count(), 1, "Immediate success makes exactly 1 curl invocation");

    # HTTP 201 Created is also treated as 2xx success without retrying
    reset_mock();
    $ENV{MOCK_CURL_HTTP_CODE} = '201';
    $ENV{MOCK_CURL_RESPONSE}  = '{"id":"msg_201"}';
    my $resp_201 = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"hi201"}');
    is($resp_201->{id}, 'msg_201', "HTTP 201 2xx status succeeds on first attempt");
    is(get_attempt_count(), 1, "HTTP 201 makes 1 attempt with 0 retries");
}

# ==================================================================
# 4. Transient HTTP Errors Recovering on Retry 1, Retry 2, and Retry 3
# ==================================================================
{
    # 4a: Recover on Retry 1 (Attempt 2)
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '500,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Internal Server Error"}',
        '{"id":"msg_retry1","status":"recovered_on_1"}'
    );

    my $resp1 = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"retry1"}');
    is($resp1->{id}, 'msg_retry1', "Recovered on 1st retry (attempt 2)");
    is(get_attempt_count(), 2, "Made 2 total attempts for 1st retry recovery");

    # 4b: Recover on Retry 2 (Attempt 3)
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '502,503,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Bad Gateway"}',
        '{"error":"Service Unavailable"}',
        '{"id":"msg_retry2","status":"recovered_on_2"}'
    );

    my $resp2 = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"retry2"}');
    is($resp2->{id}, 'msg_retry2', "Recovered on 2nd retry (attempt 3)");
    is(get_attempt_count(), 3, "Made 3 total attempts for 2nd retry recovery");

    # 4c: Recover on Final Retry 3 (Attempt 4)
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '500,503,429,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Internal Error"}',
        '{"error":"Overloaded"}',
        '{"error":"Rate limit"}',
        '{"id":"msg_retry3","status":"recovered_on_3"}'
    );

    my $resp3 = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"retry3"}');
    is($resp3->{id}, 'msg_retry3', "Recovered on final 3rd retry (attempt 4)");
    is(get_attempt_count(), 4, "Made 4 total attempts for 3rd retry recovery");
}

# ==================================================================
# 5. Persistent Error Exhausting All 3 Retries (4 total attempts)
# ==================================================================
{
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '500,502,503,529';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Fail 1"}',
        '{"error":"Fail 2"}',
        '{"error":"Fail 3"}',
        '{"error":"Site is overloaded"}'
    );

    my $resp = eval { call_api("http://localhost:8080/v1/messages", [], '{"prompt":"fail"}') };
    my $err  = $@;

    is($resp, undef, "Exhausted retries returns undef / dies");
    like($err, qr/API error \(HTTP 529\): \{"error":"Site is overloaded"\}/,
        "Dies with the final attempt's HTTP error message");
    is(get_attempt_count(), 4, "Executed initial attempt + 3 retries = 4 total attempts");
}

# ==================================================================
# 6. Respecting Custom CLAUDE_MAX_RETRIES (0 and 1)
# ==================================================================
{
    reset_mock();
    local $ENV{CLAUDE_MAX_RETRIES} = 0;
    $ENV{MOCK_CURL_HTTP_CODE} = '500';
    $ENV{MOCK_CURL_RESPONSE}  = '{"error":"No retries allowed"}';

    eval { call_api("http://localhost:8080/v1/messages", [], '{"prompt":"no_retry"}') };
    like($@, qr/API error \(HTTP 500\)/, "Dies immediately when CLAUDE_MAX_RETRIES=0");
    is(get_attempt_count(), 1, "Only 1 attempt made when CLAUDE_MAX_RETRIES=0");

    reset_mock();
    local $ENV{CLAUDE_MAX_RETRIES} = 1;
    $ENV{MOCK_CURL_HTTP_CODE} = '503';
    $ENV{MOCK_CURL_RESPONSE}  = '{"error":"One retry allowed"}';

    eval { call_api("http://localhost:8080/v1/messages", [], '{"prompt":"one_retry"}') };
    like($@, qr/API error \(HTTP 503\)/, "Dies after 1 retry when CLAUDE_MAX_RETRIES=1");
    is(get_attempt_count(), 2, "Exactly 2 attempts made when CLAUDE_MAX_RETRIES=1");
}

# ==================================================================
# 7. Provider-Level Error Object in HTTP 200 Response & Malformed JSON
# ==================================================================
{
    # 7a: HTTP 200 with top-level {"error": ...} recovers on retry
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '200,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":{"message":"Upstream model overloaded","code":503}}',
        '{"id":"msg_ok_after_err_obj","content":[{"type":"text","text":"Success"}]}'
    );

    my $resp = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"test"}');
    is($resp->{id}, 'msg_ok_after_err_obj', "Recovers from HTTP 200 payload containing top-level error object");
    is(get_attempt_count(), 2, "Retried once after provider error object");

    # 7b: HTTP 200 with {"type":"error"} (without top-level "error" field) exhausts retries and dies
    reset_mock();
    $ENV{MOCK_CURL_HTTP_CODE} = '200';
    $ENV{MOCK_CURL_RESPONSE}  = '{"type":"error","message":"Overloaded"}';

    eval { call_api("http://localhost:8080/v1/messages", [], '{"prompt":"test"}') };
    like($@, qr/API error:/, "Persistent HTTP 200 type=error object dies with API error");
    is(get_attempt_count(), 4, "Retried 3 times (4 attempts) on persistent HTTP 200 type=error object");

    # 7c: Truncated / malformed JSON response recovers on retry
    reset_mock();
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '200,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"id":"truncated_json',
        '{"id":"msg_valid_json"}'
    );

    my $resp_json = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"test"}');
    is($resp_json->{id}, 'msg_valid_json', "Recovers from transient malformed JSON response");
    is(get_attempt_count(), 2, "Retried once after JSON parse failure");
}

# ==================================================================
# 8. Retry Delay Timing & TTY Status Display
# ==================================================================
{
    reset_mock();
    local $ENV{CLAUDE_RETRY_DELAY} = 0.08;
    local $ENV{CLAUDE_TEST_TTY}    = 0;

    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '503,503,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Unavailable 1"}',
        '{"error":"Unavailable 2"}',
        '{"id":"msg_timed"}'
    );

    my $t0 = time();
    my $resp = call_api("http://localhost:8080/v1/messages", [], '{"prompt":"timed"}');
    my $elapsed = time() - $t0;

    is($resp->{id}, 'msg_timed', "Succeeded after 2 delayed retries");
    is(get_attempt_count(), 3, "Made 3 attempts in timed test");
    cmp_ok($elapsed, '>=', 0.15, "Waited at least 2 * 0.08s between retry attempts");

    # Verify exhausted retries with TTY active only prints retry status max_retries times (never after final attempt)
    reset_mock();
    local $ENV{CLAUDE_TEST_TTY}    = 1;
    local $ENV{CLAUDE_MAX_RETRIES} = 2;
    local $ENV{CLAUDE_RETRY_DELAY} = 0;
    local $COLOR_DIM               = '';
    local $COLOR_RESET             = '';
    $ENV{MOCK_CURL_HTTP_CODE} = '503';
    $ENV{MOCK_CURL_RESPONSE}  = '{"error":"Persistent 503"}';

    my $tty_out = '';
    {
        open my $fh, '>', \$tty_out;
        my $old = select($fh);
        eval { call_api("http://localhost:8080/v1/messages", [], '{"prompt":"exhaust_tty"}') };
        select($old);
        close $fh;
    }
    like($tty_out, qr/\(1\/2\)/, "TTY output shows retry (1/2)");
    like($tty_out, qr/\(2\/2\)/, "TTY output shows retry (2/2)");
    unlike($tty_out, qr/\(3\/2\)/, "TTY output does NOT print retry status after final exhausted attempt");
}

# ==================================================================
# 9. Sub-Agent (run_subagent) Recovery via call_api Retry
# ==================================================================
{
    reset_mock();
    local $ENV{ANTHROPIC_API_KEY} = 'sk-test-subagent-retry';
    configure_provider('anthropic');

    # Attempt 1 fails with HTTP 503, Attempt 2 succeeds with subagent completion text
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '503,200';
    $ENV{MOCK_CURL_RESP_SEQUENCE} = join("\n",
        '{"error":"Service temporarily unavailable"}',
        '{"content":[{"type":"text","text":"Subagent finished after transient error."}]}'
    );

    my $result = run_subagent("Verify retry inside subagent", "plan");
    is($result, "Subagent finished after transient error.",
        "run_subagent transparently recovers from transient API failure");
    is(get_attempt_count(), 2, "Subagent turn made 2 attempts (1 initial + 1 retry)");
}

# ==================================================================
# 10. Documentation Coverage (README.md & README.txt)
# ==================================================================
{
    my $readme_md  = read_file_content("$root_dir/README.md");
    my $readme_txt = read_file_content("$root_dir/README.txt");

    like($readme_md, qr/CLAUDE_MAX_RETRIES/, "README.md documents CLAUDE_MAX_RETRIES");
    like($readme_md, qr/CLAUDE_RETRY_DELAY/, "README.md documents CLAUDE_RETRY_DELAY");
    like($readme_md, qr/3 retries/i, "README.md documents default 3 retries");
    like($readme_md, qr/t\/retry\.t/, "README.md lists t/retry.t in test suites");

    like($readme_txt, qr/CLAUDE_MAX_RETRIES/, "README.txt documents CLAUDE_MAX_RETRIES");
    like($readme_txt, qr/CLAUDE_RETRY_DELAY/, "README.txt documents CLAUDE_RETRY_DELAY");
}

reset_mock();
done_testing();
