#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";
our $CURRENT_SESSION;

# ==================================================================
# Task 1: Session Abstraction & Lifecycle Hooks
# ==================================================================

# 1. generate_session_id format and monotonicity
my $id1 = generate_session_id();
ok(defined $id1, "generate_session_id() returns defined ID");
like($id1, qr/^session-\d{8}-\d{6}-\d{3,}$/, "session ID matches expected format");

my $id2 = generate_session_id();
ok(defined $id2, "second generate_session_id() returns defined ID");
isnt($id1, $id2, "consecutive session IDs are unique");

# 2. init_session creates structured session
my $s1 = init_session();
ok(defined $s1 && ref($s1) eq 'HASH', "init_session() returns hashref");
ok(defined $s1->{id} && $s1->{id} =~ /^session-/, "session has valid id");
ok(defined $s1->{created_at} && $s1->{created_at} > 0, "session has valid created_at");
is(ref($s1->{messages}), 'ARRAY', "session has messages arrayref");
is(scalar(@{$s1->{messages}}), 0, "session messages array starts empty");

# 3. init_session with custom ID
my $custom_id = "custom-test-session-123";
my $s_custom = init_session($custom_id);
is($s_custom->{id}, $custom_id, "init_session honors custom ID argument");

# 4. get_current_session returns active session
my $curr = get_current_session();
is($curr, $s_custom, "get_current_session() returns current active session");

# 5. get_current_session lazy initialization when undef
$CURRENT_SESSION = undef;
my $lazy_session = get_current_session();
ok(defined $lazy_session && ref($lazy_session) eq 'HASH', "get_current_session() lazily initializes if undef");
ok(defined $lazy_session->{id}, "lazy session has valid ID");

# 6. archive_session hook
my $archived = archive_session($lazy_session);
is($archived, $lazy_session, "archive_session returns the archived session reference");

my $archived_default = archive_session();
is($archived_default, $lazy_session, "archive_session() defaults to CURRENT_SESSION");

$CURRENT_SESSION = undef;
my $archived_none = archive_session(undef);
is($archived_none, undef, "archive_session() returns undef when no current session exists");

# ==================================================================
# Task 2: /new Command Handler & show_help Documentation
# ==================================================================

# 1. handle_new_command creates a new session, clears messages, and prints message
{
    init_session();
    push @{$CURRENT_SESSION->{messages}}, { role => 'user', content => 'Hello agent' };
    my $old_id = $CURRENT_SESSION->{id};
    is(scalar(@{$CURRENT_SESSION->{messages}}), 1, "Session has 1 message before /new");

    open my $out, '>', \my $captured;
    my $new_s = handle_new_command($out);
    close $out;

    ok(defined $new_s && ref($new_s) eq 'HASH', "handle_new_command returns session hashref");
    is($CURRENT_SESSION, $new_s, '$CURRENT_SESSION is updated to the new session');
    is(scalar(@{$new_s->{messages}}), 0, "New session messages array is empty");
    isnt($new_s->{id}, $old_id, "New session has a different ID from old session");
    like($captured, qr/Started a new conversation\. Chat history cleared\./,
         "handle_new_command prints confirmation message");
}

# 2. handle_new_command invokes archive_session with previous session
{
    init_session();
    push @{$CURRENT_SESSION->{messages}}, { role => 'user', content => 'Session to archive' };
    my $prev_session = $CURRENT_SESSION;
    my $archived_arg;

    {
        no warnings 'redefine';
        local *archive_session = sub {
            ($archived_arg) = @_;
            return $archived_arg;
        };

        open my $out, '>', \my $captured;
        handle_new_command($out);
        close $out;
    }

    is($archived_arg, $prev_session, "handle_new_command calls archive_session with previous session");
}

# 3. handle_new_command accepts optional explicit session parameter
{
    my $explicit_session = {
        id => 'explicit-session-123',
        created_at => time(),
        messages => [{ role => 'user', content => 'custom' }],
    };
    my $archived_arg;

    {
        no warnings 'redefine';
        local *archive_session = sub {
            ($archived_arg) = @_;
            return $archived_arg;
        };

        open my $out, '>', \my $captured;
        handle_new_command($out, $explicit_session);
        close $out;
    }

    is($archived_arg, $explicit_session, "handle_new_command archives explicit session argument if provided");
}

