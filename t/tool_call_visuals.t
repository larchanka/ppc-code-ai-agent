#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 50;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# ==================================================================
# 1. extract_basename tests
# ==================================================================
is(extract_basename('/foo/bar/README.md'), 'README.md', 'extract_basename: absolute path');
is(extract_basename('README.md'), 'README.md', 'extract_basename: single filename');
is(extract_basename('dir/subdir/file.txt'), 'file.txt', 'extract_basename: relative path');
is(extract_basename('/foo/bar/'), 'bar', 'extract_basename: trailing slash stripped');
is(extract_basename('foo/bar///'), 'bar', 'extract_basename: multiple trailing slashes');
is(extract_basename('/'), '/', 'extract_basename: root path');
is(extract_basename('.'), '.', 'extract_basename: dot path');
is(extract_basename(undef), '', 'extract_basename: undef returns empty string');
is(extract_basename(''), '', 'extract_basename: empty string returns empty string');

# ==================================================================
# 2. truncate_text tests
# ==================================================================
is(truncate_text('hello', 20), 'hello', 'truncate_text: short string unchanged');
is(truncate_text('12345678901234567890', 20), '12345678901234567890', 'truncate_text: exact max length');
is(truncate_text('123456789012345678901', 20), '12345678901234567890...', 'truncate_text: truncated at 20 with ellipsis');
is(truncate_text("line1\nline2\nline3", 20), 'line1 line2 line3', 'truncate_text: newlines collapsed');
is(truncate_text("  extra   spaces\t\nand   tabs  ", 30), 'extra spaces and tabs', 'truncate_text: whitespace normalized');
is(truncate_text(undef, 20), '', 'truncate_text: undef returns empty string');
is(truncate_text('default max len is twenty characters or more'), 'default max len is t...', 'truncate_text: default max_len is 20');

# ==================================================================
# 3. format_tool_summary tests
# ==================================================================
# read_file
is(format_tool_summary('read_file', { path => '/path/to/README.md' }),
   'read_file   README.md',
   'format_tool_summary: read_file without line range');

is(format_tool_summary('read_file', { path => '/path/to/README.md', start_line => 10, end_line => 20 }),
   'read_file   README.md   L10-20',
   'format_tool_summary: read_file with line range L10-20');

is(format_tool_summary('read_file', { path => 'README.md', start_line => 10 }),
   'read_file   README.md   L10-',
   'format_tool_summary: read_file with only start_line');

is(format_tool_summary('read_file', { path => 'README.md', end_line => 20 }),
   'read_file   README.md   L1-20',
   'format_tool_summary: read_file with only end_line');

# write_file
is(format_tool_summary('write_file', { path => '/long/dir/path/file.txt', content => 'short content' }),
   'write_file   file.txt   short content',
   'format_tool_summary: write_file with short content');

is(format_tool_summary('write_file', { path => 'README.md', content => 'adjklsadjsakldjskade_more' }),
   'write_file   README.md   adjklsadjsakldjskade...',
   'format_tool_summary: write_file with content truncated to 20 chars');

is(format_tool_summary('write_file', { path => 'README.md', content => "line 1\nline 2 long content here" }),
   'write_file   README.md   line 1 line 2 long c...',
   'format_tool_summary: write_file collapses multiline content');

# edit_file
is(format_tool_summary('edit_file', { path => '/src/README.md', start_line => 10, end_line => 20, content => 'my new content is long and more' }),
   'edit_file   README.md   L10-20   my new content is lo...',
   'format_tool_summary: edit_file with range and truncated content');

is(format_tool_summary('edit_file', { path => 'README.md', start_line => 5, end_line => 15, replacement => 'new stuff' }),
   'edit_file   README.md   L5-15   new stuff',
   'format_tool_summary: edit_file supports replacement key');

is(format_tool_summary('edit_file', { path => 'README.md', start_line => 5, end_line => 15, content => '' }),
   'edit_file   README.md   L5-15',
   'format_tool_summary: edit_file with empty content (deletion)');

# run_shell
is(format_tool_summary('run_shell', { command => 'ls -la' }),
   'run_shell   ls -la',
   'format_tool_summary: run_shell with short command');

is(format_tool_summary('run_shell', { command => 'git status --porcelain' }),
   'run_shell   git status --porcela...',
   'format_tool_summary: run_shell with command > 20 chars');

