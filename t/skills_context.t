#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Encode qw(encode decode);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ==============================================================================
# 1. Tests for parse_skill_frontmatter
# ==============================================================================
{
    my $tmp = tempdir(CLEANUP => 1);

    # Invalid / missing inputs
    is(parse_skill_frontmatter(undef), undef, 'parse_skill_frontmatter returns undef for undef path');
    is(parse_skill_frontmatter("$tmp/no_such_file.md"), undef, 'parse_skill_frontmatter returns undef for missing file');
    is(parse_skill_frontmatter($tmp), undef, 'parse_skill_frontmatter returns undef for directory');

    # Standard YAML frontmatter
    my $skill_dir = "$tmp/code-review";
    mkdir($skill_dir) or die $!;
    my $skill_file = "$skill_dir/SKILL.md";
    open(my $fh, '>:encoding(UTF-8)', $skill_file) or die $!;
    print $fh "---\nname: code-review\ndescription: Conducts thorough multi-axis code review.\n---\n\n# Code Review\nDetails here.\n";
    close $fh;

    my $meta = parse_skill_frontmatter($skill_file);
    is_deeply($meta, {
        name        => 'code-review',
        description => 'Conducts thorough multi-axis code review.',
        path        => $skill_file,
    }, 'parse_skill_frontmatter parses standard YAML frontmatter');

    # Quoted values and UTF-8 characters
    my $utf8_dir = "$tmp/tiger-utf8";
    mkdir($utf8_dir) or die $!;
    my $utf8_file = "$utf8_dir/SKILL.md";
    open(my $fh2, '>:encoding(UTF-8)', $utf8_file) or die $!;
    print $fh2 "---\nname: \"tiger-日本語\"\ndescription: 'Builds PowerPC binaries — 動作確認 🚀'\n---\nBody\n";
    close $fh2;

    my $meta_utf8 = parse_skill_frontmatter($utf8_file);
    is($meta_utf8->{name}, 'tiger-日本語', 'parse_skill_frontmatter unquotes and decodes UTF-8 name');
    is($meta_utf8->{description}, 'Builds PowerPC binaries — 動作確認 🚀', 'parse_skill_frontmatter unquotes and decodes UTF-8 description');

    # Multiline / folded YAML description
    my $multi_dir = "$tmp/multiline-skill";
    mkdir($multi_dir) or die $!;
    my $multi_file = "$multi_dir/SKILL.md";
    open(my $fh3, '>:encoding(UTF-8)', $multi_file) or die $!;
    print $fh3 "---\nname: multiline-skill\ndescription: >\n  First line of description\n  second line of description.\nmetadata:\n  version: 1.0\n---\n# Heading\n";
    close $fh3;

    my $meta_multi = parse_skill_frontmatter($multi_file);
    is($meta_multi->{name}, 'multiline-skill', 'parse_skill_frontmatter parses name with multiline description');
    is($meta_multi->{description}, 'First line of description second line of description.', 'parse_skill_frontmatter joins multiline description');

    # Missing frontmatter: fallback name to parent dir, description to first non-heading line
    my $nofm_dir = "$tmp/fallback-skill";
    mkdir($nofm_dir) or die $!;
    my $nofm_file = "$nofm_dir/SKILL.md";
    open(my $fh4, '>:encoding(UTF-8)', $nofm_file) or die $!;
    print $fh4 "# Fallback Skill Heading\n\nThis skill has no YAML frontmatter fence.\nMore details.\n";
    close $fh4;

    my $meta_nofm = parse_skill_frontmatter($nofm_file);
    is($meta_nofm->{name}, 'fallback-skill', 'parse_skill_frontmatter falls back to parent directory name');
    is($meta_nofm->{description}, 'This skill has no YAML frontmatter fence.', 'parse_skill_frontmatter falls back to first non-heading body line');

    # Empty file fallback
    my $empty_dir = "$tmp/empty-skill";
    mkdir($empty_dir) or die $!;
    my $empty_file = "$empty_dir/SKILL.md";
    open(my $fh5, '>', $empty_file) or die $!;
    print $fh5 "# Only a heading\n   \n";
    close $fh5;

    my $meta_empty = parse_skill_frontmatter($empty_file);
    is($meta_empty->{name}, 'empty-skill', 'parse_skill_frontmatter falls back to dir name on heading-only file');
    is($meta_empty->{description}, 'No description provided.', 'parse_skill_frontmatter falls back to default description when body has no text');

    # File > 4096 bytes bounded read check
    my $large_dir = "$tmp/large-skill";
    mkdir($large_dir) or die $!;
    my $large_file = "$large_dir/SKILL.md";
    open(my $fh6, '>:encoding(UTF-8)', $large_file) or die $!;
    print $fh6 "---\nname: large-skill\ndescription: Bounded 4KB header scan.\n---\n" . ("A" x 10000);
    close $fh6;

    my $meta_large = parse_skill_frontmatter($large_file);
    is($meta_large->{name}, 'large-skill', 'parse_skill_frontmatter reads frontmatter from >4KB file');
    is($meta_large->{description}, 'Bounded 4KB header scan.', 'parse_skill_frontmatter extracts description from >4KB file');
}

