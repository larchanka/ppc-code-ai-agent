#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname basename);
use File::Spec;
use File::Path qw(mkpath rmtree);
use Cwd qw(abs_path getcwd);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

# Build if needed and require
system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";
our $CURRENT_SESSION;

# Setup temporary test sessions directory
my $tmp_dir = File::Spec->catdir($root_dir, 't', 'tmp_sessions_menu_' . $$);
rmtree($tmp_dir) if -d $tmp_dir;
mkpath($tmp_dir, 0, 0700);
$ENV{CLAUDE_SESSIONS_DIR} = $tmp_dir;

# Helper to create a pipe with given data written into it
sub make_input_pipe {
    my ($data) = @_;
    pipe(my $reader, my $writer) or die "Cannot create pipe: $!";
    if (defined $data && length($data) > 0) {
        syswrite($writer, $data);
    }
    close $writer;
    return $reader;
}

# Ensure cleanup on finish
END {
    rmtree($tmp_dir) if defined $tmp_dir && -d $tmp_dir;
}

# ==================================================================
# 1. get_recent_sessions() filtering and limits
# ==================================================================
subtest "get_recent_sessions helper" => sub {
    my $current_cwd = getcwd();
    my $other_cwd = File::Spec->catdir($root_dir, 'other_dir');

    # Seed 4 sessions directly to have precise, instant updated_at timestamps
    my $session1 = {
        version    => 1,
        id         => "1128-0001",
        title      => "Session Current 1",
        cwd        => $current_cwd,
        created_at => 1732750000,
        updated_at => 1732750100,
        messages   => [{ role => 'user', content => 'First' }],
        stats      => {},
    };
    my $session2 = {
        version    => 1,
        id         => "1128-0002",
        title      => "Session Other 1",
        cwd        => $other_cwd,
        created_at => 1732750010,
        updated_at => 1732750200,
        messages   => [{ role => 'user', content => 'Second' }, { role => 'assistant', content => 'Resp' }],
        stats      => {},
    };
    my $session3 = {
        version    => 1,
        id         => "1128-0003",
        title      => "Session Current 2",
        cwd        => $current_cwd,
        created_at => 1732750020,
        updated_at => 1732750300,
        messages   => [{ role => 'user', content => 'Third' }],
        stats      => {},
    };
    my $session4 = {
        version    => 1,
        id         => "1128-0004",
        title      => "Session Other 2",
        cwd        => $other_cwd,
        created_at => 1732750030,
        updated_at => 1732750400,
        messages   => [{ role => 'user', content => 'Fourth' }],
        stats      => {},
    };

    atomic_write_file(File::Spec->catfile($tmp_dir, "$session1->{id}.json"), MiniJSON::encode($session1));
    atomic_write_file(File::Spec->catfile($tmp_dir, "$session2->{id}.json"), MiniJSON::encode($session2));
    atomic_write_file(File::Spec->catfile($tmp_dir, "$session3->{id}.json"), MiniJSON::encode($session3));
    atomic_write_file(File::Spec->catfile($tmp_dir, "$session4->{id}.json"), MiniJSON::encode($session4));
    rebuild_sessions_index($tmp_dir);

    # Test filtering by current cwd (default when undef or not specified)
    my $recent_cwd = get_recent_sessions();
    is(scalar(@$recent_cwd), 2, "get_recent_sessions() defaults to current cwd (2 sessions)");
    is($recent_cwd->[0]{id}, "1128-0003", "most recently updated in cwd is first");
    is($recent_cwd->[1]{id}, "1128-0001", "older updated in cwd is second");

    # Test filtering with explicit 'all'
    my $recent_all = get_recent_sessions('all');
    is(scalar(@$recent_all), 4, "get_recent_sessions('all') returns all 4 sessions");
    is($recent_all->[0]{id}, "1128-0004", "most recently updated across all is first");
    is($recent_all->[1]{id}, "1128-0003", "second most recently updated is 1128-0003");

    # Test limit parameter
    my $limited = get_recent_sessions('all', 2);
    is(scalar(@$limited), 2, "limit parameter restricts to 2 entries");
    is($limited->[0]{id}, "1128-0004", "first entry matches");
    is($limited->[1]{id}, "1128-0003", "second entry matches");

    # Test filtering with custom cwd
    my $custom = get_recent_sessions($other_cwd);
    is(scalar(@$custom), 2, "filters by custom cwd");
    is($custom->[0]{id}, "1128-0004", "custom cwd most recent");
    is($custom->[1]{id}, "1128-0002", "custom cwd second recent");

    # Test path normalization with trailing slash
    my $trailing_slash_cwd = $other_cwd . '/';
    my $custom_trailing = get_recent_sessions($trailing_slash_cwd);
    is(scalar(@$custom_trailing), 2, "filters by custom cwd even with trailing slash");
};

