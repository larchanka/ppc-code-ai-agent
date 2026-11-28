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
$ENV{CLAUDE_RETRY_DELAY} = 0;
$ENV{ANTHROPIC_API_KEY} = "test-ant-key";
$ENV{CLAUDE_PROVIDER} = "anthropic";

my $tmp_test_dir = tempdir(CLEANUP => 1);
$ENV{CLAUDE_SESSIONS_DIR} = $tmp_test_dir;

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";
configure_provider('anthropic');

our ($CURRENT_SESSION, $LAST_API_ELAPSED);

# ==================================================================
# 1. Title Sanitization (_sanitize_session_title / sanitize_session_title)
# ==================================================================
{
    # Basic alphanumeric and spaces preserved
    is(_sanitize_session_title("Fix Bug 123 in Perl"), "Fix Bug 123 in Perl", "basic alphanumeric and spaces preserved");

    # Strips punctuation and symbols
    is(_sanitize_session_title('Fix: "bug" in Perl, parser!'), "Fix bug in Perl parser", "strips punctuation and quotes");

    # Strips non-ASCII / emojis
    is(_sanitize_session_title("Fix 🚀 bug in 🐍 Python!"), "Fix bug in Python", "strips emojis and special symbols");

    # Collapses multiple consecutive spaces and strips leading/trailing whitespace
    is(_sanitize_session_title("   Fix    several    spaces   "), "Fix several spaces", "collapses consecutive spaces and trims edges");

    # Strictly truncates to 25 characters (and trims trailing space)
    my $long_title = "This is a very long title that exceeds twenty five characters";
    my $sanitized_long = _sanitize_session_title($long_title);
    cmp_ok(length($sanitized_long), '<=', 25, "truncates strictly to 25 characters or fewer");
    is($sanitized_long, "This is a very long title", "truncates to expected 25-char string");

    # Undef and empty strings
    is(_sanitize_session_title(""), "", "empty string returns empty string");
    is(_sanitize_session_title(undef), "", "undef returns empty string");
    is(_sanitize_session_title("   !!! ??? ###   "), "", "all-punctuation returns empty string");

    # Public alias sanitize_session_title behaves identically
    is(sanitize_session_title("Refactor Auth Module"), "Refactor Auth Module", "sanitize_session_title alias works");
}

# ==================================================================
# 2. Fallback Generation (_generate_fallback_title)
# ==================================================================
{
    # Standard ASCII prompt truncated to <= 25 chars
    my $fb1 = _generate_fallback_title("Write a script to parse logs", "1128-a3f9");
    cmp_ok(length($fb1), '<=', 25, "fallback prompt title is 25 chars or fewer");
    is($fb1, "Write a script to parse l", "truncates long prompt to 25 chars");

    # Empty prompt falls back to "Session <id>"
    is(_generate_fallback_title("", "1128-a3f9"), "Session 1128-a3f9", "empty prompt falls back to Session <id>");
    is(_generate_fallback_title("   \t\n  ", "1128-a3f9"), "Session 1128-a3f9", "whitespace-only prompt falls back to Session <id>");
    is(_generate_fallback_title(undef, "1128-a3f9"), "Session 1128-a3f9", "undef prompt falls back to Session <id>");

    # Non-ASCII / emoji prompt falling back to "Session <id>"
    is(_generate_fallback_title("🔥🔥🔥", "1128-a3f9"), "Session 1128-a3f9", "emoji prompt falls back to Session <id>");
    is(_generate_fallback_title("Привет мир", "1128-a3f9"), "Session 1128-a3f9", "non-ASCII prompt falls back to Session <id>");

    # Session hashref support as second argument
    my $mock_session = { id => "1128-beef" };
    is(_generate_fallback_title("", $mock_session), "Session 1128-beef", "supports session hashref as second argument");
}