# ==============================================================================
# 2. Tests for discover_skills and get_skills_context
# ==============================================================================
{
    # Case A: Neither global nor project skills directory exists
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    my $skills = discover_skills($tmp_home, $tmp_cwd);
    is_deeply($skills, [], 'discover_skills returns empty arrayref when no skills directories exist');
    is(get_skills_context($tmp_home, $tmp_cwd), '', 'get_skills_context returns empty string when no skills exist');
}

{
    # Case B: Only global skills exist, plus hidden dirs / invalid entries ignored
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    mkdir("$tmp_home/.agents") or die $!;
    mkdir("$tmp_home/.agents/skills") or die $!;

    # Valid skill 1
    mkdir("$tmp_home/.agents/skills/alpha-skill") or die $!;
    open(my $fh1, '>:encoding(UTF-8)', "$tmp_home/.agents/skills/alpha-skill/SKILL.md") or die $!;
    print $fh1 "---\nname: alpha-skill\ndescription: Alpha global skill.\n---\n";
    close $fh1;

    # Hidden directory (should be ignored)
    mkdir("$tmp_home/.agents/skills/.hidden-skill") or die $!;
    open(my $fh_hid, '>:encoding(UTF-8)', "$tmp_home/.agents/skills/.hidden-skill/SKILL.md") or die $!;
    print $fh_hid "---\nname: hidden\ndescription: Should be ignored.\n---\n";
    close $fh_hid;

    # Directory without SKILL.md (should be ignored)
    mkdir("$tmp_home/.agents/skills/empty-dir") or die $!;

    # Regular file in skills root (should be ignored)
    open(my $fh_file, '>', "$tmp_home/.agents/skills/README.txt") or die $!;
    print $fh_file "Not a skill directory";
    close $fh_file;

    my $skills = discover_skills($tmp_home, $tmp_cwd);
    is(scalar @$skills, 1, 'discover_skills finds 1 valid global skill and ignores hidden/empty/non-dir');
    is($skills->[0]->{scope}, 'global', 'global skill has scope "global"');
    is($skills->[0]->{name}, 'alpha-skill', 'global skill has expected name');

    my $ctx = get_skills_context($tmp_home, $tmp_cwd);
    my $expected = "<available_skills>\n"
        . "When a task matches a skill below, use read_file on its path to load its full instructions before proceeding:\n"
        . "- [global] alpha-skill: Alpha global skill. (path: $tmp_home/.agents/skills/alpha-skill/SKILL.md)\n"
        . "</available_skills>";
    is($ctx, $expected, 'get_skills_context formats global skill properly');
}

{
    # Case C: Only project skills exist
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    mkdir("$tmp_cwd/.agents") or die $!;
    mkdir("$tmp_cwd/.agents/skills") or die $!;
    mkdir("$tmp_cwd/.agents/skills/tiger-build") or die $!;
    open(my $fh, '>:encoding(UTF-8)', "$tmp_cwd/.agents/skills/tiger-build/SKILL.md") or die $!;
    print $fh "---\nname: tiger-build\ndescription: Builds binaries for Mac OS X 10.4.\n---\n";
    close $fh;

    my $ctx = get_skills_context($tmp_home, $tmp_cwd);
    my $expected = "<available_skills>\n"
        . "When a task matches a skill below, use read_file on its path to load its full instructions before proceeding:\n"
        . "- [project] tiger-build: Builds binaries for Mac OS X 10.4. (path: $tmp_cwd/.agents/skills/tiger-build/SKILL.md)\n"
        . "</available_skills>";
    is($ctx, $expected, 'get_skills_context formats project skill properly');
}

{
    # Case D: Both global and project skills exist (including identical skill name in both scopes)
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);

    mkdir("$tmp_home/.agents") or die $!;
    mkdir("$tmp_home/.agents/skills") or die $!;
    mkdir("$tmp_home/.agents/skills/shared-name") or die $!;
    open(my $fh1, '>:encoding(UTF-8)', "$tmp_home/.agents/skills/shared-name/SKILL.md") or die $!;
    print $fh1 "---\nname: shared-name\ndescription: Global version of shared skill.\n---\n";
    close $fh1;

    mkdir("$tmp_cwd/.agents") or die $!;
    mkdir("$tmp_cwd/.agents/skills") or die $!;
    mkdir("$tmp_cwd/.agents/skills/shared-name") or die $!;
    open(my $fh2, '>:encoding(UTF-8)', "$tmp_cwd/.agents/skills/shared-name/SKILL.md") or die $!;
    print $fh2 "---\nname: shared-name\ndescription: Project version of shared skill.\n---\n";
    close $fh2;

    my $skills = discover_skills($tmp_home, $tmp_cwd);
    is(scalar @$skills, 2, 'discover_skills preserves both global and project skills even with same name');
    is($skills->[0]->{scope}, 'global', 'first skill is global scope');
    is($skills->[1]->{scope}, 'project', 'second skill is project scope');

    my $ctx = get_skills_context($tmp_home, $tmp_cwd);
    like($ctx, qr/- \[global\] shared-name: Global version of shared skill\./, 'context includes [global] shared-name');
    like($ctx, qr/- \[project\] shared-name: Project version of shared skill\./, 'context includes [project] shared-name');
}

