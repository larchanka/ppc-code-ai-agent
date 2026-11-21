
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

sub _write_curl_config {
    my ($tmp_config, $tmp_req, $tmp_resp, $url, $method, $headers, $body_json, $has_body) = @_;
    if ($has_body) {
        open(my $fh, '>:encoding(UTF-8)', $tmp_req) or die "cannot write $tmp_req: $!\n";
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

sub _exec_curl_child {
    my ($tmp_config, $tmp_status) = @_;
    open(STDOUT, '>', $tmp_status) or POSIX::_exit(1);
    if (-x $CURL) {
        exec($CURL, '-K', $tmp_config);
    }
    else {
        exec('/bin/sh', '-c', quote($CURL) . ' -K ' . quote($tmp_config));
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
        my $pid = fork();
        if (!defined $pid) {
            $http_code = `@{[quote($CURL)]} -K @{[quote($tmp_config)]}`;
        }
        elsif ($pid == 0) {
            _exec_curl_child($tmp_config, $tmp_status);
        }
        else {
            _wait_curl_timer($pid, $start_time);
            $http_code = _read_and_unlink($tmp_status);
        }
    }
    else {
        $http_code = `@{[quote($CURL)]} -K @{[quote($tmp_config)]}`;
    }
    $http_code = '' unless defined $http_code;
    $http_code =~ s/^\s+|\s+$//g;
    return $http_code;
}

sub _decode_api_response {
    my ($http_code, $resp_body) = @_;
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

sub _call_api_once {
    # $headers is an arrayref of header strings (e.g. "x-api-key: ...").
    # Thin transport layer that takes URL/headers from outside per provider;
    # this sub itself has no knowledge of whether it's Anthropic or Gemini.
    my ($url, $headers, $body_json, $method) = @_;
    $method = defined $method ? uc($method) : 'POST';
    my $has_body = _has_request_body($method, $body_json);

    my $tmp_req    = "/tmp/code-agent-req-$$.json";
    my $tmp_resp   = "/tmp/code-agent-resp-$$.json";
    my $tmp_config = "/tmp/code-agent-curlcfg-$$.txt";
    my $tmp_status = "/tmp/code-agent-status-$$.txt";

    _write_curl_config($tmp_config, $tmp_req, $tmp_resp, $url, $method, $headers, $body_json, $has_body);

    my $start_time = time();
    my $use_live_timer = (_is_tty_active() && $has_body) ? 1 : 0;
    my $http_code = _execute_curl($tmp_config, $tmp_status, $use_live_timer, $start_time);

    $LAST_API_ELAPSED = int(time() - $start_time);
    $LAST_API_ELAPSED = 1 if $LAST_API_ELAPSED < 1;

    unlink $tmp_req if $has_body;
    unlink $tmp_config;
    unlink $tmp_status if -e $tmp_status;

    # For the same reason as STDIN (see comments at top), we do not use the
    # :encoding(UTF-8) layer here. In Perl 5.8.6, PerlIO :encoding(UTF-8) can split
    # multibyte characters across read buffer boundaries when reading responses
    # containing multibyte characters, causing "utf8 does not map to Unicode"
    # warnings and text corruption. Reading all raw bytes first and decoding them
    # together at the end avoids this issue.
    my $resp_body = decode('UTF-8', _read_and_unlink($tmp_resp), FB_DEFAULT);

    return _decode_api_response($http_code, $resp_body);
}

sub call_api {
    my ($url, $headers, $body_json, $method) = @_;
    my $max_retries = get_max_retries();
    my $retry_delay = get_retry_delay();
    my $show_retry  = _is_tty_active() && _has_request_body($method, $body_json);

    my $last_err = '';
    for (my $attempt = 0; $attempt <= $max_retries; $attempt++) {
        my $resp = eval { _call_api_once($url, $headers, $body_json, $method) };
        if (!$@) {
            return $resp;
        }
        $last_err = $@;
        if ($attempt < $max_retries) {
            if ($show_retry) {
                print "\r\033[K" . format_retry_status($attempt + 1, $max_retries, $retry_delay);
            }
            select(undef, undef, undef, $retry_delay) if $retry_delay > 0;
        }
    }
    die $last_err;
}

sub quote {
    my ($s) = @_;
    $s =~ s/'/'\\''/g;
    return "'$s'";
}