# list_dir
is(format_tool_summary('list_dir', { path => 'src' }),
   'list_dir   src',
   'format_tool_summary: list_dir with named directory');

is(format_tool_summary('list_dir', {}),
   'list_dir   .',
   'format_tool_summary: list_dir defaults to . when path omitted');

is(format_tool_summary('list_dir', { path => '.' }),
   'list_dir   .',
   'format_tool_summary: list_dir with . path');

# generic / fallback tool
is(format_tool_summary('custom_tool', { query => 'search string here' }),
   'custom_tool   search string here',
   'format_tool_summary: custom tool fallback with string param');

is(format_tool_summary('custom_tool', {}),
   'custom_tool',
   'format_tool_summary: custom tool with empty input');

# defensive path handling (undef/empty path)
is(format_tool_summary('read_file', {}),
   'read_file   ?',
   'format_tool_summary: read_file with missing path falls back to ?');

is(format_tool_summary('read_file', { start_line => 5, end_line => 10 }),
   'read_file   ?   L5-10',
   'format_tool_summary: read_file with missing path and line range');

is(format_tool_summary('write_file', { content => 'test' }),
   'write_file   ?   test',
   'format_tool_summary: write_file with missing path falls back to ?');

is(format_tool_summary('edit_file', { start_line => 1, end_line => 2, content => 'new' }),
   'edit_file   ?   L1-2   new',
   'format_tool_summary: edit_file with missing path falls back to ?');

# parameter aliases in format_tool_summary
is(format_tool_summary('read_file', { file_path => '/a/b/plan.md', start_line => 1, end_line => 5 }),
   'read_file   plan.md   L1-5',
   'format_tool_summary: read_file with file_path alias');

is(format_tool_summary('read_file', { filepath => '/a/b/spec.md' }),
   'read_file   spec.md',
   'format_tool_summary: read_file with filepath alias');

is(format_tool_summary('read_file', { filename => '/a/b/notes.txt' }),
   'read_file   notes.txt',
   'format_tool_summary: read_file with filename alias');

is(format_tool_summary('read_file', { file => '/a/b/main.pl' }),
   'read_file   main.pl',
   'format_tool_summary: read_file with file alias');

is(format_tool_summary('write_file', { filepath => 'tasks/todo.md', text => 'checklist item' }),
   'write_file   todo.md   checklist item',
   'format_tool_summary: write_file with filepath and text aliases');

is(format_tool_summary('write_file', { file_path => 'tasks/data.txt', data => 'data payload' }),
   'write_file   data.txt   data payload',
   'format_tool_summary: write_file with file_path and data aliases');

is(format_tool_summary('write_file', { filename => 'tasks/out.txt', body => 'body content' }),
   'write_file   out.txt   body content',
   'format_tool_summary: write_file with filename and body aliases');

is(format_tool_summary('edit_file', { file => 'src/tools.pl', start_line => 10, end_line => 12, new_text => 'updated code' }),
   'edit_file   tools.pl   L10-12   updated code',
   'format_tool_summary: edit_file with file and new_text aliases');

is(format_tool_summary('run_shell', { cmd => 'prove -I. t/*.t' }),
   'run_shell   prove -I. t/*.t',
   'format_tool_summary: run_shell with cmd alias');

is(format_tool_summary('list_dir', { dir => 'tasks/sub' }),
   'list_dir   sub',
   'format_tool_summary: list_dir with dir alias');

is(format_tool_summary('write_file', { _arg_parse_error => 'Unexpected EOF', _raw_arguments => '{"path":' }),
   'write_file   ?',
   'format_tool_summary: write_file with _arg_parse_error does not leak error into summary');

# ==================================================================
# 4. format_tool_call & $COLOR_DIM tests
# ==================================================================
{
    # When COLOR_DIM is active
    local $main::COLOR_DIM   = "\x1b[2m";
    local $main::COLOR_RESET = "\x1b[0m";

    my $formatted = format_tool_call('read_file', { path => 'foo.txt' });
    is($formatted, "\x1b[2mread_file   foo.txt\x1b[0m", 'format_tool_call wraps summary in DIM and RESET');
}

{
    # When COLOR_DIM is disabled / empty
    local $main::COLOR_DIM   = '';
    local $main::COLOR_RESET = '';

    my $formatted = format_tool_call('read_file', { path => 'foo.txt' });
    is($formatted, 'read_file   foo.txt', 'format_tool_call returns plain summary when COLOR_DIM is empty');
}
