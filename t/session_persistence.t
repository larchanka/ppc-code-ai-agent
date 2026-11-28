#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{CLAUDE_RETRY_DELAY} = 0;

my $tmp_test_dir = tempdir(CLEANUP => 1);

$ENV{CLAUDE_SESSIONS_DIR} = $tmp_test_dir;
$ENV{MOCK_CURL_LOG} = File::Spec->catfile($tmp_test_dir, 'mock_curl.log');
$ENV{MOCK_CURL_REQ_CHECK} = File::Spec->catfile($tmp_test_dir, 'mock_curl_req.log');

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our ($LAST_API_ELAPSED, $CURRENT_SESSION);

# ==================================================================
# 1. call_api with $opts ({ silent => 1, no_retry => 1 })
# ==================================================================
{
    # 1.1 silent => 1 preserves $LAST_API_ELAPSED and suppresses thinking output
    $LAST_API_ELAPSED = 999;
    $ENV{MOCK_CURL_RESPONSE} = '{"id":"msg_silent","type":"message"}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';
    delete $ENV{MOCK_CURL_HTTP_SEQUENCE};

    my $resp_silent = call_api("http://localhost:8080/v1/chat", [], '{"input":"silent"}', 'POST', { silent => 1 });
    is_deeply($resp_silent, { id => "msg_silent", type => "message" }, "call_api with silent => 1 returns decoded JSON");
    is($LAST_API_ELAPSED, 999, "silent => 1 preserves \$LAST_API_ELAPSED without modification");

    # 1.2 silent => 0 or omitted updates $LAST_API_ELAPSED
    my $resp_normal = call_api("http://localhost:8080/v1/chat", [], '{"input":"normal"}', 'POST');
    is_deeply($resp_normal, { id => "msg_silent", type => "message" }, "call_api without silent returns decoded JSON");
    ok(defined $LAST_API_ELAPSED && $LAST_API_ELAPSED != 999, "call_api without silent updates \$LAST_API_ELAPSED");

    # 1.3 no_retry => 1 fails immediately on retryable error without retrying
    my $count_file = File::Spec->catfile($tmp_test_dir, 'attempt_count.txt');
    $ENV{MOCK_CURL_COUNT_FILE} = $count_file;
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '500,200';
    unlink $count_file if -f $count_file;

    my $err_no_retry;
    eval {
        call_api("http://localhost:8080/v1/chat", [], '{"input":"fail"}', 'POST', { no_retry => 1 });
    };
    $err_no_retry = $@;
    like($err_no_retry, qr/API error \(HTTP 500\)/, "no_retry => 1 fails on first attempt");

    # Check attempt count from mock_curl
    my $attempts = 0;
    if (open(my $afh, '<', $count_file)) {
        my $val = <$afh>;
        $attempts = int($val) if defined $val;
        close $afh;
    }
    is($attempts, 1, "no_retry => 1 made exactly 1 attempt before dying");

    # 1.4 normal call retries and succeeds on second attempt
    unlink $count_file if -f $count_file;
    $ENV{MOCK_CURL_HTTP_SEQUENCE} = '500,200';
    $ENV{MOCK_CURL_RESPONSE} = '{"status":"recovered"}';

    my $resp_retry = eval {
        call_api("http://localhost:8080/v1/chat", [], '{"input":"retry"}', 'POST');
    };
    ok(!$@, "normal call without no_retry succeeds via retry") or diag("Error: $@");
    is_deeply($resp_retry, { status => "recovered" }, "recovered response returned");

    $attempts = 0;
    if (open(my $afh2, '<', $count_file)) {
        my $val = <$afh2>;
        $attempts = int($val) if defined $val;
        close $afh2;
    }
    is($attempts, 2, "normal call made 2 attempts before succeeding");

    delete $ENV{MOCK_CURL_COUNT_FILE};
    delete $ENV{MOCK_CURL_HTTP_SEQUENCE};
}

# ==================================================================
# 2. archive_session() auto-save
# ==================================================================
{
    my $sess = init_session();
    $sess->{id} = '0101-aa11';

    # 2.1 Empty session: archive_session returns session but does not write to disk
    my $ret_empty = archive_session($sess);
    is($ret_empty, $sess, "archive_session returns session reference");
    ok(!-f File::Spec->catfile($tmp_test_dir, '0101-aa11.json'), "archive_session does not write empty session to disk");

    # 2.2 Non-empty session: archive_session saves session to disk
    push @{ $sess->{messages} }, { role => 'user', content => 'Hello world' };
    push @{ $sess->{messages} }, { role => 'assistant', content => [{ type => 'text', text => 'Hi' }] };

    my $ret_saved = archive_session($sess);
    is($ret_saved, $sess, "archive_session returns non-empty session reference");
    my $saved_file = File::Spec->catfile($tmp_test_dir, '0101-aa11.json');
    ok(-f $saved_file, "archive_session saves non-empty session to disk ($saved_file)");

    my $raw = MiniJSON::decode(do { open(my $fh, '<', $saved_file); local $/; <$fh> });
    is($raw->{id}, '0101-aa11', "saved session has correct id");
    is(scalar(@{ $raw->{messages} }), 2, "saved session has 2 messages");

    # 2.3 archive_session(undef) when no active session returns undef
    my $ret_undef = do {
        local $CURRENT_SESSION = undef;
        archive_session(undef);
    };
    ok(!defined $ret_undef, "archive_session(undef) with no active session returns undef");
}

