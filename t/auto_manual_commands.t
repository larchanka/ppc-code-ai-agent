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

# Ensure CLAUDE_AUTO_MODE is clean for default test
delete $ENV{CLAUDE_AUTO_MODE};

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ==================================================================
# Task 1: Auto Mode State Management & confirm_tool Helper
# ==================================================================

# 1. Default state and get_auto_mode
is(get_auto_mode(), 0, "Default auto mode is 0 (manual mode)");

# 2. set_auto_mode updates and returns new value
is(set_auto_mode(1), 1, "set_auto_mode(1) returns 1");
is(get_auto_mode(), 1, "get_auto_mode() returns 1 after set_auto_mode(1)");

is(set_auto_mode(0), 0, "set_auto_mode(0) returns 0");
is(get_auto_mode(), 0, "get_auto_mode() returns 0 after set_auto_mode(0)");

# 3. Truthy and falsy argument coercion
is(set_auto_mode('truthy_string'), 1, "set_auto_mode('truthy_string') normalizes to 1");
is(get_auto_mode(), 1, "get_auto_mode() returns 1");

is(set_auto_mode(''), 0, "set_auto_mode('') normalizes to 0");
is(get_auto_mode(), 0, "get_auto_mode() returns 0");

is(set_auto_mode(undef), 0, "set_auto_mode(undef) normalizes to 0");
is(get_auto_mode(), 0, "get_auto_mode() returns 0");

# 4. confirm_tool in auto mode (returns 1 without calling confirm)
{
    set_auto_mode(1);
    my $called_confirm = 0;
    no warnings 'redefine';
    local *confirm = sub {
        $called_confirm++;
        return 0;
    };

    my $res = confirm_tool("Should not ask");
    is($res, 1, "confirm_tool returns 1 when auto mode is active");
    is($called_confirm, 0, "confirm() was not called when auto mode is active");
}

# 5. confirm_tool in manual mode (delegates to confirm)
{
    set_auto_mode(0);
    my @called_prompts;
    no warnings 'redefine';
    local *confirm = sub {
        my ($prompt) = @_;
        push @called_prompts, $prompt;
        return 1;
    };

    my $res = confirm_tool("Test prompt 1");
    is($res, 1, "confirm_tool returns confirm result in manual mode");
    is_deeply(\@called_prompts, ["Test prompt 1"], "confirm() was called with prompt in manual mode");

    local *confirm = sub {
        my ($prompt) = @_;
        push @called_prompts, $prompt;
        return 0;
    };

    my $res_cancel = confirm_tool("Test prompt 2");
    is($res_cancel, 0, "confirm_tool returns 0 when user declines in manual mode");
    is_deeply(\@called_prompts, ["Test prompt 1", "Test prompt 2"], "confirm() called for second prompt");
}

# 6. Environment variable initialization
{
    my $cmd = qq{$^X -e 'delete \$ENV{CLAUDE_AUTO_MODE}; require "$root_dir/code-agent.pl"; exit(get_auto_mode() == 0 ? 0 : 1);'};
    my $status_default = system($cmd);
    is($status_default >> 8, 0, "Default initialization without env var is 0");

    my $cmd_env = qq{$^X -e '\$ENV{CLAUDE_AUTO_MODE} = "1"; require "$root_dir/code-agent.pl"; exit(get_auto_mode() == 1 ? 0 : 1);'};
    my $status_env = system($cmd_env);
    is($status_env >> 8, 0, "CLAUDE_AUTO_MODE=1 initializes auto mode to 1");
}

# ==================================================================
# Task 2: Tool Execution Integration in run_tool
# ==================================================================

my $test_file = "$root_dir/t/test_tool_write.tmp";
unlink $test_file if -e $test_file;

# 1. run_tool write_file and run_shell in auto mode (bypass confirm)
{
    set_auto_mode(1);
    my $confirm_calls = 0;
    no warnings 'redefine';
    local *confirm = sub {
        $confirm_calls++;
        return 0;
    };

    my $res_write = run_tool('write_file', { path => $test_file, content => "auto mode content\n" });
    is($confirm_calls, 0, "run_tool write_file in auto mode does not call confirm()");
    is($res_write, "Write complete: $test_file", "run_tool write_file returns success in auto mode");
    ok(-e $test_file, "file was created in auto mode");
    if (-e $test_file) {
        open my $rfh, '<', $test_file;
        my $content = <$rfh>;
        close $rfh;
        is($content, "auto mode content\n", "file content matches");
    }

    $confirm_calls = 0;
    my $res_shell = run_tool('run_shell', { command => 'echo "auto shell output"' });
    is($confirm_calls, 0, "run_tool run_shell in auto mode does not call confirm()");
    like($res_shell, qr/auto shell output/, "run_tool run_shell executed command in auto mode");

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $res_undef = run_tool('run_shell', { command => "true\0ignored" });
        is($res_undef, '(no output)', "run_tool run_shell handles undef backtick output as (no output)");
    }
    my @uninit_warnings = grep { /uninitialized value \$output/ } @warnings;
    is(scalar(@uninit_warnings), 0, "run_tool run_shell does not emit uninitialized warning when backticks return undef");

    unlink $test_file if -e $test_file;
}

