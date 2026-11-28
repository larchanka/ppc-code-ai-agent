#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ------------------------------------------------------------------
# Test group 1: get_sessions_dir & get_max_saved_sessions
# ------------------------------------------------------------------
{
    # CLAUDE_SESSIONS_DIR override
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{CLAUDE_SESSIONS_DIR} = "$tmp/custom_sessions";
    is(get_sessions_dir(), "$tmp/custom_sessions", "get_sessions_dir honors CLAUDE_SESSIONS_DIR");

    # Default location under HOME
    delete $ENV{CLAUDE_SESSIONS_DIR};
    local $ENV{HOME} = $tmp;
    my $expected_default = File::Spec->catdir($tmp, '.code-agent', 'sessions');
    is(get_sessions_dir(), $expected_default, "get_sessions_dir defaults to ~/.code-agent/sessions");

    # Max saved sessions default
    delete $ENV{CLAUDE_MAX_SESSIONS};
    is(get_max_saved_sessions(), 100, "get_max_saved_sessions defaults to 100");

    # Max saved sessions override
    local $ENV{CLAUDE_MAX_SESSIONS} = "25";
    is(get_max_saved_sessions(), 25, "get_max_saved_sessions honors CLAUDE_MAX_SESSIONS");

    local $ENV{CLAUDE_MAX_SESSIONS} = "invalid";
    is(get_max_saved_sessions(), 100, "get_max_saved_sessions falls back to 100 on non-numeric value");

    local $ENV{CLAUDE_MAX_SESSIONS} = "0";
    is(get_max_saved_sessions(), 100, "get_max_saved_sessions falls back to 100 on 0 value");
}

# ------------------------------------------------------------------
# Test group 2: is_valid_session_id
# ------------------------------------------------------------------
{
    ok(is_valid_session_id("1128-a3f9"), "valid short session id");
    ok(is_valid_session_id("session-20261128-123456-001"), "valid legacy session id");
    ok(is_valid_session_id("my_session-42"), "valid session id with underscore and dash");

    ok(!is_valid_session_id(""), "rejects empty string");
    ok(!is_valid_session_id(undef), "rejects undef");
    ok(!is_valid_session_id("../traversal"), "rejects path traversal ..");
    ok(!is_valid_session_id("dir/session"), "rejects forward slash");
    ok(!is_valid_session_id("dir\\session"), "rejects backslash");
    ok(!is_valid_session_id("session name"), "rejects spaces");
    ok(!is_valid_session_id("session;rm"), "rejects shell metacharacters");
    ok(!is_valid_session_id("session\0bad"), "rejects null byte");
    ok(!is_valid_session_id("index"), "rejects reserved id 'index'");
    ok(!is_valid_session_id("Index"), "rejects reserved id 'Index' case-insensitively");
    ok(!is_valid_session_id("INDEX"), "rejects reserved id 'INDEX' case-insensitively");
}

# ------------------------------------------------------------------
# Test group 3: atomic_write_file permissions and UTF-8
# ------------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    my $nested_file = File::Spec->catfile($tmp, 'sub', 'dir', 'test.json');
    my $unicode_content = "{\"title\":\"Тест UTF-8 日本語 \x{2603}\"}";

    my $ok = atomic_write_file($nested_file, $unicode_content, 0600);
    ok($ok, "atomic_write_file creates nested directory and writes file");
    ok(-f $nested_file, "nested file exists");

    my $mode = (stat($nested_file))[2] & 0777;
    is(sprintf("%04o", $mode), "0600", "file written with 0600 permissions");

    open(my $rfh, '<:encoding(UTF-8)', $nested_file) or die "Cannot open $nested_file: $!";
    my $read_content = do { local $/; <$rfh> };
    close $rfh;
    is($read_content, $unicode_content, "UTF-8 content preserved roundtrip");

    # Unwritable directory should fail gracefully
    my $bad_path = "/nonexistent_parent_dir_cannot_create_$$/file.json";
    my $fail_ok = eval { atomic_write_file($bad_path, "{}", 0600) };
    is($fail_ok, 0, "atomic_write_file returns 0 on unwritable path without dying");

    # Undefined or empty path returns 0
    is(atomic_write_file(undef, "{}"), 0, "atomic_write_file returns 0 on undef path");
    is(atomic_write_file("", "{}"), 0, "atomic_write_file returns 0 on empty path");
}

