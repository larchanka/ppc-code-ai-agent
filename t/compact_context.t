#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 39;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ==================================================================
# 1. compact_tool_result_content unit tests
# ==================================================================
{
    # Short content should not be truncated
    my $short = "Line 1\nLine 2\nLine 3\n";
    is(compact_tool_result_content($short), $short, "Short content under limits is unchanged");

    # Empty and undef content
    is(compact_tool_result_content(undef), undef, "Undef content returns undef");
    is(compact_tool_result_content(''), '', "Empty content returns empty string");

    # Multi-line truncation
    my @lines = map { "This is line $_ of test output" } (1 .. 100);
    my $long_text = join("\n", @lines);
    my $truncated = compact_tool_result_content($long_text, max_lines => 20, head_lines => 5, tail_lines => 5);

    ok(length($truncated) < length($long_text), "Compacted multi-line text is shorter than original");
    like($truncated, qr/This is line 1 of test output/, "Compacted text contains head");
    like($truncated, qr/This is line 100 of test output/, "Compacted text contains tail");
    like($truncated, qr/\[\.\.\. 90 lines truncated for context budget \.\.\.\]/, "Compacted text contains lines truncated notice");

    # Re-truncation should be idempotent
    my $re_truncated = compact_tool_result_content($truncated, max_lines => 20, head_lines => 5, tail_lines => 5);
    is($re_truncated, $truncated, "Compacted text is not double-truncated");

    # Wrapped in <untrusted_tool_output> tag
    my $wrapped = "<untrusted_tool_output tool=\"read_file\">\n$long_text\n</untrusted_tool_output>";
    my $compacted_wrapped = compact_tool_result_content($wrapped, max_lines => 20, head_lines => 5, tail_lines => 5);
    like($compacted_wrapped, qr/^<untrusted_tool_output tool="read_file">/, "Preserves opening untrusted_tool_output tag");
    like($compacted_wrapped, qr/<\/untrusted_tool_output>$/, "Preserves closing untrusted_tool_output tag");
    like($compacted_wrapped, qr/\[\.\.\. 90 lines truncated for context budget \.\.\.\]/, "Contains truncation notice inside wrapper");

    # Large single-line text (byte truncation)
    my $giant_line = "A" x 5000;
    my $compacted_bytes = compact_tool_result_content($giant_line, max_bytes => 1000, head_bytes => 200, tail_bytes => 200);
    ok(length($compacted_bytes) < length($giant_line), "Single-line giant text truncated by bytes");
    like($compacted_bytes, qr/\[\.\.\. \d+ bytes truncated for context budget \.\.\.\]/, "Contains bytes truncated notice");
}

# ==================================================================
# 2. compact_session_history: preserving recent turns & IDs
# ==================================================================
{
    my $long_output1 = join("\n", map { "File1 line $_" } (1 .. 80));
    my $long_output2 = join("\n", map { "File2 line $_" } (1 .. 80));
    my $long_output3 = join("\n", map { "File3 line $_" } (1 .. 80));

    my $session = {
        id => 'test-compact-session',
        messages => [
            # Turn 1 (older)
            { role => 'user', content => 'Read file 1' },
            { role => 'assistant', content => [
                { type => 'tool_use', id => 'call_111', name => 'read_file', input => { path => 'file1.txt' } }
            ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'call_111', name => 'read_file', content => $long_output1 }
            ] },
            { role => 'assistant', content => [ { type => 'text', text => 'Finished reading file 1.' } ] },

            # Turn 2 (recent turn 1 of 2)
            { role => 'user', content => 'Read file 2' },
            { role => 'assistant', content => [
                { type => 'tool_use', id => 'call_222', name => 'read_file', input => { path => 'file2.txt' } }
            ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'call_222', name => 'read_file', content => $long_output2 }
            ] },
            { role => 'assistant', content => [ { type => 'text', text => 'Finished reading file 2.' } ] },

            # Turn 3 (recent turn 2 of 2)
            { role => 'user', content => 'Read file 3' },
            { role => 'assistant', content => [
                { type => 'tool_use', id => 'call_333', name => 'read_file', input => { path => 'file3.txt' } }
            ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'call_333', name => 'read_file', content => $long_output3 }
            ] },
            { role => 'assistant', content => [ { type => 'text', text => 'Finished reading file 3.' } ] },
        ]
    };

    # Compact with keep_turns => 2
    my $stats = compact_session_history($session, keep_turns => 2, max_lines => 20, head_lines => 5, tail_lines => 5);

    is($stats->{compacted_count}, 1, "Compacted exactly 1 tool result from older Turn 1");
    ok($stats->{bytes_saved} > 0, "Bytes saved is positive");

    # Turn 1 tool result should be compacted
    my $msg2 = $session->{messages}[2];
    is($msg2->{content}[0]{tool_use_id}, 'call_111', "Turn 1 tool_use_id 'call_111' preserved exactly");
    is($msg2->{content}[0]{name}, 'read_file', "Turn 1 tool name 'read_file' preserved");
    like($msg2->{content}[0]{content}, qr/truncated for context budget/, "Turn 1 content is compacted");

    # Turn 2 & 3 tool results should be INTACT
    my $msg6 = $session->{messages}[6];
    is($msg6->{content}[0]{tool_use_id}, 'call_222', "Turn 2 tool_use_id 'call_222' preserved");
    is($msg6->{content}[0]{content}, $long_output2, "Turn 2 tool content is completely intact (recent turn)");

    my $msg10 = $session->{messages}[10];
    is($msg10->{content}[0]{tool_use_id}, 'call_333', "Turn 3 tool_use_id 'call_333' preserved");
    is($msg10->{content}[0]{content}, $long_output3, "Turn 3 tool content is completely intact (recent turn)");

    # Verify text-only turns remain unmodified
    is($session->{messages}[0]{content}, 'Read file 1', "Turn 1 user text prompt is unmodified");
    is($session->{messages}[3]{content}[0]{text}, 'Finished reading file 1.', "Turn 1 assistant text is unmodified");

    # Verify provider request building with compacted history
    # Anthropic
    $ENV{ANTHROPIC_API_KEY} = 'test-key';
    configure_provider('anthropic');
    my $req_ant = build_request($session->{messages}, [], 'system prompt');
    ok($req_ant && ref($req_ant->{messages}) eq 'ARRAY', "Anthropic build_request succeeds with compacted history");
    is($req_ant->{messages}[2]{content}[0]{tool_use_id}, 'call_111', "Anthropic request maintains tool_use_id correlation");

    # OpenAI
    $ENV{OPENAI_BASE_URL} = 'http://127.0.0.1:8080/v1';
    configure_provider('openai');
    my $req_oa = build_request($session->{messages}, [], 'system prompt');
    ok($req_oa && ref($req_oa->{messages}) eq 'ARRAY', "OpenAI build_request succeeds with compacted history");

    # Gemini
    $ENV{GEMINI_API_KEY} = 'test-gemini-key';
    configure_provider('gemini');
    my $req_gem = build_request($session->{messages}, [], 'system prompt');
    ok($req_gem && ref($req_gem->{contents}) eq 'ARRAY', "Gemini build_request succeeds with compacted history");
}

