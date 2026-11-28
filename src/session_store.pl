# src/session_store.pl — Session Persistence and Index Management
# Provides schema-version-1 JSON persistence, atomic writes (0600),
# rebuildable index.json, retention pruning, and exact/prefix ID resolution.

use strict;
use warnings;
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(mkpath);

# --- Configuration & Validation ---

sub get_sessions_dir {
    if (defined $ENV{CLAUDE_SESSIONS_DIR} && length $ENV{CLAUDE_SESSIONS_DIR}) {
        return $ENV{CLAUDE_SESSIONS_DIR};
    }
    my $home = $ENV{HOME};
    $home = '.' unless defined $home && length $home;
    return File::Spec->catdir($home, '.code-agent', 'sessions');
}

sub get_max_saved_sessions {
    if (defined $ENV{CLAUDE_MAX_SESSIONS} && $ENV{CLAUDE_MAX_SESSIONS} =~ /^\d+$/ && $ENV{CLAUDE_MAX_SESSIONS} > 0) {
        return int($ENV{CLAUDE_MAX_SESSIONS});
    }
    return 100;
}

sub is_valid_session_id {
    my ($id) = @_;
    return 0 unless defined $id && length $id;
    return 0 if $id =~ /\0/;
    return 0 if lc($id) eq 'index';
    return ($id =~ /^[A-Za-z0-9_-]+$/) ? 1 : 0;
}

# --- File I/O Helpers ---

sub atomic_write_file {
    my ($path, $content, $mode) = @_;
    $mode = 0600 unless defined $mode;
    return 0 unless defined $path && length $path;

    my $dir = dirname($path);
    unless (-d $dir) {
        eval {
            File::Path::mkpath($dir, 0, 0700);
        };
        return 0 if $@ || !-d $dir;
    }

    my $tmp_path = sprintf("%s.tmp.%d.%d", $path, $$, int(rand(1000000)));
    my $fh;
    if (!open($fh, '>:encoding(UTF-8)', $tmp_path)) {
        return 0;
    }
    my $print_ok = print $fh $content;
    my $close_ok = close($fh);
    unless ($print_ok && $close_ok) {
        unlink($tmp_path);
        return 0;
    }

    chmod($mode, $tmp_path);

    if (!rename($tmp_path, $path)) {
        unlink($tmp_path);
        return 0;
    }
    return 1;
}

sub _read_file_utf8 {
    my ($path) = @_;
    return undef unless defined $path && -f $path;
    open(my $fh, '<:encoding(UTF-8)', $path) or return undef;
    my $content = do { local $/; <$fh> };
    close($fh);
    return $content;
}

sub _count_user_turns_from_messages {
    my ($messages) = @_;
    return 0 unless defined $messages && ref($messages) eq 'ARRAY';
    if (defined &count_user_turns) {
        return count_user_turns({ messages => $messages });
    }
    my $count = 0;
    for my $m (@$messages) {
        next unless ref($m) eq 'HASH' && defined $m->{role} && $m->{role} eq 'user';
        my $is_tool_result = 0;
        if (ref($m->{content}) eq 'ARRAY') {
            for my $b (@{ $m->{content} }) {
                if (ref($b) eq 'HASH' && defined $b->{type} && $b->{type} eq 'tool_result') {
                    $is_tool_result = 1;
                    last;
                }
            }
        }
        $count++ unless $is_tool_result;
    }
    return $count;
}

sub _extract_session_index_entry {
    my ($data) = @_;
    return undef unless defined $data && ref($data) eq 'HASH';
    my $messages = ref($data->{messages}) eq 'ARRAY' ? $data->{messages} : [];
    return {
        id            => $data->{id},
        title         => defined $data->{title} ? $data->{title} : '',
        cwd           => defined $data->{cwd} ? $data->{cwd} : '',
        created_at    => $data->{created_at} || 0,
        updated_at    => $data->{updated_at} || 0,
        message_count => scalar(@$messages),
        user_turns    => _count_user_turns_from_messages($messages),
        provider      => defined $data->{provider} ? $data->{provider} : '',
        model         => defined $data->{model} ? $data->{model} : '',
    };
}

# --- Index Management ---

sub save_sessions_index {
    my ($index, $dir) = @_;
    $dir = get_sessions_dir() unless defined $dir;
    return 0 unless defined $index && ref($index) eq 'HASH';
    my $index_file = File::Spec->catfile($dir, 'index.json');
    my $encoded = MiniJSON::encode($index);
    return atomic_write_file($index_file, $encoded, 0600);
}

