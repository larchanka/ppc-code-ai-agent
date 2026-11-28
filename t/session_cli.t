#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{CLAUDE_SESSION_AUTO_TITLE} = "0";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our $CURRENT_SESSION;
our $PROVIDER;
our $MODEL;

my $sessions_dir = tempdir(CLEANUP => 1);
$ENV{CLAUDE_SESSIONS_DIR} = $sessions_dir;

# Helper to capture output
sub capture_fh {
    my ($code) = @_;
    my $buf = '';
    open my $fh, '>', \$buf or die "Cannot open memory fh: $!";
    my $res = $code->($fh);
    close $fh;
    return ($res, $buf);
}

# =============================================================================
# Seam 1: parse_cli_args(\@ARGV)
# =============================================================================
subtest 'parse_cli_args helper' => sub {
    ok(defined &parse_cli_args, 'parse_cli_args function is defined');

    # 1.1 --session <id>
    my $opts1 = parse_cli_args(['--session', '1128-abcd']);
    is_deeply($opts1, { session => '1128-abcd' }, '--session <id> parsed correctly');

    # 1.2 --session=<id>
    my $opts2 = parse_cli_args(['--session=1128-ef01']);
    is_deeply($opts2, { session => '1128-ef01' }, '--session=<id> parsed correctly');

    # 1.3 --session without argument (at end)
    my $opts3 = parse_cli_args(['--session']);
    is($opts3->{session}, '', '--session at end yields empty session string');

    # 1.4 --session followed by another option
    my $opts4 = parse_cli_args(['--session', '--other']);
    is($opts4->{session}, '', '--session followed by another flag yields empty session string');

    # 1.5 No options passed
    my $opts5 = parse_cli_args([]);
    is_deeply($opts5, {}, 'Empty args list returns empty options hash');

    # 1.6 Additional arguments around --session
    my $opts6 = parse_cli_args(['--foo', 'bar', '--session=1128-test', 'baz']);
    is($opts6->{session}, '1128-test', '--session=<id> extracted amidst other arguments');
};

# =============================================================================
# Seam 2: init_startup_session(\%opts, $err_fh, $out_fh)
# =============================================================================
subtest 'init_startup_session unit logic' => sub {
    ok(defined &init_startup_session, 'init_startup_session function is defined');

    # Seed test sessions in $sessions_dir
    my $s1 = {
        version    => 1,
        id         => '1128-aaaa',
        title      => 'Session Alpha',
        created_at => 1700000000,
        updated_at => 1700000100,
        cwd        => '/test/path',
        messages   => [
            { role => 'user', content => 'Hello alpha' },
            { role => 'assistant', content => 'Reply alpha' },
        ],
    };
    my $s2 = {
        version    => 1,
        id         => '1128-bbbb',
        title      => 'Session Beta',
        created_at => 1700000200,
        updated_at => 1700000300,
        cwd        => '/test/path',
        messages   => [
            { role => 'user', content => 'Hello beta' },
        ],
    };
    my $s3 = {
        version    => 1,
        id         => '1128-bccc',
        title      => 'Session Beta Two',
        created_at => 1700000400,
        updated_at => 1700000500,
        cwd        => '/test/path',
        messages   => [
            { role => 'user', content => 'Hello beta two' },
        ],
    };
    save_session($s1, $sessions_dir);
    save_session($s2, $sessions_dir);
    save_session($s3, $sessions_dir);

    # 2.1 Valid exact ID resumes session
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '1128-aaaa' }, $efh);
        close $efh;
        is($ret, 1, 'init_startup_session returns 1 on exact valid ID');
        is($err_buf, '', 'No error printed to err_fh');
        is($CURRENT_SESSION->{id}, '1128-aaaa', '$CURRENT_SESSION set to loaded session');
        is($CURRENT_SESSION->{title}, 'Session Alpha', 'Session title preserved');
    }

    # 2.2 Valid prefix ID resumes target session
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '1128-a' }, $efh);
        close $efh;
        is($ret, 1, 'init_startup_session returns 1 on unique prefix ID');
        is($err_buf, '', 'No error printed to err_fh');
        is($CURRENT_SESSION->{id}, '1128-aaaa', '$CURRENT_SESSION resolved to 1128-aaaa');
    }

    # 2.3 Non-existent ID fails with error
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '9999-dead' }, $efh);
        close $efh;
        is($ret, 0, 'init_startup_session returns 0 on non-existent ID');
        like($err_buf, qr/Session '9999-dead' not found\./, 'Error message indicates session not found');
    }

    # 2.4 Invalid ID format (path traversal attempt) fails
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '../../etc/passwd' }, $efh);
        close $efh;
        is($ret, 0, 'init_startup_session returns 0 on path traversal ID');
        like($err_buf, qr/Invalid session ID/, 'Error message warns about invalid session ID');
    }

    # 2.5 Ambiguous prefix fails and lists matches
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '1128-b' }, $efh);
        close $efh;
        is($ret, 0, 'init_startup_session returns 0 on ambiguous prefix');
        like($err_buf, qr/Ambiguous session ID prefix '1128-b'/, 'Error message notes ambiguous prefix');
        like($err_buf, qr/1128-bbbb/, 'Error lists first ambiguous match');
        like($err_buf, qr/1128-bccc/, 'Error lists second ambiguous match');
    }

    # 2.6 Missing / empty session ID argument fails
    {
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({ session => '' }, $efh);
        close $efh;
        is($ret, 0, 'init_startup_session returns 0 on empty session argument');
        like($err_buf, qr/No session ID provided|requires a session ID/i, 'Error message notes missing ID');
    }

    # 2.7 No --session flag initializes fresh session
    {
        undef $CURRENT_SESSION;
        my $err_buf = '';
        open my $efh, '>', \$err_buf;
        my $ret = init_startup_session({}, $efh);
        close $efh;
        is($ret, 1, 'init_startup_session returns 1 with no session flag');
        is($err_buf, '', 'No error printed');
        ok(defined $CURRENT_SESSION && defined $CURRENT_SESSION->{id}, 'A fresh session was created');
        is(scalar(@{ $CURRENT_SESSION->{messages} }), 0, 'Fresh session has 0 messages');
    }
};

