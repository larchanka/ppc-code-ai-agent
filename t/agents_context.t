#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use Encode qw(encode decode);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our $SYSTEM_PROMPT;

# ==============================================================================
# 1. Tests for read_agents_file
# ==============================================================================
{
    my $tmp = tempdir(CLEANUP => 1);

    # Non-existent file
    is(read_agents_file("$tmp/does_not_exist.md"), '', 'read_agents_file returns empty string for missing file');

    # Undef path
    is(read_agents_file(undef), '', 'read_agents_file returns empty string for undef path');

    # Directory path
    is(read_agents_file($tmp), '', 'read_agents_file returns empty string for directory');

    # Valid file with UTF-8 content
    my $utf8_file = "$tmp/test_utf8.md";
    my $unicode_text = "Rule 1: Always verify.\n日本語テキスト: 動作確認\nEmoji & accents: 🚀 éàü";
    open(my $fh, '>:encoding(UTF-8)', $utf8_file) or die "Cannot create $utf8_file: $!";
    print $fh $unicode_text;
    close $fh;

    my $read_back = read_agents_file($utf8_file);
    is($read_back, $unicode_text, 'read_agents_file decodes UTF-8 text correctly');
}

# ==============================================================================
# 2. Tests for get_agents_context
# ==============================================================================
{
    # Case A: Neither global nor local file exists
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    is($ctx, '', 'get_agents_context returns empty string when neither file exists');
}

{
    # Case B: Only global instructions exist
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    mkdir("$tmp_home/.agents") or die "Cannot mkdir: $!";
    my $global_file = "$tmp_home/.agents/AGENTS.md";
    open(my $fh, '>:encoding(UTF-8)', $global_file) or die "Cannot write $global_file: $!";
    print $fh "  \nGlobal instructions here.\nBe concise.\n  \n";
    close $fh;

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    my $expected = "# Global Instructions (~/.agents/AGENTS.md)\n\nGlobal instructions here.\nBe concise.";
    is($ctx, $expected, 'get_agents_context formats global instructions and trims whitespace');
}

{
    # Case C: Only local project instructions exist
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    my $local_file = "$tmp_cwd/AGENTS.md";
    open(my $fh, '>:encoding(UTF-8)', $local_file) or die "Cannot write $local_file: $!";
    print $fh "\n\nLocal project rules.\nNever break Tiger compatibility.\n";
    close $fh;

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    my $expected = "# Project Instructions (AGENTS.md)\n\nLocal project rules.\nNever break Tiger compatibility.";
    is($ctx, $expected, 'get_agents_context formats local instructions and trims whitespace');
}

{
    # Case D: Both global and local instructions exist
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    mkdir("$tmp_home/.agents") or die "Cannot mkdir: $!";
    open(my $fh1, '>:encoding(UTF-8)', "$tmp_home/.agents/AGENTS.md") or die $!;
    print $fh1 "Global rules.\n";
    close $fh1;

    open(my $fh2, '>:encoding(UTF-8)', "$tmp_cwd/AGENTS.md") or die $!;
    print $fh2 "Project rules.\n";
    close $fh2;

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    my $expected = "# Global Instructions (~/.agents/AGENTS.md)\n\nGlobal rules.\n\n# Project Instructions (AGENTS.md)\n\nProject rules.";
    is($ctx, $expected, 'get_agents_context formats both global and project instructions in order');
}

{
    # Case E: Deduplication when cwd is ~/.agents (same physical file)
    my $tmp_home = tempdir(CLEANUP => 1);
    my $agents_dir = "$tmp_home/.agents";
    mkdir($agents_dir) or die $!;

    open(my $fh, '>:encoding(UTF-8)', "$agents_dir/AGENTS.md") or die $!;
    print $fh "Shared instructions.\n";
    close $fh;

    my $ctx = get_agents_context($tmp_home, $agents_dir);
    my $expected = "# Global Instructions (~/.agents/AGENTS.md)\n\nShared instructions.";
    is($ctx, $expected, 'get_agents_context deduplicates when cwd is ~/.agents');
}

{
    # Case F: Deduplication via hardlink
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);
    mkdir("$tmp_home/.agents") or die $!;

    my $global_file = "$tmp_home/.agents/AGENTS.md";
    open(my $fh, '>:encoding(UTF-8)', $global_file) or die $!;
    print $fh "Hardlinked instructions.\n";
    close $fh;

    my $local_file = "$tmp_cwd/AGENTS.md";
    link($global_file, $local_file) or die "Cannot link: $!";

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    my $expected = "# Global Instructions (~/.agents/AGENTS.md)\n\nHardlinked instructions.";
    is($ctx, $expected, 'get_agents_context deduplicates via dev/ino when files are hardlinked');
}

{
    # Case G: Empty or whitespace-only files do not create sections
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);
    mkdir("$tmp_home/.agents") or die $!;

    open(my $fh1, '>', "$tmp_home/.agents/AGENTS.md") or die $!;
    print $fh1 "   \n\t  \n";
    close $fh1;

    open(my $fh2, '>', "$tmp_cwd/AGENTS.md") or die $!;
    print $fh2 "";
    close $fh2;

    my $ctx = get_agents_context($tmp_home, $tmp_cwd);
    is($ctx, '', 'get_agents_context returns empty string when files have only whitespace');
}

