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

my $temp_dir = tempdir(CLEANUP => 1);
$ENV{CLAUDE_SESSIONS_DIR} = $temp_dir;

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our $CURRENT_SESSION;
our $PROVIDER;
our $MODEL;

sub capture_output {
    my ($code) = @_;
    my $buf = '';
    open my $fh, '>', \$buf or die "Cannot open memory fh: $!";
    $code->($fh);
    close $fh;
    return $buf;
}

# -----------------------------------------------------------------------------
# Seam 1: format_session_resume_summary
# -----------------------------------------------------------------------------
subtest 'format_session_resume_summary' => sub {
    my $session = {
        id         => '1128-abcd',
        title      => 'Fix Login Bug',
        created_at => 1700000000,
        updated_at => 1700000500,
        provider   => 'anthropic',
        model      => 'claude-3-5-sonnet',
        messages   => [
            { role => 'user', content => "Hello world first message\nLine 2" },
            { role => 'assistant', content => [ { type => 'text', text => "First reply here\nLine 2" } ] },
            { role => 'user', content => "Second question from user with longer text that should be snippeted" },
            { role => 'assistant', content => [ { type => 'text', text => "Second response from assistant with multiple lines\nSecond line\nThird line" } ] },
        ],
    };

    my $out = capture_output(sub {
        my ($fh) = @_;
        format_session_resume_summary($session, $fh);
    });

    like($out, qr/1128-abcd/, 'summary includes session id');
    like($out, qr/Fix Login Bug/, 'summary includes title');
    like($out, qr/Messages?:\s+4/i, 'summary includes message count');
    like($out, qr/Second question/i, 'summary includes recent user snippet');
    like($out, qr/Second response/i, 'summary includes recent assistant snippet');
    like($out, qr/Active model\/provider stays as current|active model|stay/i, 'summary notes active provider/model unchanged');
};

subtest 'format_session_resume_summary with tool use sequence' => sub {
    my $session_tool_use = {
        id         => '1128-tool',
        title      => 'Investigate Bug',
        created_at => 1700000000,
        updated_at => 1700000500,
        provider   => 'anthropic',
        model      => 'claude-3-5-sonnet',
        messages   => [
            # User turn
            { role => 'user', content => "Please check the log file" },
            # Assistant tool_use only (no text block)
            { role => 'assistant', content => [ { type => 'tool_use', id => 'call_1', name => 'read_file', input => { path => 'log.txt' } } ] },
            # User tool_result
            { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'call_1', content => 'Error on line 42' } ] },
            # Assistant final response
            { role => 'assistant', content => [ { type => 'text', text => "I found the error on line 42 and fixed it." } ] },
        ],
    };

    my $out = capture_output(sub {
        my ($fh) = @_;
        format_session_resume_summary($session_tool_use, $fh);
    });

    like($out, qr/Please check the log file/, 'summary includes user request');
    like($out, qr/I found the error on line 42/, 'summary captures final assistant reply after tool use');
};

subtest 'format_session_stats displays session title when present' => sub {
    my $session_with_title = {
        id         => '1128-title-test',
        title      => 'Fix Database Locks',
        created_at => time() - 60,
        provider   => 'anthropic',
        model      => 'claude-3-5-sonnet',
        messages   => [],
        stats      => _default_session_stats(),
    };

    my $out_titled = format_session_stats($session_with_title);
    like($out_titled, qr/Title:\s+Fix Database Locks/, 'stats header displays title when present');

    my $session_without_title = {
        id         => '1128-no-title',
        created_at => time() - 60,
        provider   => 'anthropic',
        model      => 'claude-3-5-sonnet',
        messages   => [],
        stats      => _default_session_stats(),
    };
    my $out_untitled = format_session_stats($session_without_title);
    unlike($out_untitled, qr/Title:/, 'stats header omits title when empty or missing');
};

