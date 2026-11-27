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

# 15. Schema property: target exists
{
    ok($edit_props->{target}, "target property exists in schema");
    is($edit_props->{target}{type}, 'string', "target is string type");
}

# 16. Content-targeted replacement (without line numbers)
{
    my $ef = write_temp_file("target_edit.txt", "alpha = 1\nbeta = 2\ngamma = 3\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path    => $ef,
        target  => "beta = 2\n",
        content => "beta = 42\n",
    });
    is($res, "Edit complete: $ef", "edit_file target replacement succeeds");
    is(read_file_raw($ef), "alpha = 1\nbeta = 42\ngamma = 3\n", "targeted block replaced cleanly without line numbers");
}

# 17. Target not found error
{
    my $ef = write_temp_file("target_miss.txt", "one\ntwo\nthree\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path    => $ef,
        target  => "four\n",
        content => "five\n",
    });
    like($res, qr/Error: target text not found/i, "edit_file returns error when target text not found");
}

# 18. Target ambiguous error (multiple occurrences)
{
    my $ef = write_temp_file("target_multi.txt", "item = 1\nitem = 1\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path    => $ef,
        target  => "item = 1",
        content => "item = 2",
    });
    like($res, qr/Error: target text appears 2 times/i, "edit_file rejects ambiguous target occurring multiple times");
}

# 19. Line-based editing with matching target verification
{
    my $ef = write_temp_file("line_target_ok.txt", "line A\nline B\nline C\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 2,
        target     => "line B\n",
        content    => "line B_modified\n",
    });
    is($res, "Edit complete: $ef", "edit_file succeeds when target matches line range");
    is(read_file_raw($ef), "line A\nline B_modified\nline C\n", "line verified and replaced");
}

# 20. Line-drift auto-relocation with unique target
{
    my $ef = write_temp_file("line_drift.txt", "header\ninserted 1\ninserted 2\nold_line\nfooter\n");
    set_auto_mode(1);

    # Target 'old_line\n' is now at line 4, but caller passed stale line 2
    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 2,
        end_line   => 2,
        target     => "old_line\n",
        content    => "new_line\n",
    });
    is($res, "Edit complete: $ef", "edit_file auto-relocates when target shifted due to line drift");
    is(read_file_raw($ef), "header\ninserted 1\ninserted 2\nnew_line\nfooter\n", "shifted line correctly updated at relocated position");
}

# 21. Target mismatch error when target does not match and is not found
{
    my $ef = write_temp_file("line_mismatch.txt", "line 1\nline 2\nline 3\n");
    set_auto_mode(1);

    my $res = run_tool('edit_file', {
        path       => $ef,
        start_line => 1,
        end_line   => 1,
        target     => "non_existent_target\n",
        content    => "replacement\n",
    });
    like($res, qr/Error: target text does not match lines 1-1/i, "edit_file rejects edit on target mismatch");
    is(read_file_raw($ef), "line 1\nline 2\nline 3\n", "file content remains unmodified after mismatch error");
}

# ==================================================================
# Task 3: System prompt documents tools, XML sections, and line-based usage
# ==================================================================
our $SYSTEM_PROMPT;
ok(defined $SYSTEM_PROMPT, "SYSTEM_PROMPT is defined");
like($SYSTEM_PROMPT, qr/<turn_economy>.*<\/turn_economy>/s, "SYSTEM_PROMPT defines <turn_economy> XML section");
like($SYSTEM_PROMPT, qr/<file_editing>.*<\/file_editing>/s, "SYSTEM_PROMPT defines <file_editing> XML section");
like($SYSTEM_PROMPT, qr/<tool_boundaries>.*<\/tool_boundaries>/s, "SYSTEM_PROMPT defines <tool_boundaries> XML section");
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

# ==================================================================
# Task 4: _arg_parse_error guard, parameter aliases, pre-confirm validation, and auto-mkdir
# ==================================================================

