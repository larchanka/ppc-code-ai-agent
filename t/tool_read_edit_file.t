#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";
delete $ENV{CLAUDE_AUTO_MODE};

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";
our @TOOLS;

my $temp_dir = tempdir(CLEANUP => 1);

# ==================================================================
# Task 1: Extend read_file schema and line range slicing
# ==================================================================

# 1. Schema inspection
my ($read_file_tool) = grep { $_->{name} eq 'read_file' } @TOOLS;
ok($read_file_tool, "read_file tool exists in \@TOOLS");
is_deeply($read_file_tool->{input_schema}{required}, ['path'], "read_file required schema contains only path");

my $props = $read_file_tool->{input_schema}{properties};
ok($props->{path}, "path property exists");
is($props->{path}{type}, 'string', "path property is string");

ok($props->{start_line}, "start_line property exists in schema");
is($props->{start_line}{type}, 'integer', "start_line is integer");

ok($props->{end_line}, "end_line property exists in schema");
is($props->{end_line}{type}, 'integer', "end_line is integer");

# 2. File creation helper
sub write_temp_file {
    my ($filename, $content) = @_;
    my $path = "$temp_dir/$filename";
    open my $fh, '>:encoding(UTF-8)', $path or die "Cannot create temp file: $!";
    print $fh $content;
    close $fh;
    return $path;
}

my $test_file_content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\n";
my $test_file = write_temp_file("test_read.txt", $test_file_content);

# 3. Full file read when start_line and end_line are omitted
is(
    run_tool('read_file', { path => $test_file }),
    $test_file_content,
    "Full file read when neither start_line nor end_line is specified"
);

# 4. Partial range reading [2, 4]
is(
    run_tool('read_file', { path => $test_file, start_line => 2, end_line => 4 }),
    "Line 2\nLine 3\nLine 4\n",
    "Line range [2, 4] reads lines 2 through 4"
);

# 5. Single line reading [3, 3]
is(
    run_tool('read_file', { path => $test_file, start_line => 3, end_line => 3 }),
    "Line 3\n",
    "Single line range [3, 3] reads line 3"
);

# 6. Only start_line specified (reads to EOF)
is(
    run_tool('read_file', { path => $test_file, start_line => 3 }),
    "Line 3\nLine 4\nLine 5\n",
    "Only start_line => 3 reads from line 3 to EOF"
);

# 7. Only end_line specified (reads from line 1)
is(
    run_tool('read_file', { path => $test_file, end_line => 2 }),
    "Line 1\nLine 2\n",
    "Only end_line => 2 reads from line 1 to line 2"
);

# 8. Bounds clamping: start_line < 1 clamped to 1
is(
    run_tool('read_file', { path => $test_file, start_line => 0, end_line => 2 }),
    "Line 1\nLine 2\n",
    "start_line => 0 clamped to 1"
);
is(
    run_tool('read_file', { path => $test_file, start_line => -5, end_line => 2 }),
    "Line 1\nLine 2\n",
    "start_line => -5 clamped to 1"
);

# 9. Bounds clamping: end_line > total clamped to total
is(
    run_tool('read_file', { path => $test_file, start_line => 4, end_line => 100 }),
    "Line 4\nLine 5\n",
    "end_line => 100 clamped to total (5)"
);

# 10. Out-of-bounds: start_line > total returns empty string
is(
    run_tool('read_file', { path => $test_file, start_line => 10, end_line => 20 }),
    "",
    "start_line => 10 > total returns empty string"
);
is(
    run_tool('read_file', { path => $test_file, start_line => 6 }),
    "",
    "start_line => 6 > total (omitted end_line) returns empty string"
);

# 11. Error validation: start_line > end_line
my $err_range = run_tool('read_file', { path => $test_file, start_line => 4, end_line => 2 });
is(
    $err_range,
    "Error: start_line (4) cannot be greater than end_line (2)",
    "Error returned when start_line > end_line"
);

# 12. Non-existent file returns error
my $err_no_file = run_tool('read_file', { path => "$temp_dir/does_not_exist.txt" });
like(
    $err_no_file,
    qr/^Error: cannot open /,
    "Non-existent file returns cannot open error"
);

# 13. Preserves lines without trailing newline at EOF
my $no_eof_nl = "First\nSecond\nThird";
my $no_eof_file = write_temp_file("no_eof.txt", $no_eof_nl);
is(
    run_tool('read_file', { path => $no_eof_file, start_line => 2, end_line => 3 }),
    "Second\nThird",
    "Range read preserves file ending without trailing newline"
);

# 14. UTF-8 multi-byte support
my $utf8_content = "こんにちは\n世界\nTiger 10.4\nPowerPC\n";
my $utf8_file = write_temp_file("utf8.txt", $utf8_content);
is(
    run_tool('read_file', { path => $utf8_file, start_line => 1, end_line => 2 }),
    "こんにちは\n世界\n",
    "Range read on UTF-8 content preserves multibyte characters"
);

