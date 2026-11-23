# --- Remote Model Context Protocol (MCP) Client ---
# Implements JSON-RPC 2.0 communication over HTTP with remote MCP servers.
# 100% pure Perl 5.8.6 with zero CPAN dependencies.

our $MCP_TIMEOUT = 20;
our $MCP_PROTOCOL_VERSION = '2024-11-05';
our $MCP_REQ_ID = 1;

# Resolves MCP configuration file path.
# Precedence:
# 1. $ENV{CLAUDE_MCP_CONFIG}
# 2. Local mcp_servers.json in current directory
# 3. Primary: ~/.code-agent-mcp.json
# 4. Legacy:  ~/.claude-agent-mcp.json
sub get_mcp_config_path {
    if (defined $ENV{CLAUDE_MCP_CONFIG} && length $ENV{CLAUDE_MCP_CONFIG}) {
        my $path = $ENV{CLAUDE_MCP_CONFIG};
        my $home = $ENV{HOME} || '.';
        $path =~ s/^~(?:\/|$)/$home\//;
        return $path;
    }

    if (-f 'mcp_servers.json') {
        return 'mcp_servers.json';
    }

    my $home = $ENV{HOME} || '.';
    my $primary = "$home/.code-agent-mcp.json";
    my $legacy  = "$home/.claude-agent-mcp.json";

    return $legacy if !-e $primary && -e $legacy;
    return $primary if -e $primary;
    return undef;
}

# Normalizes headers (from hash or array of "Key: Value") into a hash ref.
sub _normalize_mcp_headers {
    my ($raw) = @_;
    my %headers;
    return \%headers unless defined $raw;

    if (ref($raw) eq 'HASH') {
        %headers = %$raw;
    } elsif (ref($raw) eq 'ARRAY') {
        for my $h (@$raw) {
            if ($h =~ /^\s*([^:]+)\s*:\s*(.*)$/) {
                my ($k, $v) = ($1, $2);
                $v =~ s/^\s+|\s+$//g;
                $headers{$k} = $v;
            }
        }
    }

    return \%headers;
}

# Parses JSON configuration representing remote MCP servers.
# Supports both:
# 1. Standard format: { "mcpServers": { "server_name": { ... } } }
# 2. Flat dictionary:  { "server_name": { ... } }
# Degrades gracefully on invalid JSON, non-hash data, or missing remote URLs.
sub parse_mcp_config {
    my ($json_text) = @_;
    return wantarray ? () : {} unless defined $json_text && length $json_text;

    my $data;
    eval {
        $data = MiniJSON::decode($json_text);
    };
    if ($@ || !defined $data || ref($data) ne 'HASH') {
        return wantarray ? () : {};
    }

    my $raw_servers;
    if (exists $data->{mcpServers} && ref($data->{mcpServers}) eq 'HASH') {
        $raw_servers = $data->{mcpServers};
    } else {
        $raw_servers = $data;
    }

    my %servers;
    for my $name (sort keys %$raw_servers) {
        my $srv = $raw_servers->{$name};
        next unless defined $srv && ref($srv) eq 'HASH';

        # Remote MCP servers require a valid url or endpoint
        my $url = $srv->{url} || $srv->{endpoint};
        next unless defined $url;
        $url =~ s/^\s+|\s+$//g;
        next if $url eq '';

        $servers{$name} = {
            name       => $name,
            url        => $url,
            headers    => _normalize_mcp_headers($srv->{headers}),
            status     => 'disconnected',
            session_id => undef,
            tools      => [],
        };
    }

    return wantarray ? %servers : \%servers;
}

# Reads entire file safely into a string, returning undef on failure.
sub mcp_read_file {
    my ($path) = @_;
    return undef unless defined $path && -f $path;
    if (open my $fh, '<', $path) {
        my $content = do { local $/; <$fh> };
        close $fh;
        return $content;
    }
    return undef;
}