# ------------------------------------------------------------------
# Test group 4: save_session, load_session, delete_session
# ------------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{CLAUDE_SESSIONS_DIR} = $tmp;

    # 4a. Empty session is not saved
    my $empty_session = {
        id       => "1128-0001",
        messages => [],
    };
    is(save_session($empty_session), 0, "save_session ignores empty session (0 messages)");
    ok(!-f File::Spec->catfile($tmp, "1128-0001.json"), "empty session file not written");

    # 4b. Invalid session id is not saved
    my $invalid_session = {
        id       => "../bad_id",
        messages => [ { role => 'user', content => 'hi' } ],
    };
    is(save_session($invalid_session), 0, "save_session rejects invalid session id");

    my $index_reserved_session = {
        id       => "index",
        messages => [ { role => 'user', content => 'hi' } ],
    };
    is(save_session($index_reserved_session), 0, "save_session rejects reserved id 'index'");
    is(delete_session("index"), 0, "delete_session rejects reserved id 'index'");

    # 4c. Non-empty session saved with Schema v1
    my $session1 = {
        id         => "1128-a1b2",
        title      => "Test Session One",
        cwd        => "/mock/project/path",
        created_at => 1732750000,
        provider   => "anthropic",
        model      => "claude-sonnet-4-5-20250929",
        messages   => [
            { role => 'user', content => "Hello, agent!" },
            { role => 'assistant', content => [ { type => 'text', text => "Hello human!" } ] },
        ],
        stats      => {
            api_calls => 1,
            input_tokens => 10,
            output_tokens => 5,
        },
    };

    my $save_ok = save_session($session1);
    ok($save_ok, "save_session succeeds for non-empty session");
    my $sess1_file = File::Spec->catfile($tmp, "1128-a1b2.json");
    ok(-f $sess1_file, "session file written to disk");

    # File permissions check
    my $mode = (stat($sess1_file))[2] & 0777;
    is(sprintf("%04o", $mode), "0600", "session file has 0600 permissions");

    # Load session check
    my $loaded1 = load_session("1128-a1b2");
    ok(defined $loaded1, "load_session returns loaded data");
    is($loaded1->{version}, 1, "session schema version is 1");
    is($loaded1->{id}, "1128-a1b2", "session id matches");
    is($loaded1->{title}, "Test Session One", "title matches");
    is($loaded1->{cwd}, "/mock/project/path", "cwd matches");
    is($loaded1->{provider}, "anthropic", "provider matches");
    is($loaded1->{model}, "claude-sonnet-4-5-20250929", "model matches");
    is(scalar(@{ $loaded1->{messages} }), 2, "messages restored");
    is($loaded1->{stats}{api_calls}, 1, "stats restored");

    # load_session with invalid ID returns undef
    is(load_session("../1128-a1b2"), undef, "load_session rejects path traversal");
    is(load_session("nonexistent-id"), undef, "load_session returns undef for non-existent session");

    # Delete session
    my $del_ok = delete_session("1128-a1b2");
    ok($del_ok, "delete_session returns truthy");
    ok(!-f $sess1_file, "session file deleted from disk");
    is(load_session("1128-a1b2"), undef, "load_session returns undef after deletion");
}

# ------------------------------------------------------------------
# Test group 5: index.json management, rebuilding, and listing
# ------------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{CLAUDE_SESSIONS_DIR} = $tmp;

    my $s_alpha = {
        id         => "1128-aaaa",
        title      => "Alpha Session",
        cwd        => "/repo/one",
        created_at => 1000,
        messages   => [ { role => 'user', content => 'turn 1' }, { role => 'assistant', content => 'reply 1' } ],
    };
    my $s_beta = {
        id         => "1128-bbbb",
        title      => "Beta Session",
        cwd        => "/repo/two",
        created_at => 2000,
        messages   => [ { role => 'user', content => 'turn 1' } ],
    };

    save_session($s_alpha);
    sleep 1; # ensure distinct updated_at timestamps
    save_session($s_beta);

    my $idx = load_sessions_index();
    ok(defined $idx && ref($idx) eq 'HASH', "load_sessions_index returns hashref");
    is($idx->{version}, 1, "index version is 1");
    is(scalar(@{ $idx->{sessions} }), 2, "index contains 2 sessions");
    is($idx->{sessions}[0]{id}, "1128-bbbb", "most recently updated session is first");
    is($idx->{sessions}[1]{id}, "1128-aaaa", "older session is second");

    # Listing with cwd filter
    my $list_repo_one = list_sessions({ cwd => "/repo/one" });
    is(scalar(@$list_repo_one), 1, "list_sessions filters by cwd");
    is($list_repo_one->[0]{id}, "1128-aaaa", "matches correct cwd session");

    my $list_all = list_sessions();
    is(scalar(@$list_all), 2, "list_sessions without cwd returns all");

    # Rebuild index: delete index.json and ensure load_sessions_index rebuilds it
    my $index_file = File::Spec->catfile($tmp, 'index.json');
    unlink($index_file);
    ok(!-f $index_file, "index.json deleted for rebuild test");

    my $rebuilt_idx = load_sessions_index();
    ok(-f $index_file, "index.json automatically recreated on load");
    is(scalar(@{ $rebuilt_idx->{sessions} }), 2, "rebuilt index recovered both sessions");

    # Corrupt index.json auto-rebuilding
    open(my $ifh, '>', $index_file) or die "Cannot write $index_file: $!";
    print $ifh "{ corrupt json ...";
    close $ifh;

    my $recovered_idx = load_sessions_index();
    is(scalar(@{ $recovered_idx->{sessions} }), 2, "corrupt index.json automatically rebuilt from session files");

    # Corrupt session file is skipped during rebuild
    my $corrupt_sess = File::Spec->catfile($tmp, "1128-cccc.json");
    open(my $cfh, '>', $corrupt_sess) or die "Cannot write $corrupt_sess: $!";
    print $cfh "invalid json content";
    close $cfh;

    my $rebuild_skip_corrupt = rebuild_sessions_index();
    is(scalar(@{ $rebuild_skip_corrupt->{sessions} }), 2, "rebuild skips unparseable session files");
    unlink($corrupt_sess);
}