# 2. run_tool write_file and run_shell in manual mode (enforce confirm)
{
    set_auto_mode(0);
    my @prompts;
    no warnings 'redefine';

    # A) User confirms write_file
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 1;
    };

    my $res_write = run_tool('write_file', { path => $test_file, content => "manual mode content\n" });
    is(scalar(@prompts), 1, "run_tool write_file in manual mode calls confirm()");
    like($prompts[0], qr/Write to file '$test_file'/, "confirm prompt has file path");
    is($res_write, "Write complete: $test_file", "run_tool write_file proceeds when confirmed");
    ok(-e $test_file, "file was created when confirmed");

    # B) User declines write_file
    @prompts = ();
    unlink $test_file if -e $test_file;
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 0;
    };

    my $res_write_cancel = run_tool('write_file', { path => $test_file, content => "should not write\n" });
    is(scalar(@prompts), 1, "run_tool write_file prompted user on decline");
    is($res_write_cancel, "Cancelled by user.", "run_tool write_file returns Cancelled by user");
    ok(! -e $test_file, "file was not written when cancelled");

    # C) User confirms run_shell
    @prompts = ();
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 1;
    };

    my $res_shell = run_tool('run_shell', { command => 'echo "manual shell output"' });
    is(scalar(@prompts), 1, "run_tool run_shell in manual mode calls confirm()");
    like($prompts[0], qr/Run this command: echo "manual shell output"/, "confirm prompt has command");
    like($res_shell, qr/manual shell output/, "run_tool run_shell proceeds when confirmed");

    # D) User declines run_shell
    @prompts = ();
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 0;
    };

    my $res_shell_cancel = run_tool('run_shell', { command => 'echo "should not run"' });
    is(scalar(@prompts), 1, "run_tool run_shell prompted user on decline");
    is($res_shell_cancel, "Cancelled by user.", "run_tool run_shell returns Cancelled by user");

    unlink $test_file if -e $test_file;
}

# ==================================================================
# Task 3: Command Handlers (/auto, /manual), Help & Main Loop
# ==================================================================

# 1. handle_auto_command
{
    set_auto_mode(0);
    open my $out, '>', \my $captured;
    my $ret = handle_auto_command($out);
    close $out;

    is(get_auto_mode(), 1, "handle_auto_command sets auto mode to 1");
    is($ret, 1, "handle_auto_command returns 1");
    like($captured, qr/Auto mode enabled\. Tools will execute without user confirmation\./,
         "handle_auto_command prints auto mode enabled confirmation");
}

# 2. handle_manual_command
{
    set_auto_mode(1);
    open my $out, '>', \my $captured;
    my $ret = handle_manual_command($out);
    close $out;

    is(get_auto_mode(), 0, "handle_manual_command sets auto mode to 0");
    is($ret, 0, "handle_manual_command returns 0");
    like($captured, qr/Manual mode enabled\. Tools will require user confirmation\./,
         "handle_manual_command prints manual mode enabled confirmation");
}

# 3. show_help documents /auto and /manual
{
    open my $out, '>', \my $captured;
    show_help($out);
    close $out;

    like($captured, qr{/auto\b}, "show_help documents /auto command");
    like($captured, qr{/manual\b}, "show_help documents /manual command");
}

# 4. Integration: Main conversation loop routes /auto and /manual
{
    my $perl = $^X;
    my $script = "$root_dir/code-agent.pl";

    my $cmd = qq{printf "/auto\\n/manual\\nexit\\n" | } .
              qq{ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
              qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
              qq{$perl $script 2>&1};
    my $output = `$cmd`;

    like($output, qr{/auto}, "Startup banner mentions /auto");
    like($output, qr{/manual}, "Startup banner mentions /manual");
    like($output, qr{Auto mode enabled\. Tools will execute without user confirmation\.},
         "Command loop routed /auto and printed confirmation");
    like($output, qr{Manual mode enabled\. Tools will require user confirmation\.},
         "Command loop routed /manual and printed confirmation");
    like($output, qr{Goodbye\.}, "Clean exit from conversation loop after /auto and /manual");
}

done_testing();
