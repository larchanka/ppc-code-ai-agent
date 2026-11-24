#!/usr/bin/perl
# code-agent.pl — Self-contained Claude API agent for iBook G4
# (Mac OS X 10.4 Tiger, Perl 5.8.6). Has no external CPAN module dependencies.
#
# Prerequisite: /usr/local/code-toolchain/bin/curl (with TLS 1.2/1.3 support),
#               built via ~/code-build/build/remote-build-*.sh, must be available.
#
# Usage:
#   export ANTHROPIC_API_KEY=sk-ant-...
#   perl code-agent.pl

use strict;
use warnings;
use utf8;
use Encode qw(decode encode FB_DEFAULT);
use POSIX qw(WNOHANG);

# Explicitly handle screen output as UTF-8.
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# STDIN is deliberately kept as raw bytes (without :encoding layer).
# In Perl 5.8.6, PerlIO :encoding(UTF-8) during interactive keyboard reading
# where bytes arrive incrementally can split multibyte characters across read
# buffer boundaries, causing "utf8 does not map to Unicode" encoding errors
# (this does not happen with bulk input via pipes). Therefore, we read full lines
# as raw bytes first and decode them together at the end (in the while loop below).

# Adding :encoding disables STDOUT autoflush, which can delay prompt display
# until the API response arrives, so we explicitly flush each time.
$| = 1;

# --- Configuration ---
my $home_dir = $ENV{HOME} || '.';
my $CURL   = $ENV{CLAUDE_CURL}   || (-x "$home_dir/.code-agent/toolchain/bin/curl" ? "$home_dir/.code-agent/toolchain/bin/curl" : (-x '/usr/local/code-toolchain/bin/curl' ? '/usr/local/code-toolchain/bin/curl' : 'curl'));
my $CACERT = $ENV{CLAUDE_CACERT} || (-f "$home_dir/.code-agent/build/src/cacert.pem" ? "$home_dir/.code-agent/build/src/cacert.pem" : (-f '/usr/local/code-toolchain/cacert.pem' ? '/usr/local/code-toolchain/cacert.pem' : ''));

sub parse_context_size {
    my ($input) = @_;
    return undef unless defined $input;
    $input =~ s/^\s+|\s+$//g;
    return undef if $input eq '';

    if ($input =~ /^(\d+)$/) {
        my $val = int($1);
        return $val > 0 ? $val : undef;
    }
    elsif ($input =~ /^(\d+)([kKmM])$/) {
        my ($num, $unit) = ($1, lc($2));
        return undef if $num <= 0;
        my $mult = ($unit eq 'm') ? 1048576 : 1024;
        return int($num * $mult);
    }
    return undef;
}

sub format_context_size {
    my ($tokens) = @_;
    return '' unless defined $tokens;
    return "$tokens" unless $tokens =~ /^\d+$/ && $tokens > 0;

    if ($tokens >= 1048576 && ($tokens % 1048576) == 0) {
        return ($tokens / 1048576) . 'm';
    }
    elsif ($tokens >= 1024 && ($tokens % 1024) == 0) {
        return ($tokens / 1024) . 'k';
    }
    return "$tokens";
}

our $MAX_TOKENS = 4096;

sub init_max_tokens {
    my $raw_env = (defined $ENV{CLAUDE_MAX_TOKENS} && length $ENV{CLAUDE_MAX_TOKENS})
        ? $ENV{CLAUDE_MAX_TOKENS}
        : ((defined $ENV{CLAUDE_CONTEXT} && length $ENV{CLAUDE_CONTEXT}) ? $ENV{CLAUDE_CONTEXT} : undef);
    if (defined $raw_env) {
        my $parsed = parse_context_size($raw_env);
        $MAX_TOKENS = $parsed if defined $parsed;
    }
    return $MAX_TOKENS;
}

init_max_tokens();

our $MAX_RETRIES = 3;
our $RETRY_DELAY = 5;

sub get_max_retries {
    if (defined $ENV{CLAUDE_MAX_RETRIES} && $ENV{CLAUDE_MAX_RETRIES} =~ /^\s*(-?\d+)\s*$/) {
        my $val = int($1);
        return $val < 0 ? 0 : $val;
    }
    return $MAX_RETRIES;
}

sub get_retry_delay {
    if (defined $ENV{CLAUDE_RETRY_DELAY} && $ENV{CLAUDE_RETRY_DELAY} =~ /^\s*(-?\d+(?:\.\d+)?)\s*$/) {
        my $val = $1 + 0;
        return $val < 0 ? 0 : $val;
    }
    return $RETRY_DELAY;
}

sub init_retry_config {
    $MAX_RETRIES = get_max_retries();
    $RETRY_DELAY = get_retry_delay();
    return ($MAX_RETRIES, $RETRY_DELAY);
}

init_retry_config();

# Resolves the environment file path (~/.code-agent/env).
sub get_env_file_path {
    my $home = $ENV{HOME} || '.';
    return "$home/.code-agent/env";
}

# Loads environment variables from an env file (defaulting to get_env_file_path()).
# Skips lines that don't match or variables already present in %ENV.
sub load_env_file {
    my ($file) = @_;
    $file = get_env_file_path() unless defined $file;
    return unless -f $file;
    if (open(my $fh, '<', $file)) {
        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/) {
                my ($k, $v) = ($1, $2);
                $v =~ s/^\s+|\s+$//g;
                $v =~ s/^["'](.*)["']$/$1/;
                $ENV{$k} = $v unless exists $ENV{$k};
            }
        }
        close $fh;
    }
    init_max_tokens();
    init_retry_config();
}