# ==================================================================
# 3. Guard Clauses & Early Returns in generate_and_set_session_title
# ==================================================================
{
    # Return early if title already set
    my $s = init_session("1128-0001");
    $s->{title} = "Existing Title";
    $s->{title_attempted} = 0;
    my $res = generate_and_set_session_title($s, "Different Prompt");
    is($res, "Existing Title", "returns existing title without overwrite");
    is($s->{title}, "Existing Title", "title is unchanged");

    # Return early if title_attempted is already true
    my $s2 = init_session("1128-0002");
    $s2->{title} = "";
    $s2->{title_attempted} = 1;
    my $res2 = generate_and_set_session_title($s2, "Different Prompt");
    is($res2, "", "returns early if title_attempted is already true");
    is($s2->{title}, "", "title remains empty");
}

# ==================================================================
# 4. CLAUDE_SESSION_AUTO_TITLE=0 Disables LLM Call and Uses Fallback
# ==================================================================
{
    local $ENV{CLAUDE_SESSION_AUTO_TITLE} = "0";
    my $s = init_session("1128-0003");
    push @{ $s->{messages} }, { role => 'user', content => 'Build a calculator' };

    my $api_called = 0;
    no warnings 'redefine';
    local *call_api = sub {
        $api_called++;
        die "call_api should not be called when auto-title is disabled";
    };

    my $title = generate_and_set_session_title($s, "Build a calculator");
    is($api_called, 0, "call_api was not called when CLAUDE_SESSION_AUTO_TITLE=0");
    is($s->{title_attempted}, 1, "title_attempted flag is set to 1");
    is($s->{title}, "Build a calculator", "fallback title assigned to session");
    is($title, "Build a calculator", "returns fallback title");

    # Check persistence: saved to disk
    my $loaded = load_session("1128-0003");
    ok(defined $loaded, "session was saved to disk");
    is($loaded->{title}, "Build a calculator", "saved session has fallback title");

    # Also test 'off', 'false', 'no'
    for my $val (qw(false no off FALSE)) {
        local $ENV{CLAUDE_SESSION_AUTO_TITLE} = $val;
        my $s_val = init_session("1128-val-$val");
        generate_and_set_session_title($s_val, "Test Prompt");
        is($s_val->{title}, "Test Prompt", "honors CLAUDE_SESSION_AUTO_TITLE=$val");
    }
}

# ==================================================================
# 5. Successful Auto-Title via LLM Response
# ==================================================================
{
    delete $ENV{CLAUDE_SESSION_AUTO_TITLE};
    my $s = init_session("1128-0004");
    push @{ $s->{messages} }, { role => 'user', content => 'Help me debug this Perl memory leak' };

    my $api_call_opts;
    my $api_call_url;
    no warnings 'redefine';
    local *call_api = sub {
        my ($url, $hdrs, $body, $method, $opts) = @_;
        $api_call_url = $url;
        $api_call_opts = $opts;
        return {
            content => [
                { type => 'text', text => "Debug Perl Memory Leak" }
            ]
        };
    };

    my $title = generate_and_set_session_title($s, "Help me debug this Perl memory leak");
    is($title, "Debug Perl Memory Leak", "title extracted from LLM response");
    is($s->{title}, "Debug Perl Memory Leak", "session title property updated");
    is($s->{title_attempted}, 1, "title_attempted set to 1");
    ok(defined $api_call_opts && $api_call_opts->{silent} == 1, "call_api was called with silent => 1");
    ok(defined $api_call_opts && $api_call_opts->{no_retry} == 1, "call_api was called with no_retry => 1");

    # Verify session on disk
    my $loaded = load_session("1128-0004");
    ok(defined $loaded, "session was saved to disk");
    is($loaded->{title}, "Debug Perl Memory Leak", "disk session has LLM generated title");
}

# ==================================================================
# 6. LLM Response Sanitization (Quotes, Punctuation, Excess Length)
# ==================================================================
{
    delete $ENV{CLAUDE_SESSION_AUTO_TITLE};
    my $s = init_session("1128-0005");
    push @{ $s->{messages} }, { role => 'user', content => 'Optimize SQL queries' };

    no warnings 'redefine';
    local *call_api = sub {
        return {
            content => [
                { type => 'text', text => '  "Optimize: SQL Queries & Indexes (Fast)!"  ' }
            ]
        };
    };

    my $title = generate_and_set_session_title($s, "Optimize SQL queries");
    is($title, "Optimize SQL Queries Inde", "LLM title sanitized and truncated properly");
    is($s->{title}, "Optimize SQL Queries Inde", "session title set to sanitized value");
    cmp_ok(length($s->{title}), '<=', 25, "sanitized title length <= 25");
}

