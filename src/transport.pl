
# --- curl invocation (TLS 1.2/1.3 toolchain curl) ---
sub _is_tty_active {
    return defined $ENV{CLAUDE_TEST_TTY} ? ($ENV{CLAUDE_TEST_TTY} ? 1 : 0) : (-t STDOUT ? 1 : 0);
}

sub _has_request_body {
    my ($method, $body_json) = @_;
    my $norm = defined $method ? uc($method) : 'POST';
    return ($norm ne 'GET' && defined $body_json) ? 1 : 0;
}

sub _read_and_unlink {
    my ($path) = @_;
    return '' unless defined $path && -f $path;
    my $content = '';
    if (open(my $fh, '<', $path)) {
        local $/;
        my $raw = <$fh>;
        $content = $raw if defined $raw;
        close $fh;
    }
    unlink $path;
    return $content;
}

# Creates a hardened, non-predictable temporary file with mode 0600.
# Avoids symlink attacks and PID collisions in shared temporary directories.
sub _create_secure_tempfile {
    my ($prefix, $suffix) = @_;
    my $dir = $ENV{CLAUDE_TMPDIR} || ( -d "$ENV{HOME}/.code-agent/tmp" ? "$ENV{HOME}/.code-agent/tmp" : '/tmp' );
    my ($fh, $filename) = eval {
        tempfile("code-agent-$prefix-$$-XXXXXXXX", DIR => $dir, SUFFIX => $suffix, UNLINK => 0)
    };
    if ($@ || !defined $filename) {
        my $rand = sprintf("%06x", int(rand(0xFFFFFF)));
        $filename = "$dir/code-agent-$prefix-$$-$rand$suffix";
        sysopen($fh, $filename, POSIX::O_CREAT() | POSIX::O_EXCL() | POSIX::O_RDWR(), 0600)
            or die "cannot create secure temp file $filename: $!\n";
    }
    close $fh if $fh;
    chmod 0600, $filename;
    return $filename;
}

