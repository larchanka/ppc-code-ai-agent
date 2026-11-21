#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 62;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";

# Ensure context env vars are unset before initial require
delete $ENV{CLAUDE_MAX_TOKENS};
delete $ENV{CLAUDE_CONTEXT};

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ==================================================================
# 1. parse_context_size($input)
# ==================================================================
is(parse_context_size('65536'), 65536, 'parse_context_size: integer 65536');
is(parse_context_size('8192'), 8192, 'parse_context_size: integer 8192');
is(parse_context_size('4096'), 4096, 'parse_context_size: integer 4096');
is(parse_context_size('  1234  '), 1234, 'parse_context_size: whitespace trimmed integer');

is(parse_context_size('8k'), 8192, 'parse_context_size: 8k');
is(parse_context_size('8K'), 8192, 'parse_context_size: 8K (uppercase)');
is(parse_context_size('64k'), 65536, 'parse_context_size: 64k');
is(parse_context_size('64K'), 65536, 'parse_context_size: 64K (uppercase)');
is(parse_context_size('128k'), 131072, 'parse_context_size: 128k');
is(parse_context_size('1m'), 1048576, 'parse_context_size: 1m');
is(parse_context_size('1M'), 1048576, 'parse_context_size: 1M (uppercase)');
is(parse_context_size('2m'), 2097152, 'parse_context_size: 2m');

is(parse_context_size(undef), undef, 'parse_context_size: undef returns undef');
is(parse_context_size(''), undef, 'parse_context_size: empty string returns undef');
is(parse_context_size('   '), undef, 'parse_context_size: whitespace only returns undef');
is(parse_context_size('0'), undef, 'parse_context_size: 0 returns undef');
is(parse_context_size('0k'), undef, 'parse_context_size: 0k returns undef');
is(parse_context_size('-10'), undef, 'parse_context_size: negative integer returns undef');
is(parse_context_size('abc'), undef, 'parse_context_size: non-numeric string returns undef');
is(parse_context_size('64kb'), undef, 'parse_context_size: invalid suffix returns undef');

# ==================================================================
# 2. format_context_size($tokens)
# ==================================================================
is(format_context_size(8192), '8k', 'format_context_size: 8192 -> 8k');
is(format_context_size(65536), '64k', 'format_context_size: 65536 -> 64k');
is(format_context_size(131072), '128k', 'format_context_size: 131072 -> 128k');
is(format_context_size(1048576), '1m', 'format_context_size: 1048576 -> 1m');
is(format_context_size(2097152), '2m', 'format_context_size: 2097152 -> 2m');
is(format_context_size(8000), '8000', 'format_context_size: 8000 -> 8000');
is(format_context_size(1500), '1500', 'format_context_size: 1500 -> 1500');

# ==================================================================
# 3. get_max_tokens() and set_max_tokens($tokens)
# ==================================================================
is(get_max_tokens(), 8192, 'Default max tokens is 8192 (8k)');

is(set_max_tokens(65536), 65536, 'set_max_tokens(65536) returns 65536');
is(get_max_tokens(), 65536, 'get_max_tokens() returns 65536 after update');
is($ENV{CLAUDE_MAX_TOKENS}, '65536', '$ENV{CLAUDE_MAX_TOKENS} updated to 65536');

is(set_max_tokens('128k'), 131072, 'set_max_tokens("128k") shorthand returns 131072');
is(get_max_tokens(), 131072, 'get_max_tokens() returns 131072');
is($ENV{CLAUDE_MAX_TOKENS}, '131072', '$ENV{CLAUDE_MAX_TOKENS} updated to 131072');

# Invalid set_max_tokens preserves current value and returns undef
is(set_max_tokens('invalid'), undef, 'set_max_tokens("invalid") returns undef');
is(get_max_tokens(), 131072, 'get_max_tokens() preserved after invalid input');

is(set_max_tokens(0), undef, 'set_max_tokens(0) returns undef');
is(get_max_tokens(), 131072, 'get_max_tokens() preserved after 0');

is(set_max_tokens(undef), undef, 'set_max_tokens(undef) returns undef');
is(get_max_tokens(), 131072, 'get_max_tokens() preserved after undef');

# ==================================================================
# 4. handle_ctx_command($args, $out_fh)
# ==================================================================
# Reset back to 8192
set_max_tokens(8192);

# 4.1 Query mode: no args
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    my $ret = handle_ctx_command('', $fh);
    close $fh;

    is($ret, 8192, 'handle_ctx_command("") returns current limit');
    like($output, qr/Current context limit: 8192 tokens \(8k\)/, 'handle_ctx_command prints current limit');
    like($output, qr/Usage: \/ctx/, 'handle_ctx_command prints usage');
}