sub rebuild_sessions_index {
    my ($dir) = @_;
    $dir = get_sessions_dir() unless defined $dir;

    my @entries;
    if (-d $dir && opendir(my $dh, $dir)) {
        my @files = sort readdir($dh);
        closedir($dh);

        for my $file (@files) {
            next unless $file =~ /^([A-Za-z0-9_-]+)\.json$/;
            my $id = $1;
            next if lc($id) eq 'index';

            my $filepath = File::Spec->catfile($dir, $file);
            my $raw = _read_file_utf8($filepath);
            next unless defined $raw;

            my $data = eval { MiniJSON::decode($raw) };
            next if $@ || !defined $data || ref($data) ne 'HASH';
            next unless defined $data->{id} && $data->{id} eq $id;

            my $entry = _extract_session_index_entry($data);
            push @entries, $entry if defined $entry;
        }
    }

    @entries = sort { ($b->{updated_at} || 0) <=> ($a->{updated_at} || 0) } @entries;
    my $index = {
        version  => 1,
        sessions => \@entries,
    };
    save_sessions_index($index, $dir);
    return $index;
}

sub load_sessions_index {
    my ($dir) = @_;
    $dir = get_sessions_dir() unless defined $dir;

    return { version => 1, sessions => [] } unless -d $dir;

    my $index_file = File::Spec->catfile($dir, 'index.json');
    return rebuild_sessions_index($dir) unless -f $index_file;

    my $raw = _read_file_utf8($index_file);
    return rebuild_sessions_index($dir) unless defined $raw;

    my $data = eval { MiniJSON::decode($raw) };
    if ($@ || !defined $data || ref($data) ne 'HASH' || ref($data->{sessions}) ne 'ARRAY') {
        return rebuild_sessions_index($dir);
    }
    return $data;
}

sub _prune_old_sessions {
    my ($sessions_list, $dir, $max_allowed) = @_;
    return unless defined $sessions_list && ref($sessions_list) eq 'ARRAY';
    return if scalar(@$sessions_list) <= $max_allowed;

    my @to_prune = splice(@$sessions_list, $max_allowed);
    for my $item (@to_prune) {
        my $id = $item->{id};
        if (defined $id && is_valid_session_id($id)) {
            my $file = File::Spec->catfile($dir, "$id.json");
            unlink($file) if -f $file;
        }
    }
}

# --- Core Session Store API ---

sub save_session {
    my ($session, $dir) = @_;
    $dir = get_sessions_dir() unless defined $dir;

    return 0 unless defined $session && ref($session) eq 'HASH';
    my $messages = $session->{messages};
    return 0 unless defined $messages && ref($messages) eq 'ARRAY' && scalar(@$messages) > 0;

    my $id = $session->{id};
    return 0 unless is_valid_session_id($id);

    my $now = time();
    $session->{updated_at} = $now;
    $session->{created_at} = $now unless defined $session->{created_at} && $session->{created_at} > 0;
    $session->{title} = '' unless defined $session->{title};
    $session->{cwd} = '' unless defined $session->{cwd};
    $session->{provider} = '' unless defined $session->{provider};
    $session->{model} = '' unless defined $session->{model};

    my $stats = $session->{stats};
    if (!defined $stats || ref($stats) ne 'HASH') {
        $stats = defined &_default_session_stats ? _default_session_stats() : {};
    }

    my $session_data = {
        version    => 1,
        id         => $session->{id},
        title      => $session->{title},
        cwd        => $session->{cwd},
        created_at => $session->{created_at},
        updated_at => $session->{updated_at},
        provider   => $session->{provider},
        model      => $session->{model},
        messages   => $session->{messages},
        stats      => $stats,
    };

    my $filepath = File::Spec->catfile($dir, "$id.json");
    my $encoded = MiniJSON::encode($session_data);
    my $write_ok = atomic_write_file($filepath, $encoded, 0600);
    return 0 unless $write_ok;

    # Update index
    my $index = load_sessions_index($dir);
    my $sessions_list = (ref($index) eq 'HASH' && ref($index->{sessions}) eq 'ARRAY')
        ? $index->{sessions}
        : [];

    # Remove existing entry if already present
    @$sessions_list = grep { defined $_->{id} && $_->{id} ne $id } @$sessions_list;

    # Prepend or sort new entry
    my $new_entry = _extract_session_index_entry($session_data);
    push @$sessions_list, $new_entry;
    @$sessions_list = sort { ($b->{updated_at} || 0) <=> ($a->{updated_at} || 0) } @$sessions_list;

    # Retention limit check
    my $max_saved = get_max_saved_sessions();
    _prune_old_sessions($sessions_list, $dir, $max_saved);

    $index->{sessions} = $sessions_list;
    save_sessions_index($index, $dir);

    return 1;
}

