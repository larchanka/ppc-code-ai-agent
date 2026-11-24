#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# Test 1: get_env_file_path returns ~/.code-agent/env
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;

    my $path = get_env_file_path();
    is($path, "$tmp/.code-agent/env", "get_env_file_path returns .code-agent/env");
}

# Test 2: load_env_file loads variables without overwriting existing
{
    my $tmp = tempdir(CLEANUP => 1);
    my $env_file = "$tmp/test_env";
    open(my $fh, '>', $env_file) or die "Cannot create $env_file: $!";
    print $fh "export VAR_UNQUOTED=hello\n";
    print $fh "export VAR_DOUBLE_QUOTED=\"world\"\n";
    print $fh "export VAR_SINGLE_QUOTED='tiger'\n";
    print $fh "VAR_NO_EXPORT=plain\n";
    print $fh "export VAR_PREEXISTING=new_val\n";
    print $fh "# comment line\n";
    print $fh "\n";
    close $fh;

    local $ENV{VAR_PREEXISTING} = "original_val";
    delete $ENV{VAR_UNQUOTED};
    delete $ENV{VAR_DOUBLE_QUOTED};
    delete $ENV{VAR_SINGLE_QUOTED};
    delete $ENV{VAR_NO_EXPORT};

    load_env_file($env_file);

    is($ENV{VAR_UNQUOTED}, 'hello', "Unquoted env var loaded");
    is($ENV{VAR_DOUBLE_QUOTED}, 'world', "Double quoted env var loaded");
    is($ENV{VAR_SINGLE_QUOTED}, 'tiger', "Single quoted env var loaded");
    is($ENV{VAR_NO_EXPORT}, 'plain', "Var without export loaded");
    is($ENV{VAR_PREEXISTING}, 'original_val', "Existing env var not overwritten");
}

# Test 3: load_env_file loads default ~/.code-agent/env
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;
    my $cfg_dir = "$tmp/.code-agent";
    mkdir $cfg_dir, 0700;
    my $env_file = "$cfg_dir/env";
    open(my $fh, '>', $env_file) or die "Cannot create $env_file: $!";
    print $fh "export DEFAULT_LOADED=yes\n";
    close $fh;

    delete $ENV{DEFAULT_LOADED};
    load_env_file();

    is($ENV{DEFAULT_LOADED}, 'yes', "load_env_file() loads default .code-agent/env");
}

# Test 4: _maybe_save_gemini_key creates directory and saves to ~/.code-agent/env
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;

    no warnings 'redefine';
    no warnings 'once';
    local *read_line_interactive = sub { return "y\n"; };
    use warnings 'redefine';

    _maybe_save_gemini_key("test_key_gemini_123");

    my $target = "$tmp/.code-agent/env";
    ok(-d "$tmp/.code-agent", "_maybe_save_gemini_key creates .code-agent directory");
    ok(-f $target, "_maybe_save_gemini_key creates .code-agent/env when clean install");
    open(my $fh, '<', $target) or die "Cannot read $target: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content, qr/export GEMINI_API_KEY=test_key_gemini_123/, "Saved key is present in .code-agent/env");
}

# Test 5: Shell wrapper logic (sources ~/.code-agent/env)
{
    my $tmp = tempdir(CLEANUP => 1);
    my $wrapper = "$tmp/code";
    open(my $wh, '>', $wrapper) or die "Cannot create $wrapper: $!";
    print $wh <<"EOF";
#!/bin/bash
if [ -f "\$HOME/.code-agent/env" ]; then
  source "\$HOME/.code-agent/env"
fi
echo "PROVIDER=\$TEST_PROVIDER"
EOF
    close $wh;
    chmod 0755, $wrapper;

    my $home = tempdir(CLEANUP => 1);
    mkdir "$home/.code-agent", 0700;
    open(my $mh, '>', "$home/.code-agent/env") or die $!;
    print $mh "export TEST_PROVIDER=modern_code\n";
    close $mh;
    my $out = `HOME="$home" /bin/bash "$wrapper"`;
    chomp $out;
    is($out, "PROVIDER=modern_code", "Wrapper script sources .code-agent/env");
}

# Test 6: Installer migration from legacy files to ~/.code-agent/env
{
    my $tmp = tempdir(CLEANUP => 1);
    my $legacy = "$tmp/.code-agent-env";
    open(my $lh, '>', $legacy) or die $!;
    print $lh "export LEGACY=migrated\n";
    close $lh;

    # Simulate installer migration logic
    my $config_dir = "$tmp/.code-agent";
    my $env_file   = "$config_dir/env";
    mkdir $config_dir, 0700;
    if (!-f $env_file) {
        if (-f "$tmp/.code-agent-env") {
            rename "$tmp/.code-agent-env", $env_file;
        } elsif (-f "$tmp/.claude-agent-env") {
            rename "$tmp/.claude-agent-env", $env_file;
        }
    }

    ok(-f $env_file, "Migrated legacy file to .code-agent/env");
    ok(!-f $legacy, "Old legacy file removed");
    open(my $fh, '<', $env_file) or die $!;
    my $c = do { local $/; <$fh> };
    close $fh;
    like($c, qr/export LEGACY=migrated/, "Migrated content intact");
}

# Test 7: Installer cleanup of legacy directories (~/code-toolchain, ~/code-build, etc.)
{
    my $tmp = tempdir(CLEANUP => 1);
    my $old_tc = "$tmp/code-toolchain";
    my $old_bd = "$tmp/code-build";
    my $leg_tc = "$tmp/claude-toolchain";
    my $leg_bd = "$tmp/claude-build";
    mkdir $old_tc or die $!;
    mkdir $old_bd or die $!;
    mkdir $leg_tc or die $!;
    mkdir $leg_bd or die $!;

    for my $dir ($old_tc, $old_bd, $leg_tc, $leg_bd) {
        if (-d $dir) {
            rmdir $dir or system("rm", "-rf", $dir);
        }
    }

    ok(!-d $old_tc, "Old code-toolchain removed");
    ok(!-d $old_bd, "Old code-build removed");
    ok(!-d $leg_tc, "Legacy claude-toolchain removed");
    ok(!-d $leg_bd, "Legacy claude-build removed");
}

done_testing();