{
    # Case E: Deduplication when $cwd eq $home_dir (same physical directory via stat dev/ino)
    my $tmp_home = tempdir(CLEANUP => 1);
    mkdir("$tmp_home/.agents") or die $!;
    mkdir("$tmp_home/.agents/skills") or die $!;
    mkdir("$tmp_home/.agents/skills/solo-skill") or die $!;
    open(my $fh, '>:encoding(UTF-8)', "$tmp_home/.agents/skills/solo-skill/SKILL.md") or die $!;
    print $fh "---\nname: solo-skill\ndescription: Only scanned once.\n---\n";
    close $fh;

    my $skills = discover_skills($tmp_home, $tmp_home);
    is(scalar @$skills, 1, 'discover_skills deduplicates when home_dir and cwd point to same physical skills dir');
    is($skills->[0]->{scope}, 'global', 'deduplicated skill retains global scope');
}

# ==============================================================================
# 3. Tests for get_effective_system_prompt and get_subagent_system_prompt
# ==============================================================================
{
    my $tmp_home = tempdir(CLEANUP => 1);
    my $tmp_cwd  = tempdir(CLEANUP => 1);
    my $fixed_epoch = 1700000000;

    mkdir("$tmp_home/.agents") or die $!;
    open(my $fh_ag, '>:encoding(UTF-8)', "$tmp_home/.agents/AGENTS.md") or die $!;
    print $fh_ag "Global rule 1.\n";
    close $fh_ag;

    mkdir("$tmp_home/.agents/skills") or die $!;
    mkdir("$tmp_home/.agents/skills/debug-ppc") or die $!;
    open(my $fh_sk, '>:encoding(UTF-8)', "$tmp_home/.agents/skills/debug-ppc/SKILL.md") or die $!;
    print $fh_sk "---\nname: debug-ppc\ndescription: Debugs PowerPC assembly and gdb crashes.\n---\n";
    close $fh_sk;

    mkdir("$tmp_cwd/.agents") or die $!;
    mkdir("$tmp_cwd/.agents/skills") or die $!;
    mkdir("$tmp_cwd/.agents/skills/perl58-check") or die $!;
    open(my $fh_psk, '>:encoding(UTF-8)', "$tmp_cwd/.agents/skills/perl58-check/SKILL.md") or die $!;
    print $fh_psk "---\nname: perl58-check\ndescription: Verifies Perl 5.8.6 compatibility.\n---\n";
    close $fh_psk;

    # Main agent prompt (include_skills defaults to 1)
    my $main_prompt = get_effective_system_prompt("Base prompt.", $tmp_home, $tmp_cwd, $fixed_epoch);
    like($main_prompt, qr/# Global Instructions \(~\/\.agents\/AGENTS\.md\)/, 'main prompt includes AGENTS.md context');
    like($main_prompt, qr/<available_skills>/, 'main prompt includes <available_skills> block');
    like($main_prompt, qr/- \[global\] debug-ppc: Debugs PowerPC assembly and gdb crashes\./, 'main prompt includes global skill');
    like($main_prompt, qr/- \[project\] perl58-check: Verifies Perl 5\.8\.6 compatibility\./, 'main prompt includes project skill');

    # Explicit $include_skills = 0 omits skills
    my $no_skills_prompt = get_effective_system_prompt("Base prompt.", $tmp_home, $tmp_cwd, $fixed_epoch, 0);
    like($no_skills_prompt, qr/# Global Instructions/, 'prompt with include_skills=0 still includes AGENTS.md');
    unlike($no_skills_prompt, qr/<available_skills>/, 'prompt with include_skills=0 omits <available_skills>');

    # Sub-agent system prompts (plan and build) should omit skills to stay lean
    local $ENV{HOME} = $tmp_home;
    my $sub_plan = get_subagent_system_prompt('plan', 50);
    unlike($sub_plan, qr/<available_skills>/, 'get_subagent_system_prompt (plan) omits <available_skills>');

    my $sub_build = get_subagent_system_prompt('build', 50);
    unlike($sub_build, qr/<available_skills>/, 'get_subagent_system_prompt (build) omits <available_skills>');
}

done_testing();
