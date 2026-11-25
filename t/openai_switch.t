#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our ($PROVIDER, $MODEL, $API_KEY, $API_URL, $CURRENT_SESSION);

# ==================================================================
# 1. URL Normalization: normalize_openai_endpoint
# ==================================================================
{
    ok(defined &normalize_openai_endpoint, "normalize_openai_endpoint subroutine exists");

    is(normalize_openai_endpoint("http://192.168.1.50:8080/v1/"),
       "http://192.168.1.50:8080/v1",
       "strips trailing slash");

    is(normalize_openai_endpoint("http://192.168.1.50:8080/v1///"),
       "http://192.168.1.50:8080/v1",
       "strips multiple trailing slashes");

    is(normalize_openai_endpoint("localhost:11434/v1"),
       "http://localhost:11434/v1",
       "prepends http:// when protocol missing");

    is(normalize_openai_endpoint("https://api.together.xyz/v1/"),
       "https://api.together.xyz/v1",
       "preserves https:// prefix");

    is(normalize_openai_endpoint("   127.0.0.1:8000/v1   "),
       "http://127.0.0.1:8000/v1",
       "trims whitespace and prepends http://");

    is(normalize_openai_endpoint(""),
       "",
       "empty string remains empty");

    is(normalize_openai_endpoint(undef),
       undef,
       "undef remains undef");
}

# ==================================================================
# 2. Interactive Switching when OPENAI_BASE_URL is unset
# ==================================================================
{
    delete $ENV{OPENAI_BASE_URL};
    delete $ENV{OPENAI_API_KEY};
    delete $ENV{CLAUDE_MODEL};

    # Start on Anthropic provider
    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test123456";
    configure_provider('anthropic');
    is(get_current_provider(), 'anthropic', "initial provider is anthropic");

    # Setup session with messages
    my $session = init_session("test-openai-session");
    push @{$session->{messages}}, { role => 'user', content => "Hello world" };
    push @{$session->{messages}}, { role => 'assistant', content => "Hi there!" };

    # Mock inputs:
    # 1. Base URL: "192.168.1.100:8080/v1"
    # 2. Model: "my-qwen-model"
    # 3. API key: "secret-key"
    # 4. Save confirm: "y"
    my @mock_inputs = (
        "192.168.1.100:8080/v1",
        "my-qwen-model",
        "secret-key",
    );
    my $input_idx = 0;

    no warnings 'redefine';
    local *read_line_or_cancel = sub {
        return $mock_inputs[$input_idx++];
    };

    my $tmp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp_home;

    local *confirm = sub {
        my ($msg) = @_;
        return 1 if $msg =~ /Save this configuration/i;
        return 0;
    };

    my $out = '';
    open my $capture_fh, '>', \$out or die $!;
    my $old_stdout = select $capture_fh;

    my $switched = handle_openai_switch();

    select $old_stdout;
    close $capture_fh;

    ok($switched, "handle_openai_switch returns true on success");
    is(get_current_provider(), 'openai', "provider switched to openai");
    is(get_current_model(), 'my-qwen-model', "model updated to entered model");
    is($ENV{OPENAI_API_KEY}, 'secret-key', "API key updated to entered key");
    is(get_current_api_url(), 'http://192.168.1.100:8080/v1/chat/completions', "API URL set correctly");

    # Verify conversation carried over
    my $curr_session = get_current_session();
    is($curr_session->{id}, "test-openai-session", "session id preserved");
    is(scalar(@{$curr_session->{messages}}), 2, "conversation history carries over");

    # Verify saved env file
    my $env_file = "$tmp_home/.code-agent/env";
    ok(-f $env_file, "env file was saved to $env_file");
    open my $efh, '<', $env_file or die $!;
    my $saved_content = do { local $/; <$efh> };
    close $efh;

    like($saved_content, qr/export OPENAI_BASE_URL=http:\/\/192\.168\.1\.100:8080\/v1/, "OPENAI_BASE_URL saved");
    like($saved_content, qr/export CLAUDE_MODEL=my-qwen-model/, "CLAUDE_MODEL saved");
    like($saved_content, qr/export OPENAI_API_KEY=secret-key/, "OPENAI_API_KEY saved");
}