# ==================================================================
# 2. Non-TTY Menu Selection
# ==================================================================
subtest "Non-TTY menu selection" => sub {
    local $main::FORCE_RAW = 0;
    my $sessions = get_recent_sessions('all');

    # Selection by number 1
    {
        my $in = make_input_pipe("1\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, '1128-0003', 1, $in, $out, 'all');
        is($selected, '1128-0004', "selected item 1 by number");
        like($captured, qr/All recent sessions:/, "header displayed for all mode");
        like($captured, qr/\[1128-0004\]/, "contains session id");
        like($captured, qr/\*/, "indicates current session with asterisk");
    }

    # Selection by exact ID
    {
        my $in = make_input_pipe("1128-0002\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, undef, 0, $in, $out, 'myrepo');
        is($selected, '1128-0002', "selected by exact ID");
        like($captured, qr/Recent sessions \(myrepo\):/, "header displayed for cwd mode");
    }

    # Selection by unique prefix
    {
        my $in = make_input_pipe("1128-0001\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, undef, 0, $in, $out, 'myrepo');
        is($selected, '1128-0001', "selected by ID prefix");
    }

    # Cancellation with empty Enter
    {
        my $in = make_input_pipe("\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, undef, 0, $in, $out, 'myrepo');
        is($selected, undef, "empty input cancels (undef)");
    }

    # Cancellation with 'q'
    {
        my $in = make_input_pipe("q\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, undef, 0, $in, $out, 'myrepo');
        is($selected, undef, "'q' cancels (undef)");
    }

    # Out of range index returns undef
    {
        my $in = make_input_pipe("99\n");
        open my $out, '>', \my $captured;
        my $selected = select_session_nontty($sessions, undef, 0, $in, $out, 'myrepo');
        is($selected, undef, "out-of-range number returns undef");
    }

    # Edge cases: undef / empty array returns undef
    is(select_session_nontty(undef), undef, "undef sessions returns undef");
    is(select_session_nontty([]), undef, "empty sessions returns undef");
    is(select_session_interactive(undef), undef, "undef sessions interactive returns undef");
    is(select_session_interactive([]), undef, "empty sessions interactive returns undef");
};

# ==================================================================
# 3. Interactive Raw Mode Menu Navigation
# ==================================================================
subtest "Interactive raw mode navigation" => sub {
    local $main::FORCE_RAW = 1;
    my $sessions = get_recent_sessions('all');

    # Immediate Enter confirms first item
    {
        my $in = make_input_pipe("\r");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, '1128-0004', "immediate Enter selects first session");
    }

    # Down arrow then Enter selects second item
    {
        my $in = make_input_pipe("\x1b[B\r");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, '1128-0003', "Down arrow selects second session");
    }

    # 'j' key (vim down) then Enter selects second item
    {
        my $in = make_input_pipe("j\r");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, '1128-0003', "'j' key navigates down");
    }

    # 'k' key (vim up) after 'j' selects first item
    {
        my $in = make_input_pipe("jk\r");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, '1128-0004', "'k' key navigates up");
    }

    # 'q' key cancels
    {
        my $in = make_input_pipe("q");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, undef, "'q' key cancels in raw mode");
    }

    # Esc key cancels
    {
        my $in = make_input_pipe("\x1b");
        open my $out, '>', \my $captured;
        my $selected = select_session_interactive($sessions, undef, 1, $in, $out, 'all');
        is($selected, undef, "Esc key cancels in raw mode");
    }
};

# ==================================================================
# 4. Empty session list handling
# ==================================================================
subtest "Empty session list handling" => sub {
    # Create empty dir
    my $empty_dir = File::Spec->catdir($root_dir, 't', 'tmp_empty_sessions_' . $$);
    rmtree($empty_dir) if -d $empty_dir;
    mkpath($empty_dir, 0, 0700);
    local $ENV{CLAUDE_SESSIONS_DIR} = $empty_dir;

    # /sessions in directory with no sessions
    {
        open my $out, '>', \my $captured;
        handle_sessions_command('', \*STDIN, $out);
        like($captured, qr/No saved sessions found for this directory\. Use \/sessions all to see sessions from all directories\./,
            "friendly message for empty directory sessions");
    }

    # /sessions all when no sessions exist anywhere
    {
        open my $out, '>', \my $captured;
        handle_sessions_command('all', \*STDIN, $out);
        like($captured, qr/No saved sessions found\./,
            "friendly message for empty all sessions");
    }

    rmtree($empty_dir) if -d $empty_dir;
};

# ==================================================================
# 5. Full handle_sessions_command with switching
# ==================================================================
subtest "handle_sessions_command switching" => sub {
    local $main::FORCE_RAW = 0;
    local $ENV{CLAUDE_SESSIONS_DIR} = $tmp_dir;

    # Initialize current session to something else
    init_session();
    my $orig_id = $CURRENT_SESSION->{id};

    # Input '1' in non-TTY mode to select the first session from current cwd (1128-0003)
    my $in = make_input_pipe("1\n");
    open my $out, '>', \my $captured;
    handle_sessions_command('', $in, $out);

    is($CURRENT_SESSION->{id}, "1128-0003", "switched to session 1128-0003");
    like($captured, qr/=== Resumed Session: 1128-0003 ===/, "displayed resume summary");

    # Test invalid argument shows usage
    {
        open my $out2, '>', \my $captured2;
        handle_sessions_command('invalid_arg', \*STDIN, $out2);
        like($captured2, qr/Usage: \/sessions \[all\]/, "invalid argument prints usage");
    }
};

done_testing();