# -----------------------------------------------------------------------------
# Seam 2: switch_to_session & handle_session_command
# -----------------------------------------------------------------------------
subtest 'switch_to_session' => sub {
    # Prepare 2 saved sessions in $temp_dir
    my $s1 = {
        id         => '1128-aaaa',
        title      => 'Session Alpha',
        created_at => time() - 100,
        updated_at => time() - 100,
        provider   => 'gemini',
        model      => 'gemini-2.0-flash',
        messages   => [
            { role => 'user', content => 'Alpha request' },
            { role => 'assistant', content => [ { type => 'text', text => 'Alpha reply' } ] },
        ],
    };
    my $s2 = {
        id         => '1128-bbbb',
        title      => 'Session Beta',
        created_at => time() - 50,
        updated_at => time() - 50,
        provider   => 'openai',
        model      => 'gpt-4o',
        messages   => [
            { role => 'user', content => 'Beta request' },
            { role => 'assistant', content => [ { type => 'text', text => 'Beta reply' } ] },
        ],
    };
    save_session($s1, $temp_dir);
    save_session($s2, $temp_dir);

    # Set current session dirty (has messages)
    $PROVIDER = 'anthropic';
    $MODEL = 'claude-3-5-sonnet';
    my $cur = init_session('1128-cccc');
    push @{ $cur->{messages} }, { role => 'user', content => 'Current dirty message' };
    push @{ $cur->{messages} }, { role => 'assistant', content => [ { type => 'text', text => 'Current reply' } ] };

    # 1. Switch to s1 by prefix "1128-aa"
    my $out1 = capture_output(sub {
        my ($fh) = @_;
        switch_to_session('1128-aa', $fh);
    });
    is($CURRENT_SESSION->{id}, '1128-aaaa', 'switched to 1128-aaaa via prefix');
    is($PROVIDER, 'anthropic', 'provider preserved as current');
    is($MODEL, 'claude-3-5-sonnet', 'model preserved as current');
    like($out1, qr/Session Alpha/, 'summary printed for switched session');

    # Verify previous session was auto-saved
    my $saved_cur = load_session('1128-cccc', $temp_dir);
    ok(defined $saved_cur, 'previous dirty session was auto-saved before switch');
    is(scalar(@{ $saved_cur->{messages} }), 2, 'auto-saved session has both messages');

    # 2. Switch to current session -> no-op notice
    my $out_noop = capture_output(sub {
        my ($fh) = @_;
        switch_to_session('1128-aaaa', $fh);
    });
    like($out_noop, qr/already.*active|already.*current/i, 'notice when switching to current session');
    is($CURRENT_SESSION->{id}, '1128-aaaa', 'still on 1128-aaaa');

    # 3. Switch to non-existent session
    my $out_nf = capture_output(sub {
        my ($fh) = @_;
        switch_to_session('nonexistent', $fh);
    });
    like($out_nf, qr/not found/i, 'error printed for non-existent session');
    is($CURRENT_SESSION->{id}, '1128-aaaa', 'still on 1128-aaaa after error');

    # 4. Switch to ambiguous prefix
    my $out_amb = capture_output(sub {
        my ($fh) = @_;
        switch_to_session('1128-', $fh);
    });
    like($out_amb, qr/ambiguous/i, 'error printed for ambiguous prefix');
    is($CURRENT_SESSION->{id}, '1128-aaaa', 'still on 1128-aaaa after ambiguity');

    # 5. Invalid session id (e.g. path traversal)
    my $out_inv = capture_output(sub {
        my ($fh) = @_;
        switch_to_session('../bad', $fh);
    });
    like($out_inv, qr/invalid/i, 'error printed for invalid session id');
    is($CURRENT_SESSION->{id}, '1128-aaaa', 'still on 1128-aaaa after invalid id');
};

