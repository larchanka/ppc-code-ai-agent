#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename qw(basename);

my $target_str = '5.008006';
my $blame = 0;
my $help = 0;

GetOptions(
    'perl=s'  => \$target_str,
    'blame'   => \$blame,
    'help|h'  => \$help,
) or die "Error: Invalid command line arguments. Use --help for usage.\n";

if ($help || !@ARGV) {
    print <<"USAGE";
Usage: $0 [OPTIONS] <files...>

Check Perl source files for compatibility with target minimum Perl version.

Options:
  --perl VERSION    Target minimum version (default: 5.008006 / 5.8.6)
  --blame           Show detailed rule attribution if available
  -h, --help        Show this help message
USAGE
    exit(defined $help && $help ? 0 : 1);
}

my @files = @ARGV;

# Normalize target version string (e.g. 5.8.6 -> 5.008006)
my $target_num = normalize_version($target_str);

# Check if Perl::MinimumVersion is available
my $has_pmv = 0;
eval {
    require Perl::MinimumVersion;
    require version;
    $has_pmv = 1;
};

my $failed = 0;
my $target_ver_obj = $has_pmv ? version->parse(sprintf("%.6f", $target_num)) : undef;

for my $file (@files) {
    if (!-f $file) {
        warn "Warning: File not found: '$file'\n";
        next;
    }

    if ($has_pmv) {
        my $pmv = Perl::MinimumVersion->new($file);
        if (!$pmv) {
            warn "Error: Could not parse '$file' with Perl::MinimumVersion\n";
            $failed = 1;
            next;
        }

        my $ver = $pmv->minimum_version;
        if ($ver > $target_ver_obj) {
            warn "FAIL: $file requires Perl $ver (exceeds target $target_str)\n";
            $failed = 1;

            if ($blame) {
                # Attempt to run perlver --blame if available
                system("perlver", "--blame", $file);
            }
        } else {
            # Passed
        }
    } else {
        # Pure-Perl fallback static inspection
        my ($ok, $reasons) = static_check_file($file, $target_num);
        if (!$ok) {
            warn "FAIL: $file requires Perl higher than $target_str:\n";
            for my $r (@$reasons) {
                warn "  Line $r->{line}: [$r->{rule}] $r->{text}\n";
            }
            $failed = 1;
        }
    }
}

if ($failed) {
    print STDERR "\nPerl $target_str compatibility check FAILED.\n";
    exit 1;
}

print "OK: All files satisfy Perl <= $target_str" . ($has_pmv ? " (verified via Perl::MinimumVersion)" : " (verified via pure-Perl static scanner)") . "\n";
exit 0;

sub normalize_version {
    my ($v) = @_;
    if ($v =~ /^v?5\.(\d+)\.(\d+)$/) {
        return sprintf("5.%03d%03d", $1, $2) + 0;
    }
    if ($v =~ /^v?5\.([1-9]\d?)$/) {
        return sprintf("5.%03d000", $1) + 0;
    }
    if ($v =~ /^v?5\.(\d{3})(\d{3})$/) {
        return sprintf("5.%03d%03d", $1, $2) + 0;
    }
    if ($v =~ /^v?5\.(\d{3})$/) {
        return sprintf("5.%03d000", $1) + 0;
    }
    return $v + 0;
}