{
    # Case H: Default environment variables
    my $tmp_home = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp_home;
    mkdir("$tmp_home/.agents") or die $!;

    open(my $fh, '>:encoding(UTF-8)', "$tmp_home/.agents/AGENTS.md") or die $!;
    print $fh "Env home rules.\n";
    close $fh;

    # Passing undef should fall back to $ENV{HOME} and '.'
    # Since '.' has no AGENTS.md in our controlled run or might have root repo's AGENTS.md,
    # let's test explicit undef for home while providing empty cwd.
    my $empty_cwd = tempdir(CLEANUP => 1);
    my $ctx = get_agents_context(undef, $empty_cwd);
    my $expected = "# Global Instructions (~/.agents/AGENTS.md)\n\nEnv home rules.";
    is($ctx, $expected, 'get_agents_context falls back to $ENV{HOME} when $home_dir is undef');
}

# ==============================================================================
# 3. Tests for get_current_datetime_string and get_effective_system_prompt
# ==============================================================================
{
    # Test get_current_datetime_string
    my $now_str = get_current_datetime_string();
    like($now_str, qr/^\w+,\s+\w+\s+\d+,\s+\d{4}\s+\d{2}:\d{2}:\d{2}$/,
        'get_current_datetime_string returns human-readable formatted date/time');

    my $fixed_epoch = 1700000000;
    my $fixed_str = get_current_datetime_string($fixed_epoch);
    my $expected_fixed = "Current date and time: $fixed_str";

    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    # When no AGENTS.md files exist
    my $base = "You are an assistant.\n";
    my $effective = get_effective_system_prompt($base, $tmp_home, $tmp_cwd, $fixed_epoch);
    is($effective, "You are an assistant.\n\n$expected_fixed\n",
        'get_effective_system_prompt appends current date and time');

    # When base prompt is undef, defaults to $SYSTEM_PROMPT
    my $default_prompt = get_effective_system_prompt(undef, $tmp_home, $tmp_cwd, $fixed_epoch);
    like($default_prompt, qr/\bfive tools available\b/i,
        'get_effective_system_prompt defaults to $SYSTEM_PROMPT when base is undef');
    like($default_prompt, qr/\Q$expected_fixed\E/,
        'get_effective_system_prompt includes current date/time with default prompt');

    # When AGENTS.md exists
    mkdir("$tmp_home/.agents") or die $!;
    open(my $fh, '>:encoding(UTF-8)', "$tmp_home/.agents/AGENTS.md") or die $!;
    print $fh "Global instruction.";
    close $fh;

    my $effective_with_ctx = get_effective_system_prompt($base, $tmp_home, $tmp_cwd, $fixed_epoch);
    my $expected_with_ctx = "You are an assistant.\n\n$expected_fixed\n\n# Global Instructions (~/.agents/AGENTS.md)\n\nGlobal instruction.\n";
    is($effective_with_ctx, $expected_with_ctx,
        'get_effective_system_prompt appends date/time and AGENTS.md context');
}

# ==============================================================================
# 4. Tests for build_request receiving effective system prompt with AGENTS.md
# ==============================================================================
{
    my $messages = [{ role => 'user', content => 'Hello' }];

    # Anthropic provider
    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test";
    $ENV{CLAUDE_MODEL} = "claude-3-5-sonnet";
    configure_provider('anthropic');

    my $req_ant = build_request($messages, []);
    ok(defined $req_ant->{system}, 'build_request (Anthropic) defines system prompt');
    like($req_ant->{system}, qr/Current date and time:/,
        'build_request (Anthropic) includes current date and time');
    like($req_ant->{system}, qr/# Project Instructions \(AGENTS\.md\)/,
        'build_request (Anthropic) automatically includes AGENTS.md instructions');

    # Gemini provider
    $ENV{GEMINI_API_KEY} = "AIzaSyTestKey123";
    $ENV{CLAUDE_MODEL} = "gemini-2.5-flash";
    configure_provider('gemini');

    my $req_gem = build_request($messages, []);
    ok(defined $req_gem->{systemInstruction}->{parts}->[0]->{text},
        'build_request (Gemini) defines systemInstruction text');
    like($req_gem->{systemInstruction}->{parts}->[0]->{text}, qr/Current date and time:/,
        'build_request (Gemini) includes current date and time');
    like($req_gem->{systemInstruction}->{parts}->[0]->{text}, qr/# Project Instructions \(AGENTS\.md\)/,
        'build_request (Gemini) automatically includes AGENTS.md instructions');

    # OpenAI provider
    $ENV{OPENAI_BASE_URL} = "http://127.0.0.1:8080/v1";
    $ENV{CLAUDE_MODEL} = "gpt-4o";
    configure_provider('openai');

    my $req_oai = build_request($messages, []);
    ok(defined $req_oai->{messages}->[0]->{content}, 'build_request (OpenAI) defines leading system message');
    like($req_oai->{messages}->[0]->{content}, qr/Current date and time:/,
        'build_request (OpenAI) includes current date and time');
    like($req_oai->{messages}->[0]->{content}, qr/# Project Instructions \(AGENTS\.md\)/,
        'build_request (OpenAI) automatically includes AGENTS.md instructions');

    # Custom override preserved when passed explicitly
    configure_provider('anthropic');
    my $req_custom = build_request($messages, [], 'Override prompt');
    is($req_custom->{system}, 'Override prompt', 'build_request respects explicit system prompt when passed');
}

# ==============================================================================
# 5. Verify src/main.pl uses get_effective_system_prompt()
# ==============================================================================
{
    open(my $fh, '<', "$root_dir/src/main.pl") or die "Cannot open src/main.pl: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like($content, qr/build_request\(\$session->\{messages\},\s*\\\@TOOLS,\s*get_effective_system_prompt\(\)\)/,
        'src/main.pl passes get_effective_system_prompt() to build_request');
    unlike($content, qr/build_request\(\$session->\{messages\},\s*\\\@TOOLS,\s*\$SYSTEM_PROMPT\)/,
        'src/main.pl does not pass static $SYSTEM_PROMPT to build_request');
}

done_testing();