# 4. handle_new_command defaults to STDOUT when no filehandle passed
{
    init_session();
    open my $orig_stdout, ">&STDOUT" or die "Cannot dup STDOUT: $!";
    close STDOUT;
    open STDOUT, '>', \my $stdout_captured or die "Cannot redirect STDOUT: $!";

    my $new_s = handle_new_command();

    close STDOUT;
    open STDOUT, ">&", $orig_stdout or die "Cannot restore STDOUT: $!";
    close $orig_stdout;

    ok(defined $new_s, "handle_new_command() without args succeeds");
    like($stdout_captured, qr/Started a new conversation\. Chat history cleared\./,
         "handle_new_command() writes to STDOUT by default");
}

# 5. show_help documents /new
{
    open my $out, '>', \my $captured;
    show_help($out);
    close $out;

    like($captured, qr{/new\s+-\s+Start a new conversation \(clears chat history\)},
         "show_help documents /new command");
}

# 6. Integration: Main conversation loop routes /new and updates greeting banner
{
    my $perl = $^X;
    my $script = "$root_dir/code-agent.pl";

    my $cmd = qq{printf "/new\\nexit\\n" | } .
              qq{HOME="/nonexistent" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
              qq{CLAUDE_CURL="$ENV{CLAUDE_CURL}" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
              qq{$perl $script 2>&1};
    my $output = `$cmd`;

    like($output, qr{Type /help for commands}, "Startup banner mentions /help for commands");
    like($output, qr{Started a new conversation\. Chat history cleared\.},
         "Interactive conversation loop dispatches /new and prints confirmation");
    like($output, qr{Goodbye\.}, "Clean exit from conversation loop after /new");
}

# 7. Integration: Conversation turns across /new start fresh without old messages
{
    my $perl = $^X;
    my $script = "$root_dir/code-agent.pl";
    my $log_file = "$root_dir/t/test_new_command_payloads.log";
    unlink $log_file if -e $log_file;

    # Create a small recorder curl script that logs each API request body
    my $recorder_script = "$root_dir/t/mock_curl_recorder.pl";
    open my $rf, '>', $recorder_script or die "Cannot write $recorder_script: $!";
    print $rf <<'RECORDER';
#!/usr/bin/perl
use strict;
use warnings;

my $config_path;
for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq '-K' && defined $ARGV[$i+1]) {
        $config_path = $ARGV[$i+1];
        last;
    }
}
exit 1 unless $config_path && -f $config_path;

open my $fh, '<', $config_path or exit 1;
my $cfg = do { local $/; <$fh> };
close $fh;

my ($req_path) = $cfg =~ /^data-binary\s*=\s*"\@([^"]+)"/m;
my ($out_path) = $cfg =~ /^output\s*=\s*"([^"]+)"/m;

if ($req_path && -f $req_path) {
    open my $in, '<', $req_path;
    my $body = do { local $/; <$in> };
    close $in;

    my $log = $ENV{RECORDER_LOG} || '/tmp/rec.log';
    open my $lf, '>>', $log;
    print $lf "===REQUEST===\n$body\n";
    close $lf;
}

if ($out_path) {
    open my $out, '>', $out_path;
    print $out '{"content":[{"type":"text","text":"OK"}]}';
    close $out;
}

print "200";
exit 0;
RECORDER
    close $rf;
    chmod 0755, $recorder_script;

    my $cmd = qq{printf "First unique message\\n/new\\nSecond unique message\\nexit\\n" | } .
              qq{HOME="/nonexistent" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
              qq{CLAUDE_CURL="$recorder_script" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
              qq{RECORDER_LOG="$log_file" } .
              qq{$perl $script 2>&1};
    my $output = `$cmd`;

    like($output, qr{Started a new conversation\. Chat history cleared\.},
         "Interactive loop executed /new between conversation turns");

    open my $lf, '<', $log_file or die "Cannot read $log_file: $!";
    my $logged = do { local $/; <$lf> };
    close $lf;

    my @requests = split(/===REQUEST===\n/, $logged);
    shift @requests; # remove empty leading chunk

    is(scalar(@requests), 2, "Exactly two API requests were recorded across the turns");
    like($requests[0], qr/First unique message/, "First request contains 'First unique message'");
    unlike($requests[0], qr/Second unique message/, "First request does not contain 'Second unique message'");

    like($requests[1], qr/Second unique message/, "Second request contains 'Second unique message'");
    unlike($requests[1], qr/First unique message/, "Second request after /new DOES NOT contain 'First unique message'");

    unlink $log_file if -e $log_file;
    unlink $recorder_script if -e $recorder_script;
}

done_testing();