# ==================================================================
# Task 2: edit_file schema, validation, confirmation, and editing
# ==================================================================

# 1. Schema inspection
my ($edit_file_tool) = grep { $_->{name} eq 'edit_file' } @TOOLS;
ok($edit_file_tool, "edit_file tool exists in \@TOOLS");
is_deeply(
    $edit_file_tool->{input_schema}{required},
    ['path', 'start_line', 'end_line', 'content'],
    "edit_file required schema contains path, start_line, end_line, content"
);

my $edit_props = $edit_file_tool->{input_schema}{properties};
ok($edit_props->{path}, "path property exists");
is($edit_props->{path}{type}, 'string', "path property is string");

ok($edit_props->{start_line}, "start_line property exists in schema");
is($edit_props->{start_line}{type}, 'integer', "start_line is integer");

ok($edit_props->{end_line}, "end_line property exists in schema");
is($edit_props->{end_line}{type}, 'integer', "end_line is integer");

ok($edit_props->{content}, "content property exists in schema");
is($edit_props->{content}{type}, 'string', "content is string");

# 2. File helper
sub read_file_raw {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

# 3. Error handling: non-existent file
{
    set_auto_mode(1);
    my $err = run_tool('edit_file', {
        path       => "$temp_dir/non_existent.txt",
        start_line => 1,
        end_line   => 1,
        content    => "test\n",
    });
    like($err, qr/^Error: cannot open /, "edit_file returns error for non-existent file");
}

# 4. Error handling: invalid line ranges
{
    my $ef = write_temp_file("range_err.txt", "1\n2\n3\n4\n5\n");

    my $err_start_zero = run_tool('edit_file', {
        path       => $ef,
        start_line => 0,
        end_line   => 2,
        content    => "test\n",
    });
    like($err_start_zero, qr/start_line.*must be >= 1/i, "edit_file rejects start_line < 1");

    my $err_start_exceed = run_tool('edit_file', {
        path       => $ef,
        start_line => 7,
        end_line   => 7,
        content    => "test\n",
    });
    like($err_start_exceed, qr/start_line.*exceeds total lines/i, "edit_file rejects start_line > total + 1");

    my $err_end_less = run_tool('edit_file', {
        path       => $ef,
        start_line => 4,
        end_line   => 2,
        content    => "test\n",
    });
    like($err_end_less, qr/end_line.*cannot be less than start_line - 1/i, "edit_file rejects end_line < start_line - 1");
}

# 5. User confirmation: manual mode rejection and approval
{
    my $ef = write_temp_file("confirm_test.txt", "line 1\nline 2\nline 3\n");
    set_auto_mode(0);

    # Rejection
    my @prompts;
    no warnings 'redefine';
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 0;
    };

    my $res_cancel = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 2,
        content    => "cancelled line\n",
    });
    is($res_cancel, "Cancelled by user.", "edit_file cancelled when user rejects confirm");
    is(scalar(@prompts), 1, "confirm called once");
    is($prompts[0], "Edit file '$ef' (lines 2-2)?", "confirm prompt matches expected format");
    is(read_file_raw($ef), "line 1\nline 2\nline 3\n", "file content unmodified on rejection");

    # Approval
    @prompts = ();
    local *confirm = sub {
        my ($prompt) = @_;
        push @prompts, $prompt;
        return 1;
    };

    my $res_ok = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 2,
        content    => "new line 2\n",
    });
    is($res_ok, "Edit complete: $ef", "edit_file returns success message on confirmation");
    is(read_file_raw($ef), "line 1\nnew line 2\nline 3\n", "line 2 successfully replaced");

    # Clamping in confirmation prompt when end_line > total lines
    @prompts = ();
    my $res_clamp = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 999,
        content    => "clamped edit\n",
    });
    is($res_clamp, "Edit complete: $ef", "edit_file returns success message on clamped end_line");
    is($prompts[0], "Edit file '$ef' (lines 2-3)?", "confirm prompt clamps end_line to total lines (3)");
}

# 6. Auto mode bypass confirmation
{
    my $ef = write_temp_file("auto_test.txt", "A\nB\nC\n");
    set_auto_mode(1);

    my $called = 0;
    no warnings 'redefine';
    local *confirm = sub { $called++; return 0; };

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 1,
        end_line   => 1,
        content    => "Alpha\n",
    });
    is($called, 0, "confirm() not called in auto mode");
    is($res, "Edit complete: $ef", "edit_file succeeds in auto mode");
    is(read_file_raw($ef), "Alpha\nB\nC\n", "line 1 replaced in auto mode");
}

# 7. Multi-line replacement and newline normalization
{
    my $ef = write_temp_file("multi_test.txt", "1\n2\n3\n4\n5\n");
    set_auto_mode(1);

    # Replace lines 2-4 with content lacking a trailing newline (should be auto-appended)
    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 4,
        content    => "Two-to-Four",
    });
    is($res, "Edit complete: $ef", "edit_file multi-line replace succeeds");
    is(read_file_raw($ef), "1\nTwo-to-Four\n5\n", "lines 2-4 replaced with newline auto-appended");
}