# ==================================================================
# 7. LLM Failure / Timeout / Non-ASCII Handling with Fallback
# ==================================================================
{
    delete $ENV{CLAUDE_SESSION_AUTO_TITLE};

    # 7.1 LLM throws error
    {
        my $s = init_session("1128-0006");
        push @{ $s->{messages} }, { role => 'user', content => 'Refactor transport layer' };

        no warnings 'redefine';
        local *call_api = sub {
            die "Curl network timeout";
        };

        my $title = eval { generate_and_set_session_title($s, "Refactor transport layer") };
        ok(!$@, "generate_and_set_session_title does not throw when call_api dies");
        is($title, "Refactor transport layer", "falls back to prompt when call_api fails");
        is($s->{title_attempted}, 1, "title_attempted set to 1 despite failure");
        is($s->{title}, "Refactor transport layer", "session title set to fallback");
    }

    # 7.2 LLM returns empty text
    {
        my $s = init_session("1128-0007");
        push @{ $s->{messages} }, { role => 'user', content => 'Analyze heap dump' };

        no warnings 'redefine';
        local *call_api = sub {
            return { content => [ { type => 'text', text => '   ' } ] };
        };

        my $title = generate_and_set_session_title($s, "Analyze heap dump");
        is($title, "Analyze heap dump", "falls back to prompt when LLM returns blank text");
        is($s->{title}, "Analyze heap dump", "session title set to fallback");
    }

    # 7.3 LLM returns only punctuation/symbols and prompt is non-ASCII
    {
        my $s = init_session("1128-0008");
        push @{ $s->{messages} }, { role => 'user', content => '🚀🚀🚀' };

        no warnings 'redefine';
        local *call_api = sub {
            return { content => [ { type => 'text', text => '### ???' } ] };
        };

        my $title = generate_and_set_session_title($s, "🚀🚀🚀");
        is($title, "Session 1128-0008", "falls back to Session <id> when prompt has no ASCII");
        is($s->{title}, "Session 1128-0008", "session title set to Session <id>");
    }
}

# ==================================================================
# 8. Missing $first_prompt auto-extracted from $session->{messages}
# ==================================================================
{
    delete $ENV{CLAUDE_SESSION_AUTO_TITLE};
    my $s = init_session("1128-0009");
    push @{ $s->{messages} }, { role => 'user', content => 'Fix socket buffer overflow' };

    no warnings 'redefine';
    local *call_api = sub {
        return {
            content => [
                { type => 'text', text => "Socket Buffer Fix" }
            ]
        };
    };

    # Call without passing $first_prompt
    my $title = generate_and_set_session_title($s);
    is($title, "Socket Buffer Fix", "automatically extracts first prompt from messages");
    is($s->{title}, "Socket Buffer Fix", "session title correctly assigned");
}