sub static_check_file {
    my ($file, $target) = @_;
    open my $fh, '<', $file or return (0, [{ line => 0, rule => 'io', text => "Cannot open $file: $!" }]);

    my @violations;
    my $line_no = 0;

    while (my $line = <$fh>) {
        $line_no++;

        # Skip pod blocks
        if ($line =~ /^=(?:head\d|pod|item|over|back|begin|end)/) {
            while (my $pod = <$fh>) {
                $line_no++;
                last if $pod =~ /^=cut/;
            }
            next;
        }

        # Check explicit use version
        if ($line =~ /^\s*use\s+(v?5\.[0-9_.]+)\s*;/i) {
            my $req_str = $1;
            $req_str =~ s/_//g;
            my $req_num = normalize_version($req_str);
            if ($req_num > $target) {
                chomp(my $t = $line);
                push @violations, {
                    line => $line_no,
                    rule => 'explicit_version',
                    text => "Explicit version requirement exceeds target ($t)",
                };
            }
            next;
        }

        # Replace string literal contents with placeholders to preserve token structure
        my $clean = $line;
        $clean =~ s/'(?:\\.|[^'])*'/'STR'/g;
        $clean =~ s/"(?:\\.|[^"])*"/"STR"/g;
        $clean =~ s/`[^`]*`/`STR`/g;
        # Remove comments
        $clean =~ s/#.*$//;

        # Remove regex substitutions and match expressions
        $clean =~ s/s(?:\/(\\.|[^\/])*\/(\\.|[^\/])*\/|\{(\\.|[^}])*\}\{(\\.|[^}])*\}|\[(\\.|[^\]])*\]\[(\\.|[^\]])*\])[a-z]*//g;
        $clean =~ s/(?:m|qr)(?:\/(\\.|[^\/])*\/|\{(\\.|[^}])*\}|\[(\\.|[^\]])*\])[a-z]*//g;
        $clean =~ s/tr(?:\/(\\.|[^\/])*\/(\\.|[^\/])*\/|\{(\\.|[^}])*\}\{(\\.|[^}])*\}|\[(\\.|[^\]])*\]\[(\\.|[^\]])*\])[a-z]*//g;
        $clean =~ s/(?:=~|!~)\s*\/(\\.|[^\/])*\///g;
        $clean =~ s/\bsplit\s*\/[^\/]*\///g;

        # 1. 'say' statement (Perl 5.10+)
        if ($clean =~ /\b(?:say)\s+[^\s=~]/) {
            chomp(my $t = $line);
            $t =~ s/^\s+|\s+$//g;
            push @violations, {
                line => $line_no,
                rule => 'feature_say',
                text => "The 'say' keyword requires Perl 5.10+ ($t)",
            };
        }

        # 2. 'state' variables (Perl 5.10+)
        if ($clean =~ /\b(?:state)\s+[\$\@\%]/) {
            chomp(my $t = $line);
            $t =~ s/^\s+|\s+$//g;
            push @violations, {
                line => $line_no,
                rule => 'feature_state',
                text => "The 'state' variable declaration requires Perl 5.10+ ($t)",
            };
        }

        # 3. Defined-or operator '//' or '//=' (Perl 5.10+)
        if ($clean =~ /(\/\/=)/ ||
            $clean =~ /(?:\$|\@|\%|\)|\]|\}|[a-zA-Z0-9_\'\"])\s*(\/\/)\s*(?:\$|\@|\%|\(|\[|\{|[a-zA-Z0-9_\'\"])/) {
            my $op = $1 || '//';
            chomp(my $t = $line);
            $t =~ s/^\s+|\s+$//g;
            push @violations, {
                line => $line_no,
                rule => 'operator_defined_or',
                text => "The defined-or operator ($op) requires Perl 5.10+ ($t)",
            };
        }

        # 4. Smartmatch operator '~~' (Perl 5.10+)
        if ($clean =~ /\x7e\x7e\s*[^\s]/) {
            chomp(my $t = $line);
            $t =~ s/^\s+|\s+$//g;
            push @violations, {
                line => $line_no,
                rule => 'operator_smartmatch',
                text => "The smartmatch operator (\x7e\x7e) requires Perl 5.10+ ($t)",
            };
        }

        # 5. Postfix dereference (Perl 5.20+)
        if ($clean =~ /->\s*[\$\@\%\*\&]\*/) {
            chomp(my $t = $line);
            $t =~ s/^\s+|\s+$//g;
            push @violations, {
                line => $line_no,
                rule => 'postfix_deref',
                text => "Postfix dereference requires Perl 5.20+ ($t)",
            };
        }
    }

    close $fh;
    return (@violations ? (0, \@violations) : (1, []));
}
