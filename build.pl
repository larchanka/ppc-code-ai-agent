#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use File::Basename qw(dirname basename);
use Getopt::Long qw(GetOptions);

my @MODULES = (
    'src/header.pl',
    'src/prompts.pl',
    'src/json.pl',
    'src/transport.pl',
    'src/providers.pl',
    'src/models_menu.pl',
    'src/session.pl',
    'src/tools.pl',
    'src/terminal.pl',
    'src/markdown.pl',
    'src/ui.pl',
    'src/main.pl',
);

my $output_file;
my $src_dir;
my $check_only = 0;
my $help = 0;

Getopt::Long::Configure("bundling");
GetOptions(
    'output|o=s'  => \$output_file,
    'src-dir|s=s' => \$src_dir,
    'check|c'     => \$check_only,
    'help|h'      => \$help,
) or die "Error: Invalid command line arguments. Use --help for usage.\n";

if ($help) {
    print <<"USAGE";
Usage: $0 [OPTIONS]

Assemble modular source files into standalone code-agent.pl.

Options:
  -o, --output FILE   Output path for assembled script (default: code-agent.pl)
  -s, --src-dir DIR   Source directory for modules (default: src/)
  -c, --check         Verify output matches modules without overwriting
  -h, --help          Display this help message
USAGE
    exit 0;
}

my $script_dir = dirname(File::Spec->rel2abs($0));
if (!defined $output_file || $output_file eq '') {
    $output_file = File::Spec->catfile($script_dir, 'code-agent.pl');
}
if (!defined $src_dir || $src_dir eq '') {
    $src_dir = File::Spec->catdir($script_dir, 'src');
}

# Resolve full module paths and check existence
my @resolved_files;
for my $mod (@MODULES) {
    my $bname = basename($mod);
    my $path;
    if (-f File::Spec->catfile($src_dir, $mod)) {
        $path = File::Spec->catfile($src_dir, $mod);
    } elsif (-f File::Spec->catfile($src_dir, $bname)) {
        $path = File::Spec->catfile($src_dir, $bname);
    } else {
        my $expected = File::Spec->catfile($src_dir, $bname);
        die "Error: Missing source file: '$expected'\n";
    }
    push @resolved_files, { name => $mod, bname => $bname, path => $path };
}

# Concatenate modules in manifest order
my $assembled = "#!/usr/bin/perl\n";
for my $item (@resolved_files) {
    my $mod_name = $item->{name};
    my $mod_path = $item->{path};

    open my $fh, '<', $mod_path or die "Error: Cannot read source file '$mod_path': $!\n";
    binmode $fh;
    my $content = do { local $/; <$fh> };
    close $fh;

    # Strip shebang line if present at start of module
    $content =~ s/\A#!.*?\n//;

    # Append delimited section
    $assembled .= "# --- BEGIN $mod_name ---\n";
    $assembled .= $content;
    $assembled .= "\n" unless $assembled =~ /\n\z/;
    $assembled .= "# --- END $mod_name ---\n\n";
}

# If --check was requested, compare against current output file
if ($check_only) {
    if (!-f $output_file) {
        die "Error: Output file '$output_file' does not exist for --check.\n";
    }
    open my $cfh, '<', $output_file or die "Error: Cannot read '$output_file': $!\n";
    binmode $cfh;
    my $existing = do { local $/; <$cfh> };
    close $cfh;

    if ($existing eq $assembled) {
        print "$output_file is up to date.\n";
        exit 0;
    } else {
        die "Error: $output_file is out of date with source modules.\n";
    }
}

# Write atomically via temp file
my $tmp_file = "$output_file.tmp.$$";
open my $out_fh, '>', $tmp_file or die "Error: Cannot open temporary file '$tmp_file' for writing: $!\n";
binmode $out_fh;
print $out_fh $assembled;
close $out_fh or die "Error: Cannot close temporary file '$tmp_file': $!\n";

chmod 0755, $tmp_file;

# Run syntax check on the assembled code before committing
my $check_cmd = qq{"$^X"} . ' -c ' . qq{"$tmp_file"} . ' 2>&1';
my $syntax_out = `$check_cmd`;
my $syntax_exit = $? >> 8;
if ($syntax_exit != 0) {
    unlink $tmp_file;
    die "Error: Generated file syntax check failed:\n$syntax_out\n";
}

# Replace destination file atomically
if (!rename($tmp_file, $output_file)) {
    unlink $tmp_file;
    die "Error: Cannot rename '$tmp_file' to '$output_file': $!\n";
}

chmod 0755, $output_file;
print "Built $output_file successfully (syntax OK).\n";
exit 0;