sub _write_curl_config {
    my ($tmp_config, $tmp_req, $tmp_resp, $url, $method, $headers, $body_json, $has_body) = @_;
    if ($has_body) {
        open(my $fh, '>:encoding(UTF-8)', $tmp_req) or die "cannot write $tmp_req: $!\n";
        chmod 0600, $tmp_req;
        print $fh $body_json;
        close $fh;
    }

    # Pass headers via curl config file (-K) rather than command line args
    # to avoid exposing API keys in ps output
    open(my $cf, '>', $tmp_config) or die "cannot write $tmp_config: $!\n";
    chmod 0600, $tmp_config;
    print $cf qq(url = "$url"\n);
    print $cf qq(request = "$method"\n);
    # cacert is only needed for TLS. Local LLMs on LAN often use http://,
    # in which case it works fine without a cacert file, so do not pass it.
    print $cf qq(cacert = "$CACERT"\n) if $url =~ m{^https://}i;
    for my $h (@$headers) {
        print $cf qq(header = "$h"\n);
    }
    print $cf qq(data-binary = "\@$tmp_req"\n) if $has_body;
    print $cf qq(output = "$tmp_resp"\n);
    print $cf qq(write-out = "%{http_code}"\n);
    print $cf qq(silent\n);
    print $cf qq(show-error\n);
    close $cf;
}

sub _build_curl_cmd {
    my ($tmp_config) = @_;
    return quote($CURL) . ' -K ' . quote($tmp_config);
}

sub _run_curl_sync {
    my ($tmp_config) = @_;
    my $cmd = _build_curl_cmd($tmp_config);
    my $out = `$cmd`;
    return defined $out ? $out : '';
}

sub _exec_curl_child {
    my ($tmp_config, $tmp_status) = @_;
    open(STDOUT, '>', $tmp_status) or POSIX::_exit(1);
    if (-x $CURL) {
        exec($CURL, '-K', $tmp_config);
    }
    else {
        exec('/bin/sh', '-c', _build_curl_cmd($tmp_config));
    }
    POSIX::_exit(127);
}

sub _wait_curl_timer {
    my ($pid, $start_time) = @_;
    local $| = 1;
    my $last_sec = -1;
    while (1) {
        my $kid = waitpid($pid, WNOHANG);
        last if $kid == $pid || $kid == -1;
        my $elapsed = int(time() - $start_time);
        $elapsed = 1 if $elapsed < 1;
        if ($elapsed != $last_sec) {
            print "\r\033[K" . format_thinking_status($elapsed);
            $last_sec = $elapsed;
        }
        select(undef, undef, undef, 0.2);
    }
}

sub _execute_curl {
    my ($tmp_config, $tmp_status, $use_live_timer, $start_time) = @_;
    my $http_code = '';

    if ($use_live_timer) {
        my $pid = (defined $ENV{CLAUDE_TEST_FORK_FAIL} && $ENV{CLAUDE_TEST_FORK_FAIL}) ? undef : fork();
        if (defined $pid) {
            if ($pid == 0) {
                _exec_curl_child($tmp_config, $tmp_status);
            }
            else {
                _wait_curl_timer($pid, $start_time);
                $http_code = _read_and_unlink($tmp_status);
            }
            $http_code = '' unless defined $http_code;
            $http_code =~ s/^\s+|\s+$//g;
            return $http_code;
        }

        # fork() failed: notify user if interactive rather than failing silently
        if (_is_tty_active()) {
            print "\r\033[K* Process fork unavailable ($!), running curl synchronously...\n";
        }
    }

    $http_code = _run_curl_sync($tmp_config);
    $http_code = '' unless defined $http_code;
    $http_code =~ s/^\s+|\s+$//g;
    return $http_code;
}

sub _decode_api_response {
    my ($http_code, $resp_body) = @_;
    $http_code = '000' if !defined $http_code || $http_code eq '';
    $resp_body = '(connection failed / no response from server)' if !defined $resp_body || $resp_body eq '';

    if ($http_code !~ /^2/) {
        die "API error (HTTP $http_code): $resp_body\n";
    }
    my $resp = MiniJSON::decode($resp_body);
    if (ref($resp) eq 'HASH') {
        if ($resp->{error}) {
            my $e = $resp->{error};
            die "API error: " . (ref($e) ? MiniJSON::encode($e) : $e) . "\n";
        }
        if (defined $resp->{type} && $resp->{type} eq 'error') {
            die "API error: " . MiniJSON::encode($resp) . "\n";
        }
    }
    return $resp;
}

sub _is_retryable_error {
    my ($err) = @_;
    return 1 unless defined $err && length $err;
    # Non-retryable HTTP client errors (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found)
    if ($err =~ /API error \(HTTP (?:400|401|403|404)\)/i) {
        return 0;
    }
    return 1;
}

sub _call_api_once {
    # $headers is an arrayref of header strings (e.g. "x-api-key: ...").
    # Thin transport layer that takes URL/headers from outside per provider;
    # this sub itself has no knowledge of whether it's Anthropic or Gemini.
    my ($url, $headers, $body_json, $method, $opts) = @_;
    $method = defined $method ? uc($method) : 'POST';
    my $has_body = _has_request_body($method, $body_json);
    my $silent = (defined $opts && ref($opts) eq 'HASH' && $opts->{silent}) ? 1 : 0;

    my $tmp_req    = _create_secure_tempfile('req', '.json');
    my $tmp_resp   = _create_secure_tempfile('resp', '.json');
    my $tmp_config = _create_secure_tempfile('curlcfg', '.txt');
    my $tmp_status = _create_secure_tempfile('status', '.txt');

    my ($http_code, $resp_body, $call_err);
    eval {
        _write_curl_config($tmp_config, $tmp_req, $tmp_resp, $url, $method, $headers, $body_json, $has_body);

        my $start_time = time();
        my $use_live_timer = (!$silent && _is_tty_active() && $has_body) ? 1 : 0;
        $http_code = _execute_curl($tmp_config, $tmp_status, $use_live_timer, $start_time);

        unless ($silent) {
            $LAST_API_ELAPSED = int(time() - $start_time);
            $LAST_API_ELAPSED = 1 if $LAST_API_ELAPSED < 1;
        }

        # For the same reason as STDIN (see comments at top), we do not use the
        # :encoding(UTF-8) layer here. In Perl 5.8.6, PerlIO :encoding(UTF-8) can split
        # multibyte characters across read buffer boundaries when reading responses
        # containing multibyte characters, causing "utf8 does not map to Unicode"
        # warnings and text corruption. Reading all raw bytes first and decoding them
        # together at the end avoids this issue.
        $resp_body = decode('UTF-8', _read_and_unlink($tmp_resp), FB_DEFAULT);
    };
    $call_err = $@;

    # Guaranteed cleanup of all temporary artifacts even on abort or error
    unlink $tmp_req if -e $tmp_req;
    unlink $tmp_config if -e $tmp_config;
    unlink $tmp_status if -e $tmp_status;
    unlink $tmp_resp if -e $tmp_resp;

    die $call_err if $call_err;

    return _decode_api_response($http_code, $resp_body);
}

sub call_api {
    my ($url, $headers, $body_json, $method, $opts) = @_;
    my $silent   = (defined $opts && ref($opts) eq 'HASH' && $opts->{silent}) ? 1 : 0;
    my $no_retry = (defined $opts && ref($opts) eq 'HASH' && $opts->{no_retry}) ? 1 : 0;
    my $max_retries = $no_retry ? 0 : get_max_retries();
    my $show_retry  = (!$silent && _is_tty_active() && _has_request_body($method, $body_json));

    my $last_err = '';
    for (my $attempt = 0; $attempt <= $max_retries; $attempt++) {
        my $resp = eval { _call_api_once($url, $headers, $body_json, $method, $opts) };
        if (!$@) {
            return $resp;
        }
        $last_err = $@;
        last unless _is_retryable_error($last_err);

        if ($attempt < $max_retries) {
            my $delay = get_retry_delay($attempt + 1);
            if ($show_retry) {
                print "\r\033[K" . format_retry_status($attempt + 1, $max_retries, $delay);
            }
            select(undef, undef, undef, $delay) if $delay > 0;
        }
    }
    die $last_err;
}

sub quote {
    my ($s) = @_;
    $s =~ s/'/'\\''/g;
    return "'$s'";
}
