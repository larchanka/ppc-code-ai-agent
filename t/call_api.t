#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{CLAUDE_RETRY_DELAY} = 0;
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";
$ENV{MOCK_CURL_REQ_CHECK} = "$root_dir/t/test_mock_curl_req.log";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

sub read_file_content {
    my ($file) = @_;
    return '' unless -f $file;
    open my $fh, '<', $file or return '';
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# ------------------------------------------------------------------
# Test 1: Default POST request (no $method argument)
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"id":"msg_123","type":"message"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $resp = call_api("http://localhost:8080/v1/chat", ["custom-header: foo"], '{"input":"test"}');

    is_deeply($resp, { id => "msg_123", type => "message" }, "Default POST returns decoded JSON");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "POST"$/m, "Default POST sets request = 'POST'");
    like($curl_cfg, qr/^header = "custom-header: foo"$/m, "Header passed to curl config");
    like($curl_cfg, qr/^data-binary = "\@\/tmp\/(?:code|claude)-agent-req-\d+\.json"$/m, "Default POST includes data-binary");

    my $req_check = read_file_content($ENV{MOCK_CURL_REQ_CHECK});
    like($req_check, qr/^REQ_EXISTS:/, "Default POST created request body tempfile");
}

# ------------------------------------------------------------------
# Test 2: Explicit POST request with $method = 'POST'
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"result":"created"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $resp = call_api("http://localhost:8080/v1/chat", [], '{"data":1}', 'POST');

    is_deeply($resp, { result => "created" }, "Explicit POST returns decoded JSON");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "POST"$/m, "Explicit POST sets request = 'POST'");
    like($curl_cfg, qr/^data-binary = "\@\/tmp\/(?:code|claude)-agent-req-\d+\.json"$/m, "Explicit POST includes data-binary");
}

# ------------------------------------------------------------------
# Test 3: HTTP GET request with $method = 'GET'
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"models":[{"id":"claude-3"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $resp = call_api("http://localhost:8080/v1/models", ["x-api-key: secret"], undef, 'GET');

    is_deeply($resp, { models => [{ id => "claude-3" }] }, "GET request returns decoded JSON");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "GET"$/m, "GET sets request = 'GET'");
    unlike($curl_cfg, qr/data-binary/, "GET omits data-binary in curl config");

    my $req_check = read_file_content($ENV{MOCK_CURL_REQ_CHECK});
    like($req_check, qr/^REQ_NONE/, "GET does not create request tempfile");
}

# ------------------------------------------------------------------
# Test 4: HTTP GET with lowercase method 'get'
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $resp = call_api("http://localhost:8080/v1/models", [], undef, 'get');

    is_deeply($resp, { data => [] }, "lowercase 'get' returns decoded JSON");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "GET"$/m, "lowercase 'get' normalized to 'GET'");
    unlike($curl_cfg, qr/data-binary/, "lowercase 'get' omits data-binary");
}

# ------------------------------------------------------------------
# Test 5: HTTPS URL includes cacert in config
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"status":"secure"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $resp = call_api("https://api.anthropic.com/v1/models", [], undef, 'GET');

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^cacert = /m, "HTTPS GET includes cacert in curl config");
}

# ------------------------------------------------------------------
# Test 6: HTTP non-2xx error handling
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"error":"Not Found"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '404';

    eval { call_api("http://localhost:8080/v1/models", [], undef, 'GET') };
    like($@, qr/API error \(HTTP 404\): \{"error":"Not Found"\}/, "HTTP 404 throws expected exception");
}

# Cleanup test logs
unlink $ENV{MOCK_CURL_LOG} if -e $ENV{MOCK_CURL_LOG};
unlink $ENV{MOCK_CURL_REQ_CHECK} if -e $ENV{MOCK_CURL_REQ_CHECK};

done_testing();
