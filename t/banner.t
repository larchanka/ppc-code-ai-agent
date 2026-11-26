#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More tests => 18;

use File::Basename qw(dirname);
use Cwd qw(abs_path);

binmode Test::More->builder->output,         ':encoding(UTF-8)' if Test::More->builder->can('output');
binmode Test::More->builder->failure_output, ':encoding(UTF-8)' if Test::More->builder->can('failure_output');
binmode Test::More->builder->todo_output,    ':encoding(UTF-8)' if Test::More->builder->can('todo_output');

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our ($PROVIDER, $MODEL, $AUTO_MODE, $API_URL, $VERSION);
our ($COLOR_RESET, $COLOR_CODE, $COLOR_GRAY, $STYLE_BOLD, $COLOR_DIM, $COLOR_MODEL);

# Test 1: show_banner output with default provider, model, and new Option B mascot
{
    $ENV{GEMINI_API_KEY} = "AIzaSyTestKey123";
    delete $ENV{CLAUDE_MODEL};
    configure_provider('gemini');
    set_auto_mode(0);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\xe2\x96\x88\xc2\xb7\xe2\x96\x88\xc2\xb7\xe2\x96\x88/, "Banner contains mascot body (█·█·█)");
    like($out, qr/CodeAgent v\d+\.\d+\.\d+/, "Banner contains CodeAgent title and version");
    like($out, qr/\xe2\x96\x80 \xe2\x96\x80\s+AI everywhere/, "Banner contains mascot legs (▀ ▀) and tagline");
    like($out, qr/\[gemini \/ gemini-3\.5-flash-lite\]  mode: manual/, "Status line includes provider, model, and manual mode");
    like($out, qr/Type \/help for commands, \/models to switch model\./, "Includes help instructions");
}

# Test 2: show_banner with auto mode
{
    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test";
    $ENV{CLAUDE_MODEL} = "claude-3-5-sonnet";
    configure_provider('anthropic');
    set_auto_mode(1);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\[anthropic \/ claude-3-5-sonnet\]  mode: auto/, "Status line reflects auto mode");
}

# Test 3: show_banner with openai and endpoint host
{
    $ENV{OPENAI_BASE_URL} = "http://192.168.1.50:8080/v1";
    $ENV{CLAUDE_MODEL} = "llama3";
    configure_provider('openai');
    set_auto_mode(0);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\[openai \/ llama3 \@ 192\.168\.1\.50:8080\]  mode: manual/, "OpenAI host displayed in status line");
}

# Test 4: handles undefined values gracefully
{
    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/mode: (?:manual|auto)/, "Handles banner status display");
}

# Test 5: verify line bounds (all lines fit comfortably within 80 columns)
{
    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    my $max_len = 0;
    for my $line (split /\n/, $out) {
        my $clean = $line;
        $clean =~ s/\x1b\[[0-9;]*m//g;
        $max_len = length($clean) if length($clean) > $max_len;
    }
    cmp_ok($max_len, '<=', 80, "All banner lines fit comfortably within 80 columns");
}

# Test 6: ANSI color emission for Option B (bold blue body & title, gray version & tagline, blue legs)
{
    local $STYLE_BOLD  = "\x1b[1m";
    local $COLOR_CODE  = "\x1b[34m";
    local $COLOR_GRAY  = "\x1b[90m";
    local $COLOR_RESET = "\x1b[0m";

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    # Body in bold blue: \x1b[1m\x1b[34m...
    like($out, qr/\x1b\[1m\x1b\[34m\xe2\x96\x88\xc2\xb7\xe2\x96\x88\xc2\xb7\xe2\x96\x88\x1b\[0m/, "Mascot body emitted in bold blue");
    like($out, qr/\x1b\[1m\x1b\[34mCodeAgent\x1b\[0m \x1b\[90mv\d+\.\d+\.\d+\x1b\[0m/, "Title in bold blue and version in gray");
    like($out, qr/\x1b\[34m \xe2\x96\x80 \xe2\x96\x80 \x1b\[0m  \x1b\[90mAI everywhere\x1b\[0m/, "Mascot legs in blue and tagline in gray");
}

# Test 7: Graceful degradation when colors are empty/disabled
{
    local $STYLE_BOLD  = "";
    local $COLOR_CODE  = "";
    local $COLOR_GRAY  = "";
    local $COLOR_RESET = "";

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    unlike($out, qr/\x1b\[[0-9;]*m/, "No ANSI escapes emitted when colors are empty");
}

# Test 8: Dynamic version from $VERSION (e.g. v1.3.0)
{
    local $VERSION = '1.3.0';
    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/CodeAgent v1\.3\.0/, "Version formats dynamically from \$VERSION");
}

# Test 9: $COLOR_GRAY is defined and respects NO_COLOR and non-tty
{
    ok(defined $COLOR_GRAY, '$COLOR_GRAY is declared in package');
    is($COLOR_GRAY, '', '$COLOR_GRAY is cleared in non-tty test environment');

    # Verify src/header.pl defines $COLOR_GRAY as \x1b[90m
    my $header_src = do {
        open my $hf, '<', "$root_dir/src/header.pl" or die "Cannot open header.pl: $!";
        local $/; <$hf>;
    };
    like($header_src, qr/our\s+\$COLOR_GRAY\s*=\s*"\\x1b\[90m";/, '$COLOR_GRAY is defined as \x1b[90m in src/header.pl');

    # Verify NO_COLOR clears $COLOR_GRAY
    my $cmd_no_color = qq{$^X -e '\$ENV{NO_COLOR} = 1; require q{$root_dir/code-agent.pl}; print defined \$COLOR_GRAY && \$COLOR_GRAY eq "" ? "CLEARED" : "NOT_CLEARED";'};
    my $res_no_color = `$cmd_no_color`;
    is($res_no_color, "CLEARED", '$COLOR_GRAY is cleared when NO_COLOR is set');
}