# ------------------------------------------------------------------
# Test group 6: Retention limit enforcement
# ------------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{CLAUDE_SESSIONS_DIR} = $tmp;
    local $ENV{CLAUDE_MAX_SESSIONS} = "2";

    my $s1 = { id => "1128-0001", messages => [ { role => 'user', content => 'm1' } ] };
    my $s2 = { id => "1128-0002", messages => [ { role => 'user', content => 'm2' } ] };
    my $s3 = { id => "1128-0003", messages => [ { role => 'user', content => 'm3' } ] };

    save_session($s1);
    sleep 1;
    save_session($s2);
    sleep 1;
    save_session($s3);

    my $idx = load_sessions_index();
    is(scalar(@{ $idx->{sessions} }), 2, "index capped at max 2 sessions");
    is($idx->{sessions}[0]{id}, "1128-0003", "newest session retained");
    is($idx->{sessions}[1]{id}, "1128-0002", "second newest session retained");

    ok(!-f File::Spec->catfile($tmp, "1128-0001.json"), "oldest session file unlinked by retention policy");
    ok(-f File::Spec->catfile($tmp, "1128-0002.json"), "retained session file 2 still exists");
    ok(-f File::Spec->catfile($tmp, "1128-0003.json"), "retained session file 3 still exists");
}

# ------------------------------------------------------------------
# Test group 7: resolve_session_id (exact, prefix, case-insensitive, errors)
# ------------------------------------------------------------------
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{CLAUDE_SESSIONS_DIR} = $tmp;

    my $s_foo = { id => "1128-a100", messages => [ { role => 'user', content => 'foo' } ] };
    my $s_bar = { id => "1128-a200", messages => [ { role => 'user', content => 'bar' } ] };
    my $s_baz = { id => "1128-b100", messages => [ { role => 'user', content => 'baz' } ] };

    save_session($s_foo);
    save_session($s_bar);
    save_session($s_baz);

    # Exact match
    my $r_exact = resolve_session_id("1128-a100");
    ok($r_exact->{ok}, "exact match ok");
    is($r_exact->{id}, "1128-a100", "exact match returns correct ID");

    # List context returns ($id, $err)
    my ($id_list, $err_list) = resolve_session_id("1128-a100");
    is($id_list, "1128-a100", "list context returns id on success");
    ok(!defined $err_list, "list context error is undef on success");

    # Case-insensitive exact match
    my $r_ci = resolve_session_id("1128-A100");
    ok($r_ci->{ok}, "case-insensitive exact match ok");
    is($r_ci->{id}, "1128-a100", "case-insensitive exact match returns correct ID");

    # Unique prefix match
    my $r_prefix = resolve_session_id("1128-b");
    ok($r_prefix->{ok}, "unique prefix match ok");
    is($r_prefix->{id}, "1128-b100", "unique prefix returns correct ID");

    # Ambiguous prefix match
    my $r_ambig = resolve_session_id("1128-a");
    ok(!$r_ambig->{ok}, "ambiguous prefix match fails ok=0");
    is($r_ambig->{type}, "ambiguous", "error type is ambiguous");
    is(scalar(@{ $r_ambig->{matches} }), 2, "matches contains the 2 conflicting sessions");
    like($r_ambig->{error}, qr/ambiguous/i, "error message mentions ambiguous");

    my ($id_ambig, $err_ambig) = resolve_session_id("1128-a");
    ok(!defined $id_ambig, "list context id is undef on ambiguous match");
    like($err_ambig, qr/ambiguous/i, "list context error returned on ambiguous match");

    # Not found
    my $r_nf = resolve_session_id("1128-z");
    ok(!$r_nf->{ok}, "not found returns ok=0");
    is($r_nf->{type}, "not_found", "error type is not_found");

    # Invalid ID
    my $r_inv = resolve_session_id("../escape");
    ok(!$r_inv->{ok}, "invalid id returns ok=0");
    is($r_inv->{type}, "invalid", "error type is invalid");

    my $r_index = resolve_session_id("index");
    ok(!$r_index->{ok}, "resolving reserved id 'index' returns ok=0");
    is($r_index->{type}, "invalid", "error type for reserved 'index' is invalid");
    ok(-f File::Spec->catfile($tmp, "index.json"), "index.json remains intact and uncorrupted");

    my $r_empty = resolve_session_id("");
    ok(!$r_empty->{ok}, "empty id returns ok=0");
    is($r_empty->{type}, "invalid", "empty id error type is invalid");
}

done_testing();