# Discovers, loads and parses MCP server configuration.
# Accepts an optional source: file path, JSON string, or hashref.
# In discovery mode (no argument passed):
# - Loads file from get_mcp_config_path() if found.
# - Merges servers from $ENV{CLAUDE_MCP_SERVERS} if set.
# Stores discovered servers in %MCP_SERVERS and returns them.
sub load_mcp_config {
    my ($source) = @_;
    my %servers;

    if (defined $source) {
        if (ref($source) eq 'HASH') {
            my $encoded;
            eval { $encoded = MiniJSON::encode($source); };
            return defined $encoded ? parse_mcp_config($encoded) : (wantarray ? () : {});
        } elsif ($source =~ /^\s*\{/) {
            return parse_mcp_config($source);
        } else {
            my $content = mcp_read_file($source);
            return defined $content ? parse_mcp_config($content) : (wantarray ? () : {});
        }
    }

    # Discovery mode:
    # 1. Load from discovered config file
    my $file_path = get_mcp_config_path();
    if (defined $file_path) {
        my $content = mcp_read_file($file_path);
        if (defined $content) {
            my $parsed = parse_mcp_config($content);
            for my $k (keys %$parsed) {
                $servers{$k} = $parsed->{$k};
            }
        }
    }

    # 2. Merge from CLAUDE_MCP_SERVERS environment variable
    if (defined $ENV{CLAUDE_MCP_SERVERS} && length $ENV{CLAUDE_MCP_SERVERS}) {
        my $env_val = $ENV{CLAUDE_MCP_SERVERS};
        my $parsed;
        if ($env_val =~ /^\s*\{/) {
            $parsed = parse_mcp_config($env_val);
        } else {
            my $content = mcp_read_file($env_val);
            $parsed = parse_mcp_config($content) if defined $content;
        }
        if ($parsed && ref($parsed) eq 'HASH') {
            for my $k (keys %$parsed) {
                $servers{$k} = $parsed->{$k};
            }
        }
    }

    %MCP_SERVERS = %servers;
    return wantarray ? %MCP_SERVERS : \%MCP_SERVERS;
}

# --- MCP JSON-RPC 2.0 Protocol Engine ---

# Constructs a JSON-RPC 2.0 request hash.
# Auto-generates an incrementing numeric id if $id is omitted or undef.
sub mcp_build_request {
    my ($method, $params, $id) = @_;
    die "MCP error: method is required\n" unless defined $method && length $method;

    $id = $MCP_REQ_ID++ unless defined $id;
    my %req = (
        jsonrpc => '2.0',
        method  => $method,
        id      => $id,
    );
    $req{params} = $params if defined $params;
    return \%req;
}

# Constructs a JSON-RPC 2.0 notification hash (no id member).
sub mcp_build_notification {
    my ($method, $params) = @_;
    die "MCP error: method is required\n" unless defined $method && length $method;

    my %notif = (
        jsonrpc => '2.0',
        method  => $method,
    );
    $notif{params} = $params if defined $params;
    return \%notif;
}

# Convenience builder: MCP 'initialize' request
sub mcp_build_init_request {
    my ($id, $client_info) = @_;
    my $info = (defined $client_info && ref($client_info) eq 'HASH')
        ? $client_info
        : { name => 'ppc-code-ai-agent', version => '1.0.0' };

    return mcp_build_request(
        'initialize',
        {
            protocolVersion => $MCP_PROTOCOL_VERSION,
            capabilities    => {},
            clientInfo      => $info,
        },
        $id
    );
}

# Convenience builder: MCP 'notifications/initialized' notification
sub mcp_build_init_notification {
    return mcp_build_notification('notifications/initialized');
}

# Convenience builder: MCP 'tools/list' request
sub mcp_build_tools_list_request {
    my ($cursor, $id) = @_;
    my $params = (defined $cursor && length $cursor) ? { cursor => $cursor } : {};
    return mcp_build_request('tools/list', $params, $id);
}

# Convenience builder: MCP 'tools/call' request
sub mcp_build_tools_call_request {
    my ($tool_name, $arguments, $id) = @_;
    die "MCP error: tool name is required for tools/call\n" unless defined $tool_name && length $tool_name;

    my $args = (defined $arguments && ref($arguments) eq 'HASH') ? $arguments : {};
    return mcp_build_request('tools/call', { name => $tool_name, arguments => $args }, $id);
}

# Parses a JSON-RPC 2.0 response (JSON text or HASH ref).
# Extracts and returns the 'result' member or dies with a descriptive error.
sub mcp_parse_response {
    my ($resp) = @_;
    die "MCP error: Empty or invalid JSON-RPC response\n" unless defined $resp;

    my $data;
    if (ref($resp) eq 'HASH') {
        $data = $resp;
    } elsif (!ref($resp) && length($resp)) {
        eval { $data = MiniJSON::decode($resp); };
        if ($@ || !defined $data || ref($data) ne 'HASH') {
            die "MCP error: Invalid JSON-RPC response\n";
        }
    } else {
        die "MCP error: Invalid JSON-RPC response\n";
    }

    if (exists $data->{error} && defined $data->{error}) {
        my $err = $data->{error};
        if (ref($err) eq 'HASH') {
            my $msg  = defined $err->{message} ? $err->{message} : 'Unknown error';
            my $code = defined $err->{code}    ? $err->{code}    : 'N/A';
            my $detail = (defined $err->{data} && !ref($err->{data}) && length($err->{data}))
                ? " ($err->{data})"
                : '';
            die "MCP error [$code]: $msg$detail\n";
        } else {
            die "MCP error: $err\n";
        }
    }

    if (exists $data->{result}) {
        return $data->{result};
    }

    die "MCP error: Response contains neither 'result' nor 'error'\n";
}

# Normalizes MCP tool schema by mapping 'inputSchema' to 'input_schema'
sub mcp_normalize_tool_schema {
    my ($tool_or_schema) = @_;
    return { type => 'object', properties => {} } unless defined $tool_or_schema;

    if (ref($tool_or_schema) eq 'HASH') {
        if (exists $tool_or_schema->{inputSchema} && defined $tool_or_schema->{inputSchema}) {
            $tool_or_schema->{input_schema} = $tool_or_schema->{inputSchema};
            return $tool_or_schema->{input_schema};
        }
        if (exists $tool_or_schema->{input_schema} && defined $tool_or_schema->{input_schema}) {
            return $tool_or_schema->{input_schema};
        }
        if (exists $tool_or_schema->{type} || exists $tool_or_schema->{properties}) {
            return $tool_or_schema;
        }
        my $default_schema = { type => 'object', properties => {} };
        $tool_or_schema->{input_schema} = $default_schema if exists $tool_or_schema->{name};
        return $default_schema;
    }

    return { type => 'object', properties => {} };
}

# Normalizes an MCP tool definition for integration into @TOOLS.
# Namespaces tool name as 'mcp__<server>__<name>' when server name is supplied.
sub mcp_normalize_tool {
    my ($raw_tool, $server_name) = @_;
    return undef unless defined $raw_tool && ref($raw_tool) eq 'HASH';

    my $orig_name = defined $raw_tool->{name} ? $raw_tool->{name} : '';
    my $namespaced = (defined $server_name && length $server_name)
        ? "mcp__${server_name}__${orig_name}"
        : $orig_name;

    my $schema = mcp_normalize_tool_schema($raw_tool);
    my %norm = (
        name         => $namespaced,
        description  => defined $raw_tool->{description} ? $raw_tool->{description} : '',
        input_schema => $schema,
    );
    if (defined $server_name && length $server_name) {
        $norm{server}        = $server_name;
        $norm{original_name} = $orig_name;
    }
    return \%norm;
}

# --- Remote MCP HTTP Transport Client ---

our $MCP_TMP_COUNTER = 0;

sub _mcp_get_curl {
    return $ENV{CLAUDE_CURL} if defined $ENV{CLAUDE_CURL} && length $ENV{CLAUDE_CURL};
    return $CURL if defined $CURL && length $CURL;
    return (-x '/usr/local/code-toolchain/bin/curl' ? '/usr/local/code-toolchain/bin/curl' : 'curl');
}

sub _mcp_get_cacert {
    return $ENV{CLAUDE_CACERT} if defined $ENV{CLAUDE_CACERT} && length $ENV{CLAUDE_CACERT};
    return $CACERT if defined $CACERT && length $CACERT;
    return (-f '/usr/local/code-toolchain/cacert.pem' ? '/usr/local/code-toolchain/cacert.pem' : '');
}

sub _mcp_quote {
    my ($s) = @_;
    return "''" unless defined $s;
    $s =~ s/'/'\\''/g;
    return "'$s'";
}

sub _mcp_prepare_headers {
    my ($server) = @_;
    my @headers;
    my %seen;

    if (defined $server->{headers} && ref($server->{headers}) eq 'HASH') {
        for my $k (sort keys %{$server->{headers}}) {
            my $v = $server->{headers}{$k};
            push @headers, "$k: $v";
            $seen{lc($k)} = 1;
        }
    }

    push @headers, "Content-Type: application/json" unless $seen{'content-type'};
    push @headers, "Accept: application/json" unless $seen{'accept'};

    if (defined $server->{session_id} && length $server->{session_id} && !$seen{'mcp-session-id'}) {
        push @headers, "mcp-session-id: $server->{session_id}";
    }

    return \@headers;
}

sub _mcp_write_curl_config {
    my ($cfg_file, $req_file, $resp_file, $hdr_file, $url, $headers, $cacert, $timeout) = @_;

    open(my $cf, '>', $cfg_file) or die "cannot write $cfg_file: $!\n";
    chmod 0600, $cfg_file;

    print $cf qq(url = "$url"\n);
    print $cf qq(request = "POST"\n);
    print $cf qq(cacert = "$cacert"\n) if $url =~ m{^https://}i && defined $cacert && length $cacert && -f $cacert;

    for my $h (@$headers) {
        print $cf qq(header = "$h"\n);
    }

    print $cf qq(data-binary = "\@$req_file"\n);
    print $cf qq(output = "$resp_file"\n);
    print $cf qq(dump-header = "$hdr_file"\n);
    print $cf qq(write-out = "%{http_code}"\n);
    print $cf qq(max-time = "$timeout"\n);
    print $cf qq(silent\n);
    print $cf qq(show-error\n);
    close $cf;
}

sub _mcp_extract_session_id {
    my ($hdr_file) = @_;
    return undef unless defined $hdr_file && -f $hdr_file;

    my $session_id = undef;
    if (open(my $hf, '<', $hdr_file)) {
        while (my $line = <$hf>) {
            if ($line =~ /^\s*mcp-session-id\s*:\s*(.+)$/i) {
                my $val = $1;
                $val =~ s/^\s+|\s+$//g;
                $val =~ s/[\r\n]+$//;
                $session_id = $val if length $val;
            }
        }
        close $hf;
    }
    return $session_id;
}

sub _mcp_format_result {
    my ($http_code, $resp_body, $decoded, $session_id) = @_;
    my $code_num = ($http_code =~ /^\d+$/) ? int($http_code) : 0;

    my $res;
    if ($code_num >= 200 && $code_num < 300) {
        if (defined $decoded && ref($decoded) eq 'HASH') {
            $res = $decoded;
            my $has_err = (exists $res->{error} && defined $res->{error}) ? 1 : 0;
            $res->{_http_code} = $code_num;
            $res->{_success}   = $has_err ? 0 : 1;
            $res->{session_id} = $session_id if defined $session_id && !exists $res->{session_id};
        } elsif (defined $decoded && ref($decoded) eq 'ARRAY') {
            $res = {
                jsonrpc    => '2.0',
                error      => { code => -32700, message => "Parse error: expected JSON object but received array" },
                _http_code => $code_num,
                _success   => 0,
                _raw       => $resp_body,
            };
            $res->{session_id} = $session_id if defined $session_id;
        } else {
            $res = {
                jsonrpc    => '2.0',
                error      => { code => -32700, message => "Parse error: non-JSON response from server" },
                _http_code => $code_num,
                _success   => 0,
                _raw       => $resp_body,
            };
            $res->{session_id} = $session_id if defined $session_id;
        }
    } else {
        my $err_msg;
        if ($code_num == 0) {
            $err_msg = "Network error: failed to connect to MCP server";
        } else {
            $err_msg = "HTTP error $code_num";
            if (defined $decoded && ref($decoded) eq 'HASH') {
                if ($decoded->{error}) {
                    my $e = $decoded->{error};
                    $err_msg .= ": " . (ref($e) eq 'HASH' ? ($e->{message} || MiniJSON::encode($e)) : $e);
                } elsif ($decoded->{message}) {
                    $err_msg .= ": $decoded->{message}";
                }
            } elsif (length $resp_body) {
                my $snippet = substr($resp_body, 0, 100);
                $snippet =~ s/\s+/ /g;
                $err_msg .= ": $snippet";
            }
        }
        $res = {
            jsonrpc    => '2.0',
            error      => { code => -32000, message => $err_msg },
            _http_code => $code_num,
            _success   => 0,
            _raw       => $resp_body,
        };
        $res->{session_id} = $session_id if defined $session_id;
    }

    return $res;
}

sub mcp_http_post {
    my ($server_info, $payload) = @_;

    # Resolve server structure
    my $server;
    if (ref($server_info) eq 'HASH') {
        $server = $server_info;
    } elsif (defined $server_info && exists $MCP_SERVERS{$server_info}) {
        $server = $MCP_SERVERS{$server_info};
    } elsif (defined $server_info && !ref($server_info) && length $server_info) {
        $server = { url => $server_info };
    } else {
        my $err = {
            jsonrpc    => '2.0',
            error      => { code => -32602, message => "MCP error: missing or invalid server info" },
            _http_code => 0,
            _success   => 0,
        };
        return wantarray ? ($err, "missing or invalid server info") : $err;
    }

    my $url = $server->{url};
    if (!defined $url || $url eq '') {
        my $err = {
            jsonrpc    => '2.0',
            error      => { code => -32602, message => "MCP error: server URL is required" },
            _http_code => 0,
            _success   => 0,
        };
        return wantarray ? ($err, "server URL is required") : $err;
    }

    # Encode payload body
    my $body_json = '';
    if (ref($payload)) {
        eval { $body_json = MiniJSON::encode($payload); };
        if ($@) {
            my $err = {
                jsonrpc    => '2.0',
                error      => { code => -32700, message => "MCP error: failed to encode payload: $@" },
                _http_code => 0,
                _success   => 0,
            };
            return wantarray ? ($err, "failed to encode payload") : $err;
        }
    } elsif (defined $payload) {
        $body_json = $payload;
    }

    my $tmp_tag    = "$$-" . (++$MCP_TMP_COUNTER);
    my $tmp_req    = "/tmp/code-agent-mcp-req-$tmp_tag.json";
    my $tmp_resp   = "/tmp/code-agent-mcp-resp-$tmp_tag.json";
    my $tmp_config = "/tmp/code-agent-mcp-cfg-$tmp_tag.txt";
    my $tmp_hdr    = "/tmp/code-agent-mcp-hdr-$tmp_tag.txt";

    # Write request body file
    if (open(my $rf, '>:encoding(UTF-8)', $tmp_req)) {
        chmod 0600, $tmp_req;
        print $rf $body_json;
        close $rf;
    } else {
        my $err = {
            jsonrpc    => '2.0',
            error      => { code => -32000, message => "MCP error: cannot write request tempfile: $!" },
            _http_code => 0,
            _success   => 0,
        };
        return wantarray ? ($err, "cannot write request tempfile") : $err;
    }

    my $headers = _mcp_prepare_headers($server);
    my $cacert  = _mcp_get_cacert();
    my $timeout = $MCP_TIMEOUT || 20;

    eval {
        _mcp_write_curl_config($tmp_config, $tmp_req, $tmp_resp, $tmp_hdr, $url, $headers, $cacert, $timeout);
    };
    if ($@) {
        unlink $tmp_req;
        my $err = {
            jsonrpc    => '2.0',
            error      => { code => -32000, message => "MCP error: cannot write curl config: $@" },
            _http_code => 0,
            _success   => 0,
        };
        return wantarray ? ($err, "cannot write curl config") : $err;
    }

    # Execute curl
    my $curl = _mcp_get_curl();
    my $http_code = `@{[ _mcp_quote($curl) ]} -K @{[ _mcp_quote($tmp_config) ]} 2>/dev/null`;
    $http_code = '' unless defined $http_code;
    $http_code =~ s/^\s+|\s+$//g;

    # Read response body
    my $resp_body = '';
    if (-f $tmp_resp && open(my $bf, '<', $tmp_resp)) {
        local $/;
        my $raw = <$bf>;
        $resp_body = $raw if defined $raw;
        close $bf;
    }
    if (length $resp_body) {
        eval { $resp_body = Encode::decode('UTF-8', $resp_body, Encode::FB_DEFAULT); };
    }

    my $session_id = _mcp_extract_session_id($tmp_hdr);

    # Clean up temp files
    unlink $tmp_req;
    unlink $tmp_config;
    unlink $tmp_resp if -e $tmp_resp;
    unlink $tmp_hdr if -e $tmp_hdr;

    # Decode JSON body if possible
    my $decoded;
    if (length $resp_body) {
        eval { $decoded = MiniJSON::decode($resp_body); };
    }

    # Check session_id in payload if not found in headers
    if (!defined $session_id && defined $decoded && ref($decoded) eq 'HASH' && ref($decoded->{result}) eq 'HASH') {
        if (defined $decoded->{result}{sessionId} && !ref($decoded->{result}{sessionId})) {
            $session_id = $decoded->{result}{sessionId};
        } elsif (ref($decoded->{result}{_meta}) eq 'HASH' && defined $decoded->{result}{_meta}{sessionId}) {
            $session_id = $decoded->{result}{_meta}{sessionId};
        }
    }

    # Update server info if tracked
    if (ref($server) eq 'HASH') {
        $server->{session_id} = $session_id if defined $session_id;
        $server->{last_http_code} = ($http_code =~ /^\d+$/) ? int($http_code) : 0;
    }

    my $result_hash = _mcp_format_result($http_code, $resp_body, $decoded, $session_id);

    my $err_str = undef;
    if (!$result_hash->{_success}) {
        my $err_val = $result_hash->{error};
        $err_str = ref($err_val) eq 'HASH'
            ? ($err_val->{message} || (eval { MiniJSON::encode($err_val) } || 'Unknown error'))
            : (defined $err_val ? "$err_val" : 'Unknown error');
    }

    if (ref($server) eq 'HASH') {
        $server->{last_error} = $err_str;
    }

    return wantarray ? ($result_hash, $err_str) : $result_hash;
}

# --- Server Connection Lifecycle & Dynamic Tool Registration ---

# Unregisters all tools belonging to $server_name from %MCP_TOOLS and @TOOLS.
sub mcp_unregister_server_tools {
    my ($server_name) = @_;
    return unless defined $server_name && length $server_name;

    my %to_remove;
    for my $tool_name (keys %MCP_TOOLS) {
        if (defined $MCP_TOOLS{$tool_name}{server} && $MCP_TOOLS{$tool_name}{server} eq $server_name) {
            $to_remove{$tool_name} = 1;
            delete $MCP_TOOLS{$tool_name};
            delete $UNTRUSTED_OUTPUT_TOOLS{$tool_name};
        }
    }
    if (exists $MCP_SERVERS{$server_name} && ref($MCP_SERVERS{$server_name}{tools}) eq 'ARRAY') {
        for my $tn (@{ $MCP_SERVERS{$server_name}{tools} }) {
            $to_remove{$tn} = 1;
            delete $MCP_TOOLS{$tn};
            delete $UNTRUSTED_OUTPUT_TOOLS{$tn};
        }
    }

    if (keys %to_remove) {
        @TOOLS = grep {
            !($_->{name} && exists $to_remove{$_->{name}})
            && !(defined $_->{server} && $_->{server} eq $server_name)
        } @TOOLS;
    }
}

# Disconnects an MCP server, removing its registered tools from %MCP_TOOLS and @TOOLS.
sub mcp_disconnect_server {
    my ($server_name) = @_;
    return 0 unless defined $server_name && exists $MCP_SERVERS{$server_name};

    mcp_unregister_server_tools($server_name);
    my $server = $MCP_SERVERS{$server_name};
    $server->{status}     = 'disconnected';
    $server->{tools}      = [];
    $server->{session_id} = undef;
    return 1;
}

# Queries tools/list with pagination support, returning array of raw tool definitions.
sub _mcp_fetch_server_tools {
    my ($server, $server_name) = @_;
    my @discovered;
    my $cursor = undef;

    while (1) {
        my $tl_req = mcp_build_tools_list_request($cursor);
        my ($tl_res, $tl_err) = mcp_http_post($server, $tl_req);

        if (!$tl_res || !$tl_res->{_success} || !exists $tl_res->{result}) {
            my $err_msg = $tl_err
                || (ref($tl_res->{error}) eq 'HASH' ? $tl_res->{error}{message} : $tl_res->{error})
                || 'tools/list failed';
            warn "[MCP] Warning: Failed to retrieve tools from '$server_name': $err_msg\n";
            last;
        }

        my $res_data = $tl_res->{result};
        if (ref($res_data) eq 'HASH' && ref($res_data->{tools}) eq 'ARRAY') {
            push @discovered, @{ $res_data->{tools} };
        }

        $cursor = (ref($res_data) eq 'HASH' && defined $res_data->{nextCursor} && length $res_data->{nextCursor})
            ? $res_data->{nextCursor}
            : undef;
        last unless defined $cursor;
    }

    return @discovered;
}

# Performs MCP handshake (initialize -> notifications/initialized -> tools/list)
# and registers discovered tools into %MCP_TOOLS and @TOOLS.
# Does not die on errors; logs warning and updates server status.
sub mcp_connect_server {
    my ($server_ref) = @_;
    my $server;
    my $server_name;

    if (ref($server_ref) eq 'HASH') {
        $server = $server_ref;
        $server_name = $server->{name} || 'remote';
        $MCP_SERVERS{$server_name} = $server unless exists $MCP_SERVERS{$server_name};
    } elsif (defined $server_ref && length $server_ref) {
        $server_name = $server_ref;
        $server = $MCP_SERVERS{$server_name};
    }

    if (!defined $server) {
        my $msg = "Server not found" . (defined $server_name ? ": '$server_name'" : "");
        warn "[MCP] $msg\n";
        return wantarray ? (0, $msg) : 0;
    }

    # Step 1: initialize request
    my $init_req = mcp_build_init_request();
    my ($init_res, $init_err) = mcp_http_post($server, $init_req);

    if (!$init_res || !$init_res->{_success} || !exists $init_res->{result}) {
        my $err_msg = $init_err
            || (ref($init_res->{error}) eq 'HASH' ? $init_res->{error}{message} : $init_res->{error})
            || 'Initialization failed';
        $server->{status}     = 'error';
        $server->{last_error} = $err_msg;
        warn "[MCP] Failed to connect to server '$server_name': $err_msg\n";
        return wantarray ? (0, $err_msg) : 0;
    }

    my $init_data = $init_res->{result};
    if (ref($init_data) eq 'HASH') {
        $server->{server_info}      = $init_data->{serverInfo} if ref($init_data->{serverInfo}) eq 'HASH';
        $server->{protocol_version} = $init_data->{protocolVersion} if defined $init_data->{protocolVersion};
        $server->{capabilities}     = $init_data->{capabilities} if ref($init_data->{capabilities}) eq 'HASH';
    }

    # Step 2: notifications/initialized
    my $init_notif = mcp_build_init_notification();
    mcp_http_post($server, $init_notif);

    # Step 3: tools/list (supporting pagination via nextCursor)
    my @discovered_tools = _mcp_fetch_server_tools($server, $server_name);

    # Step 4: Register discovered tools into %MCP_TOOLS and @TOOLS
    # First unregister any previous tools for this server to prevent duplicates on reconnect
    mcp_unregister_server_tools($server_name);

    my @registered_names;
    for my $raw_tool (@discovered_tools) {
        my $norm = mcp_normalize_tool($raw_tool, $server_name);
        next unless defined $norm;

        $MCP_TOOLS{$norm->{name}} = $norm;
        $UNTRUSTED_OUTPUT_TOOLS{$norm->{name}} = 1;
        push @TOOLS, $norm;
        push @registered_names, $norm->{name};
    }

    $server->{status}     = 'connected';
    $server->{tools}      = \@registered_names;
    $server->{last_error} = undef;

    return wantarray ? (1, scalar(@registered_names)) : 1;
}

# --- Tool Invocation & Output Formatting ---

# Formats a single item from an MCP tools/call content array.
sub _mcp_format_content_item {
    my ($item) = @_;
    return '' unless defined $item;
    return "$item" unless ref($item);

    if (ref($item) eq 'HASH') {
        if (defined $item->{text}) {
            return $item->{text};
        }
        if (defined $item->{data}) {
            my $mime = defined $item->{mimeType} ? $item->{mimeType} : 'binary';
            return "[image data: $mime]";
        }
        if (defined $item->{resource}) {
            my $r = $item->{resource};
            return ref($r) eq 'HASH'
                ? (defined $r->{text} ? $r->{text} : (defined $r->{uri} ? $r->{uri} : MiniJSON::encode($r)))
                : "$r";
        }
        my $enc = eval { MiniJSON::encode($item) };
        return defined $enc ? $enc : "$item";
    }

    return "$item";
}

# Formats MCP tools/call result payload into a display/model string.
sub mcp_format_call_result {
    my ($result) = @_;
    return '' unless defined $result;
    return "$result" unless ref($result);

    if (ref($result) eq 'HASH') {
        # Standard MCP tools/call result: { content => [...], isError => false }
        if (exists $result->{content} && ref($result->{content}) eq 'ARRAY') {
            my @parts = map { _mcp_format_content_item($_) } @{ $result->{content} };
            my $out = join("\n", @parts);
            $out = "Error: $out" if $result->{isError} && $out !~ /^Error\b/i;
            return $out;
        } elsif (exists $result->{content} && !ref($result->{content})) {
            my $out = "$result->{content}";
            $out = "Error: $out" if $result->{isError} && $out !~ /^Error\b/i;
            return $out;
        }

        # Check for simple text or message keys
        return $result->{text}    if defined $result->{text};
        return $result->{message} if defined $result->{message};

        # Fallback: encode as JSON
        my $encoded = eval { MiniJSON::encode($result) };
        return defined $encoded ? $encoded : "$result";
    } elsif (ref($result) eq 'ARRAY') {
        my $encoded = eval { MiniJSON::encode($result) };
        return defined $encoded ? $encoded : join("\n", @$result);
    }

    return "$result";
}

# Dispatches execution of a remote MCP tool.
# Enforces confirmation via confirm_tool() in manual mode.
# Sends JSON-RPC tools/call over HTTP transport.
# Formats response using mcp_format_call_result().
sub mcp_execute_tool {
    my ($tool_name, $arguments) = @_;
    return "Error: tool name is required" unless defined $tool_name && length $tool_name;

    my $tool_info = exists $MCP_TOOLS{$tool_name} ? $MCP_TOOLS{$tool_name} : undef;
    if (!defined $tool_info) {
        return "Error: unknown MCP tool '$tool_name'";
    }

    my $server_name = $tool_info->{server};
    my $remote_name = $tool_info->{original_name} || $tool_name;

    if (!defined $server_name || !exists $MCP_SERVERS{$server_name}) {
        return "Error: MCP server for tool '$tool_name' not found";
    }

    my $server = $MCP_SERVERS{$server_name};
    if (!defined $server->{status} || $server->{status} ne 'connected') {
        return "Error: MCP server '$server_name' is not connected";
    }

    # Manual mode confirmation
    unless (confirm_tool("Call remote MCP tool '$tool_name'?")) {
        return "Cancelled by user.";
    }

    my $call_req = mcp_build_tools_call_request($remote_name, $arguments);
    my ($call_res, $call_err) = mcp_http_post($server, $call_req);

    if (!$call_res || !$call_res->{_success} || !exists $call_res->{result}) {
        my $err_msg = $call_err
            || (ref($call_res->{error}) eq 'HASH' ? $call_res->{error}{message} : $call_res->{error})
            || "Call to '$tool_name' failed";
        return "Error: $err_msg";
    }

    return mcp_format_call_result($call_res->{result});
}

# Connects all configured MCP servers.
# Loads configuration automatically if %MCP_SERVERS is empty.
# Returns the number of successfully connected servers.
sub mcp_init_all {
    load_mcp_config() unless keys %MCP_SERVERS;
    my $connected = 0;
    for my $name (sort keys %MCP_SERVERS) {
        my $ok = mcp_connect_server($name);
        $connected++ if $ok;
    }
    return $connected;
}

# --- Interactive /mcp Slash Command Handlers ---

sub _mcp_cmd_help {
    my ($out_fh) = @_;
    print $out_fh "Usage:\n";
    print $out_fh "  /mcp                            - List configured MCP servers and tools\n";
    print $out_fh "  /mcp list                       - List configured MCP servers and tools\n";
    print $out_fh "  /mcp add <name> <url> [headers] - Add and connect a new remote MCP server\n";
    print $out_fh "  /mcp remove <name>              - Remove an MCP server and its tools\n";
    print $out_fh "  /mcp refresh                    - Reconnect and refresh tools from all servers\n";
    return undef;
}

sub _mcp_cmd_list {
    my ($out_fh) = @_;
    if (!keys %MCP_SERVERS) {
        print $out_fh "No MCP servers configured.\n";
        print $out_fh "Use '/mcp add <name> <url> [headers]' to connect a server.\n";
        return 0;
    }

    print $out_fh "Configured MCP servers:\n";
    for my $name (sort keys %MCP_SERVERS) {
        my $srv = $MCP_SERVERS{$name};
        my $status = defined $srv->{status} ? $srv->{status} : 'unknown';
        my $url    = defined $srv->{url} ? $srv->{url} : '';
        print $out_fh "  * $name [$status] - $url\n";

        my @tools = (ref($srv->{tools}) eq 'ARRAY') ? @{ $srv->{tools} } : ();
        my $cnt = scalar @tools;
        if ($cnt > 0) {
            print $out_fh "    Tools ($cnt): " . join(', ', @tools) . "\n";
        } else {
            print $out_fh "    Tools (0)\n";
        }
        if (defined $srv->{last_error} && length $srv->{last_error}) {
            print $out_fh "    Error: $srv->{last_error}\n";
        }
    }
    return scalar keys %MCP_SERVERS;
}

sub _mcp_cmd_add {
    my ($args_str, $out_fh) = @_;
    $args_str = '' unless defined $args_str;
    $args_str =~ s/^\s+|\s+$//g;

    unless ($args_str =~ /^(\S+)\s+(\S+)(?:\s+(.*))?$/s) {
        print $out_fh "Usage: /mcp add <name> <url> [headers]\n";
        return undef;
    }
    my ($name, $url, $headers_raw) = ($1, $2, $3);

    my $headers = {};
    if (defined $headers_raw && length $headers_raw) {
        $headers_raw =~ s/^\s+|\s+$//g;
        if ($headers_raw =~ /^\{.*\}$/s) {
            eval { $headers = MiniJSON::decode($headers_raw); };
            if ($@ || ref($headers) ne 'HASH') {
                print $out_fh "Warning: Could not parse headers as JSON: $@\n" if $@;
                $headers = {};
            }
        } elsif ($headers_raw =~ /^([^:]+)\s*:\s*(.*)$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^\s+|\s+$//g;
            $headers->{$k} = $v;
        }
    }

    if (exists $MCP_SERVERS{$name}) {
        mcp_disconnect_server($name);
    }

    $MCP_SERVERS{$name} = {
        name       => $name,
        url        => $url,
        headers    => $headers,
        status     => 'disconnected',
        session_id => undef,
        tools      => [],
    };

    my ($ok, $count_or_err) = mcp_connect_server($name);
    if ($ok) {
        my $num = defined $count_or_err ? $count_or_err : 0;
        print $out_fh "Connected to MCP server '$name'. Discovered $num tool(s).\n";
        return 1;
    } else {
        my $err = defined $count_or_err ? $count_or_err : 'Connection failed';
        print $out_fh "Failed to connect to MCP server '$name': $err\n";
        return undef;
    }
}

sub _mcp_cmd_remove {
    my ($args_str, $out_fh) = @_;
    $args_str = '' unless defined $args_str;
    $args_str =~ s/^\s+|\s+$//g;

    unless (length $args_str) {
        print $out_fh "Usage: /mcp remove <name>\n";
        return undef;
    }

    my $name = (split /\s+/, $args_str)[0];
    unless (exists $MCP_SERVERS{$name}) {
        print $out_fh "Error: MCP server '$name' not found.\n";
        return undef;
    }

    mcp_disconnect_server($name);
    delete $MCP_SERVERS{$name};
    print $out_fh "Removed MCP server '$name'.\n";
    return 1;
}

sub _mcp_cmd_refresh {
    my ($out_fh) = @_;
    my @names = sort keys %MCP_SERVERS;
    if (!@names) {
        print $out_fh "No MCP servers configured to refresh.\n";
        return 0;
    }

    my $connected = 0;
    for my $name (@names) {
        my ($ok) = mcp_connect_server($name);
        $connected++ if $ok;
    }

    my $total = scalar @names;
    my $total_tools = scalar keys %MCP_TOOLS;
    print $out_fh "Refreshed $connected/$total MCP server(s). $total_tools tool(s) registered.\n";
    return $connected;
}

# Top-level dispatcher for the /mcp interactive slash command.
sub handle_mcp_command {
    my ($args, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    if (!defined $args || $args =~ /^\s*$/) {
        return _mcp_cmd_list($out_fh);
    }

    $args =~ s/^\s+|\s+$//g;
    my ($subcmd, $rest) = split(/\s+/, $args, 2);
    $subcmd = lc($subcmd);

    if ($subcmd eq 'list') {
        return _mcp_cmd_list($out_fh);
    } elsif ($subcmd eq 'add') {
        return _mcp_cmd_add($rest, $out_fh);
    } elsif ($subcmd eq 'remove' || $subcmd eq 'rm' || $subcmd eq 'delete') {
        return _mcp_cmd_remove($rest, $out_fh);
    } elsif ($subcmd eq 'refresh' || $subcmd eq 'reload') {
        return _mcp_cmd_refresh($out_fh);
    } else {
        return _mcp_cmd_help($out_fh);
    }
}

1;