# ==================================================================
# 3. Interactive Switching: Cancellation (empty or undef input)
# ==================================================================
{
    delete $ENV{OPENAI_BASE_URL};
    delete $ENV{OPENAI_API_KEY};
    delete $ENV{CLAUDE_MODEL};

    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test123456";
    configure_provider('anthropic');
    is(get_current_provider(), 'anthropic', "provider is anthropic");
    my $orig_model = get_current_model();

    # Test 1: undef input (simulating Esc or Ctrl+C)
    {
        no warnings 'redefine';
        local *read_line_or_cancel = sub { return undef; };

        my $out = '';
        open my $capture_fh, '>', \$out or die $!;
        my $old_stdout = select $capture_fh;

        my $switched = handle_openai_switch();

        select $old_stdout;
        close $capture_fh;

        ok(!$switched, "handle_openai_switch returns false on cancel (undef)");
        is(get_current_provider(), 'anthropic', "provider remains anthropic");
        is(get_current_model(), $orig_model, "model unchanged");
        like($out, qr/Cancelled/i, "prints Cancelled notice");
    }

    # Test 2: empty string input (user just hit enter without typing url)
    {
        no warnings 'redefine';
        local *read_line_or_cancel = sub { return "   \n"; };

        my $out = '';
        open my $capture_fh, '>', \$out or die $!;
        my $old_stdout = select $capture_fh;

        my $switched = handle_openai_switch();

        select $old_stdout;
        close $capture_fh;

        ok(!$switched, "handle_openai_switch returns false on empty url");
        is(get_current_provider(), 'anthropic', "provider remains anthropic");
        is(get_current_model(), $orig_model, "model unchanged");
        like($out, qr/Cancelled/i, "prints Cancelled notice");
    }
}

# ==================================================================
# 4. Interactive Switching: Defaults for Model & API Key
# ==================================================================
{
    delete $ENV{OPENAI_BASE_URL};
    delete $ENV{OPENAI_API_KEY};
    delete $ENV{CLAUDE_MODEL};

    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test123456";
    configure_provider('anthropic');

    my @inputs = (
        "http://localhost:11434/v1",  # URL
        "",                           # Model default
        "",                           # Key default
    );
    my $idx = 0;

    no warnings 'redefine';
    local *read_line_or_cancel = sub { return $inputs[$idx++]; };
    local *confirm = sub { return 0; };  # do not save

    my $out = '';
    open my $capture_fh, '>', \$out or die $!;
    my $old_stdout = select $capture_fh;

    my $switched = handle_openai_switch();

    select $old_stdout;
    close $capture_fh;

    ok($switched, "switched with defaults");
    is(get_current_provider(), 'openai', "provider is openai");
    is(get_current_model(), 'local-model', "default model is local-model");
    is(get_current_api_url(), 'http://localhost:11434/v1/chat/completions', "API URL set correctly");
}

# ==================================================================
# 5. When OPENAI_BASE_URL is already in ENV
# ==================================================================
{
    $ENV{OPENAI_BASE_URL} = "http://10.0.0.5:8000/v1";
    $ENV{OPENAI_API_KEY} = "my-env-key";
    delete $ENV{CLAUDE_MODEL};

    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test123456";
    configure_provider('anthropic');

    my $called_prompt = 0;
    no warnings 'redefine';
    local *read_line_or_cancel = sub { $called_prompt++; return undef; };

    my $out = '';
    open my $capture_fh, '>', \$out or die $!;
    my $old_stdout = select $capture_fh;

    my $switched = handle_openai_switch();

    select $old_stdout;
    close $capture_fh;

    ok($switched, "switched without prompting");
    is($called_prompt, 0, "did not prompt user when OPENAI_BASE_URL is already in ENV");
    is(get_current_provider(), 'openai', "provider is openai");
    is(get_current_model(), 'local-model', "model set");
    is($ENV{OPENAI_API_KEY}, 'my-env-key', "API key taken from ENV");
}

# ==================================================================
# 6. Save Configuration to existing env file (update or append)
# ==================================================================
{
    my $tmp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp_home;
    my $env_dir = "$tmp_home/.code-agent";
    mkdir $env_dir, 0700;
    my $env_file = "$env_dir/env";

    open my $fh, '>', $env_file or die $!;
    print $fh "export ANTHROPIC_API_KEY=existing-key\n";
    print $fh "export OPENAI_BASE_URL=old-url\n";
    close $fh;

    save_env_vars({
        OPENAI_BASE_URL => 'http://new-host:1234/v1',
        CLAUDE_MODEL    => 'custom-model',
    }, $env_file);

    open my $rfh, '<', $env_file or die $!;
    my $content = do { local $/; <$rfh> };
    close $rfh;

    like($content, qr/export ANTHROPIC_API_KEY=existing-key/, "existing unrelated keys preserved");
    like($content, qr/export OPENAI_BASE_URL=http:\/\/new-host:1234\/v1/, "OPENAI_BASE_URL updated");
    unlike($content, qr/export OPENAI_BASE_URL=old-url/, "old OPENAI_BASE_URL replaced");
    like($content, qr/export CLAUDE_MODEL=custom-model/, "CLAUDE_MODEL added");
}

# ==================================================================
# 7. Command Aliases: /openai and /local in REPL & show_help
# ==================================================================
{
    my $help_out = '';
    open my $hfh, '>', \$help_out or die $!;
    show_help($hfh);
    close $hfh;

    like($help_out, qr/\/openai\s+.*\/local/, "show_help documents /openai and /local alias");
}

done_testing();