sub load_session {
    my ($id, $dir) = @_;
    return undef unless is_valid_session_id($id);
    $dir = get_sessions_dir() unless defined $dir;

    my $filepath = File::Spec->catfile($dir, "$id.json");
    return undef unless -f $filepath;

    my $raw = _read_file_utf8($filepath);
    return undef unless defined $raw;

    my $data = eval { MiniJSON::decode($raw) };
    return undef if $@ || !defined $data || ref($data) ne 'HASH';
    return $data;
}

sub delete_session {
    my ($id, $dir) = @_;
    return 0 unless is_valid_session_id($id);
    $dir = get_sessions_dir() unless defined $dir;

    my $filepath = File::Spec->catfile($dir, "$id.json");
    unlink($filepath) if -f $filepath;

    my $index = load_sessions_index($dir);
    if (ref($index) eq 'HASH' && ref($index->{sessions}) eq 'ARRAY') {
        my @filtered = grep { defined $_->{id} && $_->{id} ne $id } @{ $index->{sessions} };
        $index->{sessions} = \@filtered;
        save_sessions_index($index, $dir);
    }
    return 1;
}

sub list_sessions {
    my ($options, $dir) = @_;
    $options = {} unless defined $options && ref($options) eq 'HASH';
    $dir = get_sessions_dir() unless defined $dir;

    my $index = load_sessions_index($dir);
    my $sessions = (ref($index) eq 'HASH' && ref($index->{sessions}) eq 'ARRAY')
        ? [ @{ $index->{sessions} } ]
        : [];

    if (defined $options->{cwd} && length $options->{cwd}) {
        my $target_cwd = $options->{cwd};
        $sessions = [ grep { ($_->{cwd} || '') eq $target_cwd } @$sessions ];
    }

    if (defined $options->{limit} && $options->{limit} =~ /^\d+$/ && $options->{limit} > 0) {
        if (scalar(@$sessions) > $options->{limit}) {
            $sessions = [ @$sessions[0 .. $options->{limit} - 1] ];
        }
    }

    return $sessions;
}

# --- ID Resolution ---

sub _resolve_result {
    my ($ok, $id, $type, $error, $matches) = @_;
    my $res = {
        ok      => $ok ? 1 : 0,
        matches => $matches || [],
    };
    $res->{id} = $id if defined $id;
    $res->{type} = $type if defined $type;
    $res->{error} = $error if defined $error;
    return wantarray ? ($id, $error) : $res;
}

sub resolve_session_id {
    my ($query, $dir) = @_;
    $dir = get_sessions_dir() unless defined $dir;

    return _resolve_result(0, undef, 'invalid', "No session ID provided.", [])
        unless defined $query && length($query) > 0;

    return _resolve_result(0, undef, 'invalid',
        "Invalid session ID '$query'. IDs must contain only letters, numbers, dashes, and underscores.", [])
        unless is_valid_session_id($query);

    my $index = load_sessions_index($dir);
    my $sessions = (ref($index) eq 'HASH' && ref($index->{sessions}) eq 'ARRAY')
        ? $index->{sessions}
        : [];

    # 1. Exact match (case-sensitive)
    for my $s (@$sessions) {
        if (defined $s->{id} && $s->{id} eq $query) {
            return _resolve_result(1, $s->{id}, undef, undef, [ $s->{id} ]);
        }
    }

    # 2. Case-insensitive exact match
    my $lquery = lc($query);
    my @ci_matches;
    for my $s (@$sessions) {
        push @ci_matches, $s->{id} if defined $s->{id} && lc($s->{id}) eq $lquery;
    }
    if (scalar(@ci_matches) == 1) {
        return _resolve_result(1, $ci_matches[0], undef, undef, \@ci_matches);
    }

    # 2b. Direct file check if index was desynchronized
    my $direct_file = File::Spec->catfile($dir, "$query.json");
    if (-f $direct_file) {
        my $loaded = load_session($query, $dir);
        if (defined $loaded && ref($loaded) eq 'HASH' && defined $loaded->{id} && length($loaded->{id})) {
            my $actual_id = $loaded->{id};
            return _resolve_result(1, $actual_id, undef, undef, [ $actual_id ]);
        }
    }

    # 3. Case-insensitive prefix match
    my @prefix_matches;
    for my $s (@$sessions) {
        next unless defined $s->{id};
        push @prefix_matches, $s->{id} if index(lc($s->{id}), $lquery) == 0;
    }

    if (scalar(@prefix_matches) == 1) {
        return _resolve_result(1, $prefix_matches[0], undef, undef, \@prefix_matches);
    }
    elsif (scalar(@prefix_matches) > 1) {
        my $match_list = join(', ', @prefix_matches);
        return _resolve_result(0, undef, 'ambiguous',
            "Ambiguous session ID prefix '$query'. Multiple sessions match: $match_list", \@prefix_matches);
    }

    # 4. Not found
    return _resolve_result(0, undef, 'not_found', "Session '$query' not found.", []);
}

1;