# 8. Line deletion when content is empty string
{
    my $ef = write_temp_file("del_test.txt", "1\n2\n3\n4\n5\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 4,
        content    => "",
    });
    is($res, "Edit complete: $ef", "edit_file line deletion succeeds");
    is(read_file_raw($ef), "1\n5\n", "lines 2 through 4 excised cleanly");
}

# 9. Insertion without deletion: prepend at top (start_line: 1, end_line: 0)
{
    my $ef = write_temp_file("prepend_test.txt", "First\nSecond\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 1,
        end_line   => 0,
        content    => "Header\n",
    });
    is($res, "Edit complete: $ef", "edit_file prepend succeeds");
    is(read_file_raw($ef), "Header\nFirst\nSecond\n", "header prepended at top of file");
}

# 10. Insertion without deletion: append at EOF (start_line: N+1, end_line: N)
{
    my $ef = write_temp_file("append_test.txt", "First\nSecond\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 3,
        end_line   => 2,
        content    => "Footer\n",
    });
    is($res, "Edit complete: $ef", "edit_file append at EOF succeeds");
    is(read_file_raw($ef), "First\nSecond\nFooter\n", "footer appended at end of file");
}

# 11. Insertion without deletion: middle insert (start_line: 2, end_line: 1)
{
    my $ef = write_temp_file("mid_test.txt", "First\nSecond\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 1,
        content    => "Between\n",
    });
    is($res, "Edit complete: $ef", "edit_file middle insertion succeeds");
    is(read_file_raw($ef), "First\nBetween\nSecond\n", "inserted between lines 1 and 2");
}

# 12. Clamping end_line > total
{
    my $ef = write_temp_file("clamp_test.txt", "1\n2\n3\n4\n5\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 4,
        end_line   => 100,
        content    => "End\n",
    });
    is($res, "Edit complete: $ef", "edit_file clamps end_line to total");
    is(read_file_raw($ef), "1\n2\n3\nEnd\n", "lines 4 and 5 replaced when end_line clamped");
}

# 13. Replacement synonym tolerance
{
    my $ef = write_temp_file("synonym_test.txt", "Alpha\nBeta\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path        => $ef,
        start_line  => 2,
        end_line    => 2,
        replacement => "Gamma\n",
    });
    is($res, "Edit complete: $ef", "edit_file accepts 'replacement' argument synonym");
    is(read_file_raw($ef), "Alpha\nGamma\n", "replacement applied using synonym key");
}

# 14. UTF-8 multi-byte support
{
    my $ef = write_temp_file("utf8_edit.txt", "こんにちは\n世界\nTiger\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 2,
        content    => "PowerPC Mac OS X\n",
    });
    is($res, "Edit complete: $ef", "edit_file UTF-8 replacement succeeds");
    is(read_file_raw($ef), "こんにちは\nPowerPC Mac OS X\nTiger\n", "UTF-8 content preserved and replaced");
}

# ==================================================================
# Task 3: System prompt documents tools, XML sections, and line-based usage
# ==================================================================
our $SYSTEM_PROMPT;
ok(defined $SYSTEM_PROMPT, "SYSTEM_PROMPT is defined");
like($SYSTEM_PROMPT, qr/<turn_economy>.*<\/turn_economy>/s, "SYSTEM_PROMPT defines <turn_economy> XML section");
like($SYSTEM_PROMPT, qr/<file_editing>.*<\/file_editing>/s, "SYSTEM_PROMPT defines <file_editing> XML section");
like($SYSTEM_PROMPT, qr/<tiger_env>.*<\/tiger_env>/s, "SYSTEM_PROMPT defines <tiger_env> XML section");
like($SYSTEM_PROMPT, qr/\bread_file\b/, "SYSTEM_PROMPT documents read_file");
like($SYSTEM_PROMPT, qr/\bwrite_file\b/, "SYSTEM_PROMPT documents write_file");
like($SYSTEM_PROMPT, qr/\bedit_file\b/, "SYSTEM_PROMPT documents edit_file");
like($SYSTEM_PROMPT, qr/\blist_dir\b/, "SYSTEM_PROMPT documents list_dir");
like($SYSTEM_PROMPT, qr/\brun_shell\b/, "SYSTEM_PROMPT documents run_shell");
like($SYSTEM_PROMPT, qr/start_line.*end_line/s, "SYSTEM_PROMPT mentions line slicing parameters");
like($SYSTEM_PROMPT, qr/prefer\s+`?edit_file`?\s+over\s+`?write_file`?/i, "SYSTEM_PROMPT explains when to prefer edit_file");
like($SYSTEM_PROMPT, qr/chaining|chained bash/i, "SYSTEM_PROMPT instructs chaining shell commands");
like($SYSTEM_PROMPT, qr/save turns|turn_economy/i, "SYSTEM_PROMPT explains turn economy rationale");

done_testing();