# ==================================================================
# 3. handle_compact_command() auto-save
# ==================================================================
{
    my $sess = init_session();
    $sess->{id} = '0101-bb22';
    my $huge_output = join("\n", map { "Line $_ of long tool output" } (1 .. 100));
    push @{ $sess->{messages} }, { role => 'user', content => 'run tool' };
    push @{ $sess->{messages} }, {
        role => 'assistant',
        content => [
            { type => 'tool_use', id => 'call_1', name => 'run_shell', input => { command => 'echo test' } }
        ]
    };
    push @{ $sess->{messages} }, {
        role => 'user',
        content => [
            { type => 'tool_result', tool_use_id => 'call_1', content => $huge_output }
        ]
    };
    # Recent turn to stay intact
    push @{ $sess->{messages} }, { role => 'user', content => 'recent turn' };
    push @{ $sess->{messages} }, { role => 'assistant', content => [{ type => 'text', text => 'done' }] };

    my $out_buf = '';
    open my $out_fh, '>', \$out_buf;
    my $stats = handle_compact_command($out_fh, $sess, keep_turns => 0, max_lines => 20);
    close $out_fh;

    ok(defined $stats && $stats->{compacted_count} > 0, "compacted_count > 0 in handle_compact_command");
    my $compact_file = File::Spec->catfile($tmp_test_dir, '0101-bb22.json');
    ok(-f $compact_file, "handle_compact_command saved compacted session to disk ($compact_file)");

    my $raw = MiniJSON::decode(do { open(my $fh, '<', $compact_file); local $/; <$fh> });
    my $tool_msg = $raw->{messages}[2];
    like($tool_msg->{content}[0]{content}, qr/\[\.\.\. \d+ lines truncated for context budget \.\.\.\]/,
         "persisted session contains truncated tool result");
}

# ==================================================================
# 4. Integration: REPL turn auto-save and exit auto-save
# ==================================================================
{
    my $perl = $^X;
    my $script = "$root_dir/code-agent.pl";
    $ENV{MOCK_CURL_RESPONSE} = '{"content":[{"type":"text","text":"I am a bot"}]}';
    $ENV{MOCK_CURL_HTTP_CODE} = '200';

    # 4.1 REPL turn completed and exit: session is saved to CLAUDE_SESSIONS_DIR
    my $repl_dir = File::Spec->catdir($tmp_test_dir, 'repl_test');
    mkdir $repl_dir or die "Cannot create $repl_dir: $!";

    my $cmd = qq{printf "Hello bot\\nexit\\n" | } .
              qq{CLAUDE_SESSIONS_DIR="$repl_dir" } .
              qq{CLAUDE_SESSION_AUTO_TITLE=0 } .
              qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
              qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
              qq{$perl $script 2>&1};
    my $out = `$cmd`;
    like($out, qr{Goodbye\.}, "REPL session exited cleanly");

    # Verify a session file was written to $repl_dir
    opendir(my $dh, $repl_dir);
    my @json_files = grep { $_ =~ /^\d{4}-[0-9a-f]{4}\.json$/ } readdir($dh);
    closedir($dh);

    is(scalar(@json_files), 1, "Exactly one session JSON file was auto-saved during conversation turn");
    if (@json_files) {
        my $saved = File::Spec->catfile($repl_dir, $json_files[0]);
        my $content = MiniJSON::decode(do { open(my $fh, '<', $saved); local $/; <$fh> });
        is(scalar(@{ $content->{messages} }), 2, "Auto-saved session contains user message and assistant response");
        is($content->{messages}[0]{content}, "Hello bot", "User message matches");
    }

    # 4.2 Immediate exit with no turns (empty session): no file is saved
    my $empty_repl_dir = File::Spec->catdir($tmp_test_dir, 'empty_repl_test');
    mkdir $empty_repl_dir or die "Cannot create $empty_repl_dir: $!";

    my $cmd_empty = qq{printf "/exit\\n" | } .
                    qq{CLAUDE_SESSIONS_DIR="$empty_repl_dir" } .
                    qq{CLAUDE_SESSION_AUTO_TITLE=0 } .
                    qq{ANTHROPIC_API_KEY="test-key" CLAUDE_PROVIDER="anthropic" } .
                    qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
                    qq{$perl $script 2>&1};
    my $out_empty = `$cmd_empty`;
    like($out_empty, qr{Goodbye\.}, "REPL exited cleanly on /exit");

    opendir(my $dh_emp, $empty_repl_dir);
    my @emp_files = grep { $_ =~ /\.json$/ } readdir($dh_emp);
    closedir($dh_emp);

    is(scalar(@emp_files), 0, "No session JSON files saved on clean exit of empty session");
}

done_testing();