# ==================================================================
# 3. /compact slash command and show_help
# ==================================================================
{
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open scalar fh: $!";
    show_help($fh);
    close $fh;
    like($output, qr{/compact\b}, "show_help lists /compact command");

    # Test handle_compact_command with truncatable content
    my $test_session = {
        id => 'cmd-session',
        messages => [
            { role => 'user', content => 'Read old' },
            { role => 'assistant', content => [ { type => 'tool_use', id => 'c1', name => 'read_file' } ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'c1', name => 'read_file', content => join("\n", (1..100)) }
            ] },
            { role => 'user', content => 'Read new' },
            { role => 'assistant', content => [ { type => 'tool_use', id => 'c2', name => 'read_file' } ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'c2', name => 'read_file', content => "short" }
            ] },
        ]
    };

    my $cmd_out = '';
    open my $cfh, '>', \$cmd_out or die "Cannot open scalar fh: $!";
    my $res = handle_compact_command($cfh, $test_session, keep_turns => 1, max_lines => 10, head_lines => 2, tail_lines => 2);
    close $cfh;

    is($res->{compacted_count}, 1, "handle_compact_command compacted 1 result");
    like($cmd_out, qr/Compacted session history/, "handle_compact_command printed confirmation message");

    # Calling handle_compact_command again when already compact
    my $cmd_out2 = '';
    open my $cfh2, '>', \$cmd_out2 or die "Cannot open scalar fh: $!";
    my $res2 = handle_compact_command($cfh2, $test_session, keep_turns => 1, max_lines => 10, head_lines => 2, tail_lines => 2);
    close $cfh2;

    is($res2->{compacted_count}, 0, "Already compacted session has 0 compacted results");
    like($cmd_out2, qr/already compact/, "handle_compact_command reports already compact");
}

# ==================================================================
# 4. Turn & size estimation, automatic compaction triggers
# ==================================================================
{
    my $sess = {
        id => 'metrics-session',
        messages => [
            { role => 'user', content => 'Turn 1 prompt' },
            { role => 'assistant', content => [ { type => 'text', text => 'Reply 1' } ] },
            { role => 'user', content => 'Turn 2 prompt' },
            { role => 'assistant', content => [ { type => 'tool_use', id => 'x1', name => 'read_file' } ] },
            { role => 'user', content => [
                { type => 'tool_result', tool_use_id => 'x1', name => 'read_file', content => join("\n", (1..50)) }
            ] },
            { role => 'assistant', content => [ { type => 'text', text => 'Reply 2' } ] },
            { role => 'user', content => 'Turn 3 prompt' },
        ]
    };

    is(count_user_turns($sess), 3, "count_user_turns counts 3 user prompt turns correctly");
    ok(estimate_session_chars($sess) > 100, "estimate_session_chars returns plausible byte count");

    # auto_compact when under threshold
    my $res_under = auto_compact_session_if_needed($sess, threshold_chars => 100000, threshold_turns => 10);
    is($res_under, undef, "auto_compact_session_if_needed returns undef when under thresholds");

    # auto_compact when over turn threshold
    my $res_over_turns = auto_compact_session_if_needed($sess, threshold_chars => 100000, threshold_turns => 2, keep_turns => 1, max_lines => 10);
    ok(defined $res_over_turns, "auto_compact_session_if_needed triggers when over turn threshold");
    is($res_over_turns->{compacted_count}, 1, "auto_compact_session_if_needed compacted older tool result");

    # auto_compact disabled when CLAUDE_AUTO_COMPACT=0
    $ENV{CLAUDE_AUTO_COMPACT} = '0';
    my $res_disabled = auto_compact_session_if_needed($sess, threshold_chars => 10, threshold_turns => 1);
    is($res_disabled, undef, "auto_compact_session_if_needed returns undef when CLAUDE_AUTO_COMPACT=0");
    delete $ENV{CLAUDE_AUTO_COMPACT};
}
