#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
my $build_script = File::Spec->catfile($root_dir, 'build.pl');

# Test 1: build.pl exists and passes syntax check
ok(-f $build_script, "build.pl exists");
my $syntax_output = `$^X -c "$build_script" 2>&1`;
my $syntax_code = $? >> 8;
is($syntax_code, 0, "build.pl compiles cleanly (perl -c)")
    or diag("Syntax check failed:\n$syntax_output");

# Test 2: Execution without existing src/ fails with non-zero exit code
{
    my $tmp_empty = tempdir(CLEANUP => 1);
    my $cmd = qq{$^X "$build_script" --src-dir "$tmp_empty/nonexistent_src" --output "$tmp_empty/out.pl" 2>&1};
    my $out = `$cmd`;
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, "build.pl fails with non-zero exit code when source files missing");
    like($out, qr/Missing source file|Error/i, "build.pl outputs descriptive error on missing source file");
}

# Test 3: Successful build with mock modules
{
    my $tmp_dir = tempdir(CLEANUP => 1);
    my $mock_src = File::Spec->catdir($tmp_dir, 'src');
    mkdir $mock_src or die "Cannot mkdir $mock_src: $!";

    my @manifest = (
        'header.pl',
        'prompts.pl',
        'json.pl',
        'transport.pl',
        'providers.pl',
        'models_menu.pl',
        'session_store.pl',
        'session.pl',
        'sessions_menu.pl',
        'tools.pl',
        'mcp.pl',
        'terminal.pl',
        'markdown.pl',
        'ui.pl',
        'main.pl',
    );

    for my $i (0 .. $#manifest) {
        my $fname = $manifest[$i];
        my $fpath = File::Spec->catfile($mock_src, $fname);
        open my $fh, '>', $fpath or die "Cannot write $fpath: $!";
        if ($fname eq 'header.pl') {
            print $fh "#!/usr/bin/perl\nuse strict;\nuse warnings;\n# Header module\nour \$VERSION = '1.0';\n";
        } elsif ($fname eq 'main.pl') {
            print $fh "#!/usr/bin/perl\n# Main entrypoint\nprint \"Hello from code-agent\\n\" unless caller;\n1;\n";
        } else {
            print $fh "#!/usr/bin/perl\n# Module $fname\nour \$VAR_$i = $i;\n1;\n";
        }
        close $fh;
    }

    my $out_file = File::Spec->catfile($tmp_dir, 'code-agent.pl');

    # Execute build
    my $cmd = qq{$^X "$build_script" --src-dir "$mock_src" --output "$out_file" 2>&1};
    my $out = `$cmd`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, "build.pl exits with code 0 on successful build")
        or diag("Output:\n$out");
    ok(-f $out_file, "Output file was created");
    ok(-x $out_file, "Output file has executable permissions");

    # Verify content structure
    open my $fh, '<', $out_file or die "Cannot read $out_file: $!";
    my $first_line = <$fh>;
    is($first_line, "#!/usr/bin/perl\n", "First line is shebang");

    my $content = do { local $/; <$fh> };
    close $fh;

    # Shebang should only occur once at the top of the file
    my @shebang_matches = ($content =~ /^#!/mg);
    is(scalar(@shebang_matches), 0, "No duplicate shebang lines in body");

    # Check delimiter comments
    for my $fname (@manifest) {
        like($content, qr/# --- BEGIN src\/$fname ---/, "Contains delimiter for $fname");
    }

    # Verify syntax of generated file
    my $chk_out = `$^X -c "$out_file" 2>&1`;
    is($? >> 8, 0, "Generated file passes perl -c syntax check")
        or diag("Check failed:\n$chk_out");

    # Test 4: --check option
    # 4a. When in sync, --check returns 0
    my $check_cmd = qq{$^X "$build_script" --src-dir "$mock_src" --output "$out_file" --check 2>&1};
    my $check_out = `$check_cmd`;
    is($? >> 8, 0, "--check returns 0 when output is in sync with sources");

    # 4b. When modified / out of sync, --check returns non-zero
    open my $afh, '>>', $out_file or die "Cannot append: $!";
    print $afh "\n# Manual modification\n";
    close $afh;

    my $check_out2 = `$check_cmd`;
    isnt($? >> 8, 0, "--check returns non-zero when output differs from source");
}

# Test 5: Build failure when source module has invalid syntax
{
    my $tmp_dir = tempdir(CLEANUP => 1);
    my $mock_src = File::Spec->catdir($tmp_dir, 'src');
    mkdir $mock_src or die "Cannot mkdir $mock_src: $!";

    my @manifest = (
        'header.pl', 'prompts.pl', 'json.pl', 'transport.pl', 'providers.pl', 'models_menu.pl',
        'session_store.pl', 'session.pl', 'sessions_menu.pl', 'tools.pl', 'mcp.pl', 'terminal.pl', 'markdown.pl', 'ui.pl', 'main.pl',
    );

    for my $fname (@manifest) {
        my $fpath = File::Spec->catfile($mock_src, $fname);
        open my $fh, '>', $fpath or die "Cannot write $fpath: $!";
        if ($fname eq 'header.pl') {
            print $fh "#!/usr/bin/perl\nuse strict;\nthis is invalid perl syntax !!!;\n";
        } else {
            print $fh "1;\n";
        }
        close $fh;
    }

    my $out_file = File::Spec->catfile($tmp_dir, 'code-agent.pl');
    my $cmd = qq{$^X "$build_script" --src-dir "$mock_src" --output "$out_file" 2>&1};
    my $out = `$cmd`;
    my $exit_code = $? >> 8;

    isnt($exit_code, 0, "build.pl fails when generated code fails syntax check");
    like($out, qr/syntax check failed|syntax error/i, "Output indicates syntax check failure");
}

# Test 6: Install.command integration
{
    my $install_cmd_file = File::Spec->catfile($root_dir, 'Install.command');
    ok(-f $install_cmd_file, "Install.command exists");

    # Check bash syntax
    my $syntax_out = `bash -n "$install_cmd_file" 2>&1`;
    is($? >> 8, 0, "Install.command passes bash -n syntax check")
        or diag("bash -n failed:\n$syntax_out");

    open my $ifh, '<', $install_cmd_file or die "Cannot read $install_cmd_file: $!";
    my $content = do { local $/; <$ifh> };
    close $ifh;

    like($content, qr/if\s+\[\s+-f\s+["']?build\.pl["']?\s+\]\s+&&\s+\[\s+-d\s+["']?src["']?\s+\];\s*then/s,
         "Install.command checks for build.pl and src/");
    like($content, qr/perl\s+build\.pl/, "Install.command executes perl build.pl");
}

# Test 7: modern-install.command integration
{
    my $modern_cmd_file = File::Spec->catfile($root_dir, 'modern-install.command');
    ok(-f $modern_cmd_file, "modern-install.command exists");
    ok(-x $modern_cmd_file, "modern-install.command is executable");

    # Check bash syntax
    my $syntax_out = `bash -n "$modern_cmd_file" 2>&1`;
    is($? >> 8, 0, "modern-install.command passes bash -n syntax check")
        or diag("bash -n failed:\n$syntax_out");

    open my $mfh, '<', $modern_cmd_file or die "Cannot read $modern_cmd_file: $!";
    my $content = do { local $/; <$mfh> };
    close $mfh;

    like($content, qr/command\s+-v\s+curl/, "modern-install.command checks for system curl");
    like($content, qr/command\s+-v\s+perl/, "modern-install.command checks for system perl");
    like($content, qr/if\s+\[\s+-f\s+["']?build\.pl["']?\s+\]\s+&&\s+\[\s+-d\s+["']?src["']?\s+\];\s*then/s,
         "modern-install.command checks for build.pl and src/");
    like($content, qr/perl\s+build\.pl/, "modern-install.command executes perl build.pl");
}

done_testing();