# -----------------------------------------------------------------------------
# Seam 3: delete_session_command
# -----------------------------------------------------------------------------
subtest 'delete_session_command' => sub {
    my $s_del = {
        id         => '1128-dddd',
        title      => 'Session To Delete',
        created_at => time(),
        updated_at => time(),
        messages   => [
            { role => 'user', content => 'Delete me' },
        ],
    };
    save_session($s_del, $temp_dir);
    ok(-f File::Spec->catfile($temp_dir, '1128-dddd.json'), 'file exists before delete');

    # 1. Delete inactive session
    my $out_del1 = capture_output(sub {
        my ($fh) = @_;
        delete_session_command('1128-dddd', $fh);
    });
    ok(!-f File::Spec->catfile($temp_dir, '1128-dddd.json'), 'file removed after delete');
    like($out_del1, qr/deleted.*1128-dddd/i, 'confirmation message printed');

    # 2. Delete active session
    my $s_active = {
        id         => '1128-eeee',
        title      => 'Active To Delete',
        created_at => time(),
        updated_at => time(),
        messages   => [
            { role => 'user', content => 'Active msg' },
        ],
    };
    save_session($s_active, $temp_dir);
    $CURRENT_SESSION = $s_active;

    my $out_del_act = capture_output(sub {
        my ($fh) = @_;
        delete_session_command('1128-eeee', $fh);
    });
    ok(!-f File::Spec->catfile($temp_dir, '1128-eeee.json'), 'active session file removed');
    isnt($CURRENT_SESSION->{id}, '1128-eeee', 'active session reset to new id');
    is(scalar(@{ $CURRENT_SESSION->{messages} }), 0, 'new active session is empty');
    like($out_del_act, qr/deleted.*1128-eeee/i, 'confirmation message printed');
    like($out_del_act, qr/new.*session|started.*fresh/i, 'notice about new session started');

    # 3. Delete non-existent session
    my $out_del_nf = capture_output(sub {
        my ($fh) = @_;
        delete_session_command('nonexistent', $fh);
    });
    like($out_del_nf, qr/not found/i, 'error when deleting non-existent session');
};

# -----------------------------------------------------------------------------
# Seam 4: handle_session_command (dispatcher)
# -----------------------------------------------------------------------------
subtest 'handle_session_command dispatcher' => sub {
    # 1. No arguments -> usage help
    my $out_help = capture_output(sub {
        my ($fh) = @_;
        handle_session_command('', $fh);
    });
    like($out_help, qr/\/session <id>/i, 'usage shows /session <id>');
    like($out_help, qr/\/session delete/i, 'usage shows /session delete');
    like($out_help, qr/\/sessions/i, 'usage references /sessions for list');

    # 2. Dispatch to delete
    my $s_disp_del = {
        id         => '1128-ffff',
        title      => 'Dispatcher Delete',
        created_at => time(),
        updated_at => time(),
        messages   => [ { role => 'user', content => 'Hi' } ],
    };
    save_session($s_disp_del, $temp_dir);
    my $out_disp_del = capture_output(sub {
        my ($fh) = @_;
        handle_session_command('delete 1128-ffff', $fh);
    });
    like($out_disp_del, qr/deleted.*1128-ffff/i, 'dispatched delete successfully');

    # 3. Dispatch to switch
    my $s_disp_sw = {
        id         => '1128-1111',
        title      => 'Dispatcher Switch',
        created_at => time(),
        updated_at => time(),
        messages   => [ { role => 'user', content => 'Hi' } ],
    };
    save_session($s_disp_sw, $temp_dir);
    my $out_disp_sw = capture_output(sub {
        my ($fh) = @_;
        handle_session_command('1128-1111', $fh);
    });
    is($CURRENT_SESSION->{id}, '1128-1111', 'dispatched switch successfully');
};

# -----------------------------------------------------------------------------
# Seam 5: help command updates
# -----------------------------------------------------------------------------
subtest 'show_help documentation' => sub {
    my $help = capture_output(sub {
        my ($fh) = @_;
        show_help($fh);
    });
    like($help, qr/\/session\b/, 'show_help documents /session');
    like($help, qr/\/sessions\b/, 'show_help documents /sessions');
};

done_testing();
