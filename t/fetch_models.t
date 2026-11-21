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
# Test 1: Anthropic model discovery
# ------------------------------------------------------------------
{
    $ENV{ANTHROPIC_API_KEY} = 'test-ant-key-123';
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"claude-3-5-sonnet-20241022","display_name":"Claude 3.5 Sonnet"},{"id":"claude-3-haiku-20240307","display_name":"Claude 3 Haiku"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my ($models, $err) = fetch_models('anthropic');

    is($err, undef, "Anthropic fetch: no error");
    is_deeply($models, [
        { id => 'claude-3-5-sonnet-20241022', display => 'Claude 3.5 Sonnet' },
        { id => 'claude-3-haiku-20240307', display => 'Claude 3 Haiku' },
    ], "Anthropic fetch: models normalized with id and display");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "GET"$/m, "Anthropic request is GET");
    like($curl_cfg, qr{^url = "https://api\.anthropic\.com/v1/models\?limit=100"}m, "Anthropic URL includes limit=100");
    like($curl_cfg, qr/^header = "x-api-key: test-ant-key-123"$/m, "Anthropic x-api-key header passed");
}

# ------------------------------------------------------------------
# Test 2: Gemini model discovery (filter generateContent, strip models/)
# ------------------------------------------------------------------
{
    $ENV{GEMINI_API_KEY} = 'test-gemini-key-456';
    $ENV{MOCK_CURL_RESPONSE} = '{"models":[' .
        '{"name":"models/gemini-2.5-flash","displayName":"Gemini 2.5 Flash","supportedGenerationMethods":["generateContent","countTokens"]},' .
        '{"name":"models/text-embedding-004","displayName":"Text Embedding 004","supportedGenerationMethods":["embedContent"]},' .
        '{"name":"models/gemini-1.5-pro","displayName":"Gemini 1.5 Pro","supportedGenerationMethods":["generateContent"]}' .
    ']}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my ($models, $err) = fetch_models('gemini');

    is($err, undef, "Gemini fetch: no error");
    is_deeply($models, [
        { id => 'gemini-2.5-flash', display => 'Gemini 2.5 Flash' },
        { id => 'gemini-1.5-pro', display => 'Gemini 1.5 Pro' },
    ], "Gemini fetch: filters non-generateContent and strips models/ prefix");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "GET"$/m, "Gemini request is GET");
    like($curl_cfg, qr{^url = "https://generativelanguage\.googleapis\.com/v1beta/models\?pageSize=100"}m, "Gemini URL includes pageSize=100");
    like($curl_cfg, qr/^header = "x-goog-api-key: test-gemini-key-456"$/m, "Gemini x-goog-api-key header passed");
}

# ------------------------------------------------------------------
# Test 3: OpenAI model discovery
# ------------------------------------------------------------------
{
    $ENV{OPENAI_BASE_URL} = 'http://127.0.0.1:8080/v1/';
    $ENV{OPENAI_API_KEY} = 'test-oai-key-789';
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"gpt-4o","object":"model"},{"id":"llama-3.1-8b","object":"model"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my ($models, $err) = fetch_models('openai');

    is($err, undef, "OpenAI fetch: no error");
    is_deeply($models, [
        { id => 'gpt-4o', display => 'gpt-4o' },
        { id => 'llama-3.1-8b', display => 'llama-3.1-8b' },
    ], "OpenAI fetch: models normalized with id as default display");

    my $curl_cfg = read_file_content($ENV{MOCK_CURL_LOG});
    like($curl_cfg, qr/^request = "GET"$/m, "OpenAI request is GET");
    like($curl_cfg, qr{^url = "http://127\.0\.0\.1:8080/v1/models"}m, "OpenAI URL is base + /models");
    like($curl_cfg, qr/^header = "authorization: Bearer test-oai-key-789"$/m, "OpenAI authorization header passed");
}

# ------------------------------------------------------------------
# Test 4: Display name fallbacks
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"custom-model"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my ($models, $err) = fetch_models('anthropic');
    is_deeply($models, [
        { id => 'custom-model', display => 'custom-model' }
    ], "Fallback to id when display_name is omitted");
}