# 1. _arg_parse_error short-circuits run_tool before confirm_tool
{
    set_auto_mode(0);
    my $confirm_called = 0;
    no warnings 'redefine';
    local *confirm = sub { $confirm_called++; return 1; };

    my $openai_resp = {
        choices => [
            {
                message => {
                    tool_calls => [
                        {
                            id       => 'call_trunc_1',
                            function => {
                                name      => 'write_file',
                                arguments => '{"path":"foo.txt","content":"unterminated',
                            },
                        },
                    ],
                },
            },
        ],
    };
    my @blocks = parse_response_openai($openai_resp);
    is(scalar(@blocks), 1, "parse_response_openai returned 1 tool_use block for truncated args");
    ok(exists $blocks[0]{input}{_arg_parse_error}, "_arg_parse_error is populated on truncated JSON arguments");

    my $res = run_tool($blocks[0]{name}, $blocks[0]{input});
    like(
        $res,
        qr/^Error: tool arguments for 'write_file' were truncated or invalid JSON\b/,
        "run_tool rejects _arg_parse_error with actionable message"
    );
    is($confirm_called, 0, "confirm() was not called when _arg_parse_error is present");
}

# 2. Pre-confirmation validation with zero Perl warnings
{
    set_auto_mode(0);
    my $confirm_called = 0;
    no warnings 'redefine';
    local *confirm = sub { $confirm_called++; return 1; };

    my @warnings_caught;
    local $SIG{__WARN__} = sub { push @warnings_caught, $_[0]; };

    is(
        run_tool('read_file', {}),
        "Error: missing required 'path' parameter",
        "read_file with missing path returns clear error"
    );
    is(
        run_tool('write_file', { content => 'hello' }),
        "Error: missing required 'path' parameter",
        "write_file with missing path returns clear error before confirm"
    );
    is(
        run_tool('write_file', { path => "$temp_dir/no_content.txt" }),
        "Error: missing required 'content' parameter",
        "write_file with missing content returns clear error before confirm"
    );
    is(
        run_tool('edit_file', { start_line => 1, end_line => 1, content => 'x' }),
        "Error: missing required 'path' parameter",
        "edit_file with missing path returns clear error"
    );
    is(
        run_tool('run_shell', {}),
        "Error: missing required 'command' parameter",
        "run_shell with missing command returns clear error before confirm"
    );
    is($confirm_called, 0, "confirm() was never called when required parameters were missing");
    is(scalar(@warnings_caught), 0, "zero Perl uninitialized value warnings on missing parameters");
}

# 3. Parameter aliases in read_file, write_file, edit_file, list_dir, run_shell
{
    set_auto_mode(1);
    my $alias_file = "$temp_dir/alias_target.txt";

    # write_file with file_path + text
    my $w_res = run_tool('write_file', { file_path => $alias_file, text => "Line A\nLine B\n" });
    is($w_res, "Write complete: $alias_file", "write_file succeeds with file_path and text aliases");
    is(read_file_raw($alias_file), "Line A\nLine B\n", "write_file wrote expected content via aliases");

    # write_file with filepath + data
    my $w_res2 = run_tool('write_file', { filepath => $alias_file, data => "Data 1\nData 2\n" });
    is($w_res2, "Write complete: $alias_file", "write_file succeeds with filepath and data aliases");

    # write_file with filename + body
    my $w_res3 = run_tool('write_file', { filename => $alias_file, body => "Body 1\nBody 2\n" });
    is($w_res3, "Write complete: $alias_file", "write_file succeeds with filename and body aliases");

    # read_file with file_path / filepath / filename / file
    is(run_tool('read_file', { file_path => $alias_file }), "Body 1\nBody 2\n", "read_file supports file_path alias");
    is(run_tool('read_file', { filepath  => $alias_file }), "Body 1\nBody 2\n", "read_file supports filepath alias");
    is(run_tool('read_file', { filename  => $alias_file }), "Body 1\nBody 2\n", "read_file supports filename alias");
    is(run_tool('read_file', { file      => $alias_file }), "Body 1\nBody 2\n", "read_file supports file alias");

    # edit_file with file_path + new_text / text
    my $e_res = run_tool('edit_file', {
        file_path  => $alias_file,
        start_line => 2,
        end_line   => 2,
        new_text   => "Body 2 updated\n",
    });
    is($e_res, "Edit complete: $alias_file", "edit_file supports file_path and new_text aliases");
    is(read_file_raw($alias_file), "Body 1\nBody 2 updated\n", "edit_file updated line via new_text alias");

    my $e_res2 = run_tool('edit_file', {
        file       => $alias_file,
        start_line => 1,
        end_line   => 1,
        text       => "Body 1 updated\n",
    });
    is($e_res2, "Edit complete: $alias_file", "edit_file supports file and text aliases");
    is(read_file_raw($alias_file), "Body 1 updated\nBody 2 updated\n", "edit_file updated line via text alias");

    # list_dir with dir / directory / file_path
    my $ld_res = run_tool('list_dir', { dir => $temp_dir });
    like($ld_res, qr/alias_target\.txt/, "list_dir supports dir alias");

    # run_shell with cmd
    my $sh_res = run_tool('run_shell', { cmd => 'echo alias_shell_ok' });
    like($sh_res, qr/alias_shell_ok/, "run_shell supports cmd alias");
}