# =============================================================================
# Seam 3: Subprocess E2E testing of code-agent.pl with CLI flags
# =============================================================================
subtest 'Subprocess execution with --session' => sub {
    my $script = "$root_dir/code-agent.pl";
    my $perl = $^X;

    # 3.1 Valid exact ID resumes session and prints resume summary banner
    {
        my $cmd = qq{printf "exit\\n" | } .
                  qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session 1128-aaaa 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'Process exited cleanly with status 0');
        like($output, qr/Resumed Session:\s*1128-aaaa/i, 'Resume summary contains session ID');
        like($output, qr/Session Alpha/i, 'Resume summary contains session title');
    }

    # 3.2 Valid --session=<id> with prefix
    {
        my $cmd = qq{printf "exit\\n" | } .
                  qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session=1128-a 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, 'Process exited cleanly with status 0 using --session=<prefix>');
        like($output, qr/Resumed Session:\s*1128-aaaa/i, 'Resolved and resumed 1128-aaaa');
    }

    # 3.3 Non-existent session exits with status 1 and error message on STDERR
    {
        my $cmd = qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session 9999-dead 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 1, 'Non-existent session causes process to exit with status 1');
        like($output, qr/Session '9999-dead' not found\./, 'Output prints session not found error');
    }

    # 3.4 Missing session argument exits with status 1
    {
        my $cmd = qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 1, 'Missing session argument causes process to exit with status 1');
        like($output, qr/No session ID provided|requires a session ID/i, 'Output prints error for missing session ID');
    }

    # 3.5 Path traversal attempt exits with status 1
    {
        my $cmd = qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session ../../etc 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 1, 'Invalid session ID format exits with status 1');
        like($output, qr/Invalid session ID/, 'Output warns about invalid ID');
    }

    # 3.6 Ambiguous prefix exits with status 1
    {
        my $cmd = qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSIONS_DIR="$sessions_dir" } .
                  qq{$perl "$script" --session 1128-b 2>&1};
        my $output = `$cmd`;
        my $exit_code = $? >> 8;
        is($exit_code, 1, 'Ambiguous session ID prefix exits with status 1');
        like($output, qr/Ambiguous session ID prefix/, 'Output warns about ambiguous prefix');
    }
};

# =============================================================================
# Seam 4: Wrapper scripts argument forwarding
# =============================================================================
subtest 'Wrapper scripts argument forwarding' => sub {
    my $install_sh = File::Spec->catfile($root_dir, 'Install.command');
    my $modern_sh  = File::Spec->catfile($root_dir, 'modern-install.command');

    # 4.1 Shell syntax validity (bash -n)
    my $out_inst = `bash -n "$install_sh" 2>&1`;
    is($? >> 8, 0, 'Install.command passes bash -n syntax check')
        or diag("bash -n Install.command failed:\n$out_inst");

    my $out_mod = `bash -n "$modern_sh" 2>&1`;
    is($? >> 8, 0, 'modern-install.command passes bash -n syntax check')
        or diag("bash -n modern-install.command failed:\n$out_mod");

    # 4.2 Install.command generates wrapper script that forwards "$@"
    open my $ifh, '<', $install_sh or die "Cannot read $install_sh: $!";
    my $install_content = do { local $/; <$ifh> };
    close $ifh;

    like($install_content, qr/exec perl (?:["']?\$AGENT_SCRIPT["']?|\$BUILD_DIR\/code-agent\.pl)\s+["']?\\\$@["']?/,
        'Install.command wrapper generation includes "\\$@" to forward arguments');

    # 4.3 modern-install.command generates wrapper script that forwards "$@"
    open my $mfh, '<', $modern_sh or die "Cannot read $modern_sh: $!";
    my $modern_content = do { local $/; <$mfh> };
    close $mfh;

    like($modern_content, qr/exec perl (?:["']?\$AGENT_SCRIPT["']?|\$BUILD_DIR\/code-agent\.pl)\s+["']?\\\$@["']?/,
        'modern-install.command wrapper generation includes "\\$@" to forward arguments');
};

done_testing();