# 4.2 Set mode with raw integer
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    my $ret = handle_ctx_command('65536', $fh);
    close $fh;

    is($ret, 65536, 'handle_ctx_command("65536") returns new limit');
    is(get_max_tokens(), 65536, 'get_max_tokens() updated');
    like($output, qr/Context limit set to 65536 tokens \(64k\)/, 'handle_ctx_command prints confirmation');
}

# 4.3 Set mode with shorthand unit
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    my $ret = handle_ctx_command('8k', $fh);
    close $fh;

    is($ret, 8192, 'handle_ctx_command("8k") returns 8192');
    is(get_max_tokens(), 8192, 'get_max_tokens() updated to 8192');
    like($output, qr/Context limit set to 8192 tokens \(8k\)/, 'handle_ctx_command prints confirmation for 8k');
}

# 4.4 Error handling mode
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    my $ret = handle_ctx_command('not_a_number', $fh);
    close $fh;

    is($ret, undef, 'handle_ctx_command("not_a_number") returns undef');
    is(get_max_tokens(), 8192, 'get_max_tokens() preserved after error');
    like($output, qr/Invalid context size 'not_a_number'/, 'handle_ctx_command prints error message');
}

# ==================================================================
# 5. show_help contains /ctx
# ==================================================================
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    show_help($fh);
    close $fh;

    like($output, qr{/ctx\b}, 'show_help output contains /ctx command');
}

# ==================================================================
# 6. Startup environment variable overrides
# ==================================================================
{
    my $cmd1 = qq{CLAUDE_MAX_TOKENS=64k CLAUDE_CONTEXT= $^X -e 'require "$root_dir/code-agent.pl"; print get_max_tokens();'};
    my $out1 = `$cmd1`;
    is($out1, '65536', 'Startup: CLAUDE_MAX_TOKENS=64k sets max tokens to 65536');

    my $cmd2 = qq{CLAUDE_MAX_TOKENS= CLAUDE_CONTEXT=16k $^X -e 'require "$root_dir/code-agent.pl"; print get_max_tokens();'};
    my $out2 = `$cmd2`;
    is($out2, '16384', 'Startup: CLAUDE_CONTEXT=16k sets max tokens to 16384');
}

# ==================================================================
# 7. load_env_file() re-evaluates $MAX_TOKENS from env file
# ==================================================================
{
    my $tmp_env = "$root_dir/t/test_ctx_env";
    open my $fh, '>', $tmp_env or die "Cannot create temp env: $!";
    print $fh "CLAUDE_MAX_TOKENS=32k\n";
    close $fh;

    set_max_tokens(8192);
    delete $ENV{CLAUDE_MAX_TOKENS};
    delete $ENV{CLAUDE_CONTEXT};
    load_env_file($tmp_env);
    is(get_max_tokens(), 32768, 'load_env_file re-evaluates $MAX_TOKENS from env file');
    unlink $tmp_env;
}

# ==================================================================
# 8. Provider build_request reflects active $MAX_TOKENS & override
# ==================================================================
{
    set_max_tokens(16384);
    $ENV{ANTHROPIC_API_KEY} = "test-ant-key";
    $ENV{GEMINI_API_KEY}    = "test-gem-key";
    $ENV{OPENAI_BASE_URL}   = "http://127.0.0.1:8080/v1";

    # Anthropic
    configure_provider('anthropic');
    my $req_ant = build_request([], [], 'system');
    is($req_ant->{max_tokens}, 16384, 'Anthropic build_request reflects updated $MAX_TOKENS');

    my $req_ant_over = build_request([], [], 'system', 32768);
    is($req_ant_over->{max_tokens}, 32768, 'Anthropic build_request supports explicit override');

    # Gemini
    configure_provider('gemini');
    my $req_gem = build_request([], [], 'system');
    is($req_gem->{generationConfig}{maxOutputTokens}, 16384, 'Gemini build_request reflects updated $MAX_TOKENS');

    my $req_gem_over = build_request([], [], 'system', 32768);
    is($req_gem_over->{generationConfig}{maxOutputTokens}, 32768, 'Gemini build_request supports explicit override');

    # OpenAI
    configure_provider('openai');
    my $req_oa = build_request([], [], 'system');
    is($req_oa->{max_tokens}, 16384, 'OpenAI build_request reflects updated $MAX_TOKENS');

    my $req_oa_over = build_request([], [], 'system', 32768);
    is($req_oa_over->{max_tokens}, 32768, 'OpenAI build_request supports explicit override');
}