# ==================================================================
# 9. End-to-End Interactive REPL Auto-Title in main.pl
# ==================================================================
{
    my $e2e_tmp = tempdir(CLEANUP => 1);
    my $sessions_dir = File::Spec->catdir($e2e_tmp, '.code-agent', 'sessions');
    my $recorder_script = File::Spec->catfile($e2e_tmp, 'mock_curl_e2e.pl');
    my $log_file = File::Spec->catfile($e2e_tmp, 'recorder.log');

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

my $body = '';
if ($req_path && -f $req_path) {
    open my $in, '<', $req_path;
    $body = do { local $/; <$in> };
    close $in;

    my $log = $ENV{RECORDER_LOG} || '/tmp/rec.log';
    open my $lf, '>>', $log;
    print $lf "===REQUEST===\n$body\n";
    close $lf;
}

if ($out_path) {
    open my $out, '>', $out_path;
    if ($body =~ /summarizes this user request/i) {
        # LLM auto-title request
        print $out '{"content":[{"type":"text","text":"E2E Generated Title"}]}';
    }
    else {
        # Regular user prompt response
        print $out '{"content":[{"type":"text","text":"Hello from AI"}]}';
    }
    close $out;
}

print "200";
exit 0;
RECORDER
    close $rf;
    chmod 0755, $recorder_script;

    my $script = "$root_dir/code-agent.pl";
    my $perl = $^X;

    # 9.1 Default auto-title enabled: triggers title API call after turn 1
    {
        unlink $log_file if -f $log_file;
        my $cmd = qq{printf "Plan a birthday party\\nexit\\n" | } .
                  qq{HOME="$e2e_tmp" CLAUDE_SESSIONS_DIR="$sessions_dir" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_CURL="$recorder_script" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
                  qq{RECORDER_LOG="$log_file" } .
                  qq{$perl $script 2>&1};
        my $output = `$cmd`;

        open my $lf, '<', $log_file or die "Cannot read $log_file: $!";
        my $logged = do { local $/; <$lf> };
        close $lf;

        my @requests = split(/===REQUEST===\n/, $logged);
        shift @requests; # remove empty leading chunk

        is(scalar(@requests), 2, "Turn 1 + Auto-Title produced exactly 2 API calls");
        like($requests[0], qr/Plan a birthday party/, "First request is the user conversation turn");
        like($requests[1], qr/summarizes this user request/, "Second request is the auto-title prompt");

        # Inspect saved session on disk
        opendir(my $dh, $sessions_dir) or die "Cannot read $sessions_dir: $!";
        my ($session_file) = grep { /^\d{4}-[0-9a-f]{4}\.json$/ } readdir($dh);
        closedir $dh;

        ok(defined $session_file, "Session file was created on disk in ~/.code-agent/sessions");
        if ($session_file) {
            my $full_path = File::Spec->catfile($sessions_dir, $session_file);
            open my $sfh, '<', $full_path;
            my $raw = do { local $/; <$sfh> };
            close $sfh;
            like($raw, qr/"title"\s*:\s*"E2E Generated Title"/, "Saved session JSON contains E2E Generated Title");
        }
    }

    # 9.2 Auto-title disabled with CLAUDE_SESSION_AUTO_TITLE=0
    {
        my $e2e_tmp2 = tempdir(CLEANUP => 1);
        my $sessions_dir2 = File::Spec->catdir($e2e_tmp2, '.code-agent', 'sessions');
        my $log_file2 = File::Spec->catfile($e2e_tmp2, 'recorder2.log');

        my $cmd = qq{printf "Configure database cluster\\nexit\\n" | } .
                  qq{HOME="$e2e_tmp2" CLAUDE_SESSIONS_DIR="$sessions_dir2" ANTHROPIC_API_KEY="test-ant-key" CLAUDE_PROVIDER="anthropic" } .
                  qq{CLAUDE_SESSION_AUTO_TITLE="0" } .
                  qq{CLAUDE_CURL="$recorder_script" CLAUDE_CACERT="$ENV{CLAUDE_CACERT}" } .
                  qq{RECORDER_LOG="$log_file2" } .
                  qq{$perl $script 2>&1};
        my $output = `$cmd`;

        open my $lf, '<', $log_file2 or die "Cannot read $log_file2: $!";
        my $logged = do { local $/; <$lf> };
        close $lf;

        my @requests = split(/===REQUEST===\n/, $logged);
        shift @requests;

        is(scalar(@requests), 1, "Only 1 API call made when CLAUDE_SESSION_AUTO_TITLE=0");
        like($requests[0], qr/Configure database cluster/, "Single request is the user conversation turn");

        opendir(my $dh, $sessions_dir2) or die "Cannot read $sessions_dir2: $!";
        my ($session_file) = grep { /^\d{4}-[0-9a-f]{4}\.json$/ } readdir($dh);
        closedir $dh;

        ok(defined $session_file, "Session file created on disk");
        if ($session_file) {
            my $full_path = File::Spec->catfile($sessions_dir2, $session_file);
            open my $sfh, '<', $full_path;
            my $raw = do { local $/; <$sfh> };
            close $sfh;
            like($raw, qr/"title"\s*:\s*"Configure database cluste"/, "Fallback prompt title used in saved session");
        }
    }
}

done_testing();
