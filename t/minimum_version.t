#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
my $checker_script = File::Spec->catfile($root_dir, 'scripts', 'check_minimum_version.pl');
my $code_agent_pl  = File::Spec->catfile($root_dir, 'code-agent.pl');
my $build_pl       = File::Spec->catfile($root_dir, 'build.pl');
my @src_files      = glob(File::Spec->catfile($root_dir, 'src', '*.pl'));

# Test 1: scripts/check_minimum_version.pl exists and compiles cleanly
ok(-f $checker_script, "scripts/check_minimum_version.pl exists");
my $syntax_out = `$^X -c "$checker_script" 2>&1`;
is($? >> 8, 0, "scripts/check_minimum_version.pl passes perl -c syntax check")
    or diag("Syntax check failed:\n$syntax_out");

# Test 2: Negative cases - verifying that checker catches Perl > 5.8.6 constructs
{
    my $tmp_dir = tempdir(CLEANUP => 1);

    # Case A: defined-or operator (Perl 5.10+)
    my $bad_defined_or = File::Spec->catfile($tmp_dir, 'bad_defined_or.pl');
    open my $fh, '>', $bad_defined_or or die $!;
    print $fh "#!/usr/bin/perl\nuse strict;\nmy \$a = \$b // 'default';\n";
    close $fh;

    my $out_a = `$^X "$checker_script" --perl 5.008006 "$bad_defined_or" 2>&1`;
    my $code_a = $? >> 8;
    isnt($code_a, 0, "checker fails on defined-or (//) operator");
    like($out_a, qr/defined-or|\/\/|exceeds|higher than|requires/i, "checker diagnostic mentions incompatibility for //");

    # Case B: 'say' statement (Perl 5.10+)
    my $bad_say = File::Spec->catfile($tmp_dir, 'bad_say.pl');
    open $fh, '>', $bad_say or die $!;
    print $fh "#!/usr/bin/perl\nuse strict;\nuse feature 'say';\nsay 'Hello World';\n";
    close $fh;

    my $out_b = `$^X "$checker_script" --perl 5.008006 "$bad_say" 2>&1`;
    my $code_b = $? >> 8;
    isnt($code_b, 0, "checker fails on 'say' statement");
    like($out_b, qr/say|exceeds|higher than|requires/i, "checker diagnostic mentions incompatibility for say");

    # Case C: 'state' variable (Perl 5.10+)
    my $bad_state = File::Spec->catfile($tmp_dir, 'bad_state.pl');
    open $fh, '>', $bad_state or die $!;
    print $fh "#!/usr/bin/perl\nuse strict;\nsub count { state \$c = 0; return ++\$c; }\n";
    close $fh;

    my $out_c = `$^X "$checker_script" --perl 5.008006 "$bad_state" 2>&1`;
    my $code_c = $? >> 8;
    isnt($code_c, 0, "checker fails on 'state' variable declaration");
    like($out_c, qr/state|exceeds|higher than|requires/i, "checker diagnostic mentions incompatibility for state");

    # Case D: explicit modern version requirement (e.g. use 5.010)
    my $bad_version = File::Spec->catfile($tmp_dir, 'bad_version.pl');
    open $fh, '>', $bad_version or die $!;
    print $fh "#!/usr/bin/perl\nuse 5.010;\nuse strict;\n1;\n";
    close $fh;

    my $out_d = `$^X "$checker_script" --perl 5.008006 "$bad_version" 2>&1`;
    my $code_d = $? >> 8;
    isnt($code_d, 0, "checker fails on explicit 'use 5.010'");
    like($out_d, qr/5\.010|version|exceeds|higher than|requires/i, "checker diagnostic mentions version excess");

    # Case E: smartmatch operator (Perl 5.10+)
    my $bad_smartmatch = File::Spec->catfile($tmp_dir, 'bad_smartmatch.pl');
    open $fh, '>', $bad_smartmatch or die $!;
    print $fh "#!/usr/bin/perl\nuse strict;\nif (\$a ~~ \@b) { print 1; }\n";
    close $fh;

    my $out_sm = `$^X "$checker_script" --perl 5.008006 "$bad_smartmatch" 2>&1`;
    my $code_sm = $? >> 8;
    isnt($code_sm, 0, "checker fails on smartmatch (~~) operator");
    like($out_sm, qr/smartmatch|~~|exceeds|higher than|requires/i, "checker diagnostic mentions incompatibility for smartmatch");

    # Case F: Valid Perl 5.8.6 construct passes
    my $good_script = File::Spec->catfile($tmp_dir, 'good.pl');
    open $fh, '>', $good_script or die $!;
    print $fh "#!/usr/bin/perl\nuse strict;\nuse warnings;\nmy \$x = defined(\$b) ? \$b : 'default';\nprint \$x, \"\\n\";\n1;\n";
    close $fh;

    my $out_e = `$^X "$checker_script" --perl 5.008006 "$good_script" 2>&1`;
    my $code_e = $? >> 8;
    is($code_e, 0, "checker succeeds on valid Perl 5.8.6 code")
        or diag("Check failed:\n$out_e");

    # Case G: Short version formats like 5.8 and 5.10 normalization
    my $out_short_ver = `$^X "$checker_script" --perl 5.8 "$good_script" 2>&1`;
    is($? >> 8, 0, "checker handles short version format --perl 5.8 successfully");
}

# Test 3: Actual repository source files verification via checker
{
    my @target_files = ($code_agent_pl, $build_pl, $checker_script, @src_files);
    my $files_arg = join(' ', map { qq{"$_"} } @target_files);
    my $cmd = qq{$^X "$checker_script" --perl 5.008006 $files_arg 2>&1};
    my $out = `$cmd`;
    my $code = $? >> 8;

    is($code, 0, "All codebase source files (code-agent.pl, build.pl, checker, src/*.pl) satisfy Perl <= 5.8.6")
        or diag("Compatibility check failure:\n$out");
}

# Test 4: If Perl::MinimumVersion is available in this environment, verify via CPAN module directly
SKIP: {
    eval "use Perl::MinimumVersion 1.20; use version; 1;";
    skip "Perl::MinimumVersion not installed locally (will run in CI)", scalar(@src_files) + 3 if $@;

    my $target_ver = version->parse('5.008006');
    for my $file ($code_agent_pl, $build_pl, $checker_script, @src_files) {
        my $bname = File::Basename::basename($file);
        my $pmv = Perl::MinimumVersion->new($file);
        my $ver = $pmv->minimum_version;
        cmp_ok($ver, '<=', $target_ver, "$bname requires Perl $ver <= 5.008006 via Perl::MinimumVersion");
    }
}

done_testing();