# 4. Auto-create missing parent directories in write_file
{
    set_auto_mode(1);
    my $nested_path = "$temp_dir/deep/nested/dir/plan.md";
    ok(!-d "$temp_dir/deep", "parent directory does not exist before write_file");

    my $res = run_tool('write_file', {
        path    => $nested_path,
        content => "# Nested Plan\n",
    });
    is($res, "Write complete: $nested_path", "write_file auto-creates missing parent directories");
    ok(-f $nested_path, "nested file exists after write_file");
    is(read_file_raw($nested_path), "# Nested Plan\n", "nested file content matches");

    # Parent directory creation is skipped when user cancels confirmation
    set_auto_mode(0);
    my $cancelled_nested = "$temp_dir/unapproved_dir/sub/file.txt";
    no warnings 'redefine';
    local *confirm = sub { return 0; };
    my $cancel_res = run_tool('write_file', {
        path    => $cancelled_nested,
        content => "should not write\n",
    });
    is($cancel_res, "Cancelled by user.", "write_file cancelled by user for nested path");
    ok(!-d "$temp_dir/unapproved_dir", "parent directory was NOT created when user cancelled write_file");
    set_auto_mode(1);
}

# 5. Zero stderr leakage in run_shell on chained commands and shell keywords (time)
{
    set_auto_mode(1);

    # Capture STDERR while executing run_shell to verify zero stderr leakage to terminal
    my $stderr_captured = '';
    my $out_captured;
    {
        my $tmp_err = "$temp_dir/stderr_leak_test.log";
        open(my $saved_err, ">&STDERR") or die "cannot dup STDERR: $!";
        open(STDERR, '>', $tmp_err) or die "cannot redirect STDERR: $!";

        $out_captured = run_tool('run_shell', {
            command => 'echo "chained_err_1" >&2 && echo "chained_out_2"',
        });

        open(STDERR, ">&", $saved_err);
        close $saved_err;

        $stderr_captured = read_file_raw($tmp_err);
        unlink $tmp_err;
    }

    is($stderr_captured, '', "run_shell does not leak stderr to terminal on chained commands (&&)");
    like($out_captured, qr/chained_err_1/, "run_shell captures stderr from preceding chained command into result");
    like($out_captured, qr/chained_out_2/, "run_shell captures stdout from final chained command into result");

    # time keyword in bash/sh
    {
        my $tmp_err2 = "$temp_dir/time_leak_test.log";
        open(my $saved_err2, ">&STDERR") or die "cannot dup STDERR: $!";
        open(STDERR, '>', $tmp_err2) or die "cannot redirect STDERR: $!";

        my $time_res = run_tool('run_shell', {
            command => 'time echo "time_test_ok"',
        });

        open(STDERR, ">&", $saved_err2);
        close $saved_err2;

        my $time_err = read_file_raw($tmp_err2);
        unlink $tmp_err2;

        is($time_err, '', "run_shell does not leak time keyword stderr to terminal");
        like($time_res, qr/time_test_ok/, "run_shell captures command output when using time");
        like($time_res, qr/(?:real\s+\d|\belapsed\b|\buser\b)/m, "run_shell captures time keyword stats into result");
    }
}

done_testing();