# ------------------------------------------------------------------
# Test 5: Default provider argument (uses current $PROVIDER)
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"m1","display_name":"Model 1"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    configure_provider('anthropic');
    my ($models, $err) = fetch_models();
    is($err, undef, "fetch_models() with no args uses current provider");
    is($models->[0]{id}, 'm1', "Fetched model from default provider");
}

# ------------------------------------------------------------------
# Test 6: HTTP error handling (e.g. 401 Unauthorized)
# ------------------------------------------------------------------
{
    $ENV{MOCK_CURL_RESPONSE} = '{"error":{"message":"Invalid API Key"}}';
    $ENV{MOCK_CURL_HTTP_CODE} = '401';

    my ($models, $err) = fetch_models('anthropic');
    is($models, undef, "HTTP 401: models is undef");
    like($err, qr/HTTP 401/, "HTTP 401: error string contains HTTP 401");
}

# ------------------------------------------------------------------
# Test 7: Missing API key / configuration error
# ------------------------------------------------------------------
{
    delete $ENV{GEMINI_API_KEY};
    delete $ENV{ANTHROPIC_API_KEY};
    delete $ENV{OPENAI_BASE_URL};

    # Force unconfigured provider
    my ($models, $err) = fetch_models('gemini');
    is($models, undef, "Missing GEMINI_API_KEY: models is undef");
    like($err, qr/GEMINI_API_KEY/, "Missing GEMINI_API_KEY reported cleanly");

    my ($oai_models, $oai_err) = fetch_models('openai');
    is($oai_models, undef, "Missing OPENAI_BASE_URL: models is undef");
    like($oai_err, qr/OPENAI_BASE_URL/, "Missing OPENAI_BASE_URL reported cleanly");

    my ($unk_models, $unk_err) = fetch_models('unsupported_provider');
    is($unk_models, undef, "Unknown provider: models is undef");
    like($unk_err, qr/Unknown provider/, "Unknown provider error reported");
}

# ------------------------------------------------------------------
# Test 8: Malformed or invalid payload structures
# ------------------------------------------------------------------
{
    $ENV{ANTHROPIC_API_KEY} = 'test-ant-key-123';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # Missing data array in Anthropic
    $ENV{MOCK_CURL_RESPONSE} = '{"wrong_key":[]}';
    my ($models1, $err1) = fetch_models('anthropic');
    is($models1, undef, "Malformed Anthropic response: models is undef");
    like($err1, qr/missing data array/, "Missing data array error");

    # Missing models array in Gemini
    $ENV{GEMINI_API_KEY} = 'test-gemini-key-456';
    $ENV{MOCK_CURL_RESPONSE} = '{"wrong_key":[]}';
    my ($models2, $err2) = fetch_models('gemini');
    is($models2, undef, "Malformed Gemini response: models is undef");
    like($err2, qr/missing models array/, "Missing models array error");

    # Gemini model without models/ prefix and without displayName
    $ENV{MOCK_CURL_RESPONSE} = '{"models":[{"name":"gemini-custom","supportedGenerationMethods":["generateContent"]}]}';
    my ($models3, $err3) = fetch_models('gemini');
    is_deeply($models3, [{ id => 'gemini-custom', display => 'gemini-custom' }],
        "Gemini model without prefix and without displayName handled cleanly");
}

# ------------------------------------------------------------------
# Test 9: Scalar context
# ------------------------------------------------------------------
{
    $ENV{ANTHROPIC_API_KEY} = 'test-ant-key-123';
    $ENV{MOCK_CURL_RESPONSE} = '{"data":[{"id":"claude-3-5-sonnet","display_name":"Sonnet"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    my $models = fetch_models('anthropic');
    is(ref($models), 'ARRAY', "Scalar context returns arrayref on success");
    is($models->[0]{id}, 'claude-3-5-sonnet', "Scalar context model id matches");

    $ENV{MOCK_CURL_HTTP_CODE} = '500';
    $ENV{MOCK_CURL_RESPONSE} = '{"error":"Internal error"}';
    my $failed_models = fetch_models('anthropic');
    is($failed_models, undef, "Scalar context returns undef on error");
}

# Cleanup test logs
unlink $ENV{MOCK_CURL_LOG} if -e $ENV{MOCK_CURL_LOG};
unlink $ENV{MOCK_CURL_REQ_CHECK} if -e $ENV{MOCK_CURL_REQ_CHECK};

done_testing();