# Theme-safe ANSI attributes (zero hardcoded colors; adapts to Terminal profile)
our $COLOR_RESET     = "\x1b[0m";
our $COLOR_USER      = "\x1b[34m";   # Default foreground (avoids \e[2m dim which blends into background on Leopard/Tiger)
our $COLOR_MODEL     = "\x1b[35m";   # Bold (high contrast using profile's bold setting)
our $COLOR_DIM       = "\x1b[33m";   # Dim (for compact tool invocation summaries)
our $COLOR_SUBAGENT  = "\x1b[36m";   # Cyan (for sub-agent trees and badges)
our $STYLE_BOLD      = "\x1b[1m";
our $STYLE_UNDERLINE = "\x1b[4m";
our $COLOR_HEADER    = "\x1b[1;35m"; # Bold + Magenta for headers
our $COLOR_CODE      = "\x1b[34m";   # Blue for inline & block code
if (!-t STDOUT || exists $ENV{NO_COLOR}) {
    $COLOR_RESET     = '';
    $COLOR_USER      = '';
    $COLOR_MODEL     = '';
    $COLOR_DIM       = '';
    $COLOR_SUBAGENT  = '';
    $STYLE_BOLD      = '';
    $STYLE_UNDERLINE = '';
    $COLOR_HEADER    = '';
    $COLOR_CODE      = '';
}

sub cursor_hide {
    my $is_tty = defined $ENV{CLAUDE_TEST_TTY} ? $ENV{CLAUDE_TEST_TTY} : -t STDOUT;
    print "\x1b[?25l" if $is_tty;
}

sub cursor_show {
    my $is_tty = defined $ENV{CLAUDE_TEST_TTY} ? $ENV{CLAUDE_TEST_TTY} : -t STDOUT;
    print "\x1b[?25h" if $is_tty;
}

END {
    cursor_show();
}

# Provider switching. CLAUDE_PROVIDER=gemini uses the Gemini API free tier with no
# credit card required (default is Anthropic). Can also be switched during conversation
# via /claude or /gemini (see configure_provider below).
my ($PROVIDER, $API_KEY, $MODEL, $API_URL, $ANTHROPIC_VERSION);

# Application version.
our $VERSION = '1.3.0';

# Autonomous tool execution mode. When enabled, tools that normally require
# confirmation (write_file, run_shell) execute immediately without prompting.
our $AUTO_MODE = $ENV{CLAUDE_AUTO_MODE} ? 1 : 0;

# Active conversation session and monotonic ID sequence counter.
our $CURRENT_SESSION = undef;
our $SESSION_COUNTER = 0;
our $LAST_API_ELAPSED = 0;
our $CURRENT_SUBAGENT_TYPE = undef;

# Remote MCP and tool output tracking globals
our (%MCP_SERVERS, %MCP_TOOLS, %UNTRUSTED_OUTPUT_TOOLS);

# (Re)configures $API_KEY, $MODEL, $API_URL, etc. according to $provider.
# Called at startup and by /claude and /gemini commands during conversation.
# If corresponding environment variables (ANTHROPIC_API_KEY / GEMINI_API_KEY)
# are missing, it dies — at startup this exits the program; during interactive
# switching, the caller catches with eval and stays on current provider.
sub configure_provider {
    my ($provider) = @_;
    if ($provider eq 'gemini') {
        $ENV{GEMINI_API_KEY} or die "GEMINI_API_KEY is not set.\n";
        $API_KEY = $ENV{GEMINI_API_KEY};
        $MODEL   = $ENV{CLAUDE_MODEL} || 'gemini-3.5-flash-lite';
        $API_URL = "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent";
    }
    elsif ($provider eq 'anthropic') {
        $ENV{ANTHROPIC_API_KEY} or die "ANTHROPIC_API_KEY is not set.\n";
        $API_KEY = $ENV{ANTHROPIC_API_KEY};
        $MODEL   = $ENV{CLAUDE_MODEL} || 'claude-sonnet-4-5-20250929';
        $API_URL = 'https://api.anthropic.com/v1/messages';
        $ANTHROPIC_VERSION = '2023-06-01';
    }
    elsif ($provider eq 'openai') {
        # Any OpenAI-compatible chat/completions endpoint. Intended for local LLMs
        # running on a faster machine on the LAN (llama.cpp / Ollama / LM Studio, etc.).
        # $OPENAI_BASE_URL should be in the form "http://host:port/v1".
        my $base = $ENV{OPENAI_BASE_URL}
            or die "OPENAI_BASE_URL is not set (e.g. http://192.168.1.50:8080/v1).\n";
        $base =~ s{/+$}{};
        $API_KEY = $ENV{OPENAI_API_KEY} || 'not-needed';  # Many servers do not require an API key
        $MODEL   = $ENV{CLAUDE_MODEL} || 'local-model';
        $API_URL = "$base/chat/completions";
    }
    else {
        die "Unknown provider '$provider' (use anthropic / gemini / openai).\n";
    }
    $PROVIDER = $provider;
}

1;

