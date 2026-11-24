
# --- Provider-specific request building and response parsing ---
# Conversation history (@messages) is kept internally in Anthropic content blocks format
# (role => user/assistant, content => string or [{type=>...}]). Gemini and OpenAI formats
# are converted on the wire, keeping the loop and run_tool provider-agnostic.

sub build_headers {
    if ($PROVIDER eq 'gemini') {
        return [ "x-goog-api-key: $API_KEY", "content-type: application/json" ];
    }
    if ($PROVIDER eq 'openai') {
        return [ "authorization: Bearer $API_KEY", "content-type: application/json" ];
    }
    return [
        "x-api-key: $API_KEY",
        "anthropic-version: $ANTHROPIC_VERSION",
        "content-type: application/json",
    ];
}

sub build_request {
    my ($messages, $tools, $system, $max_tokens) = @_;
    $system = get_effective_system_prompt() unless defined $system;
    $max_tokens = $MAX_TOKENS unless defined $max_tokens;
    return build_request_gemini($messages, $tools, $system, $max_tokens)   if $PROVIDER eq 'gemini';
    return build_request_openai($messages, $tools, $system, $max_tokens)   if $PROVIDER eq 'openai';
    return build_request_anthropic($messages, $tools, $system, $max_tokens);
}

sub build_request_anthropic {
    my ($messages, $tools, $system, $max_tokens) = @_;
    $max_tokens = $MAX_TOKENS unless defined $max_tokens;

    my @sanitized;
    for my $msg (@$messages) {
        if (!ref $msg->{content}) {
            push @sanitized, $msg;
            next;
        }
        my @filtered_blocks;
        for my $block (@{ $msg->{content} }) {
            if (ref $block eq 'HASH' && defined $block->{type} && $block->{type} eq 'thinking') {
                # Anthropic API requires a cryptographic signature for thinking blocks.
                # Omit unsigned thinking blocks (e.g. from Gemini or OpenAI).
                next unless defined $block->{signature} && $block->{signature} ne '';
            }
            push @filtered_blocks, $block;
        }
        push @sanitized, { %$msg, content => \@filtered_blocks };
    }

    return {
        model      => $MODEL,
        max_tokens => $max_tokens,
        system     => $system,
        messages   => \@sanitized,
        tools      => $tools,
    };
}

sub build_request_gemini {
    my ($messages, $tools, $system, $max_tokens) = @_;
    $max_tokens = $MAX_TOKENS unless defined $max_tokens;

    my @contents;
    for my $msg (@$messages) {
        my $role = $msg->{role} eq 'assistant' ? 'model' : 'user';
        my @parts;
        if (!ref $msg->{content}) {
            push @parts, { text => $msg->{content} };
        }
        else {
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'text') {
                    my $part = { text => $block->{text} };
                    $part->{thoughtSignature} = $block->{thought_signature} if defined $block->{thought_signature};
                    push @parts, $part;
                }
                elsif ($block->{type} eq 'tool_use') {
                    my $part = { functionCall => { name => $block->{name}, args => $block->{input} } };
                    # Gemini 3.x returns a 400 error unless the same thoughtSignature
                    # received with functionCall is reattached when sending it back
                    # (it worked without it up to Gemini 2.5, but became mandatory in 3.x).
                    $part->{thoughtSignature} = $block->{thought_signature} if defined $block->{thought_signature};
                    push @parts, $part;
                }
                elsif ($block->{type} eq 'tool_result') {
                    # Gemini correlates tool results by name rather than tool_use_id
                    push @parts, {
                        functionResponse => {
                            name     => $block->{name},
                            response => { output => $block->{content} },
                        },
                    };
                }
            }
        }
        push @contents, { role => $role, parts => \@parts };
    }

# Sanitizes OpenAPI/JSON Schema for Google Gemini FunctionDeclaration parameters.
# Gemini uses a strict protobuf-mapped schema subset that rejects unknown fields
# (such as 'additionalProperties', '$schema', 'title') and does not support 'anyOf'/'oneOf'.
sub _clean_gemini_schema {
    my ($schema) = @_;
    return { type => 'object', properties => {} } unless defined $schema && ref($schema) eq 'HASH';

    my %cleaned;

    # Handle anyOf / oneOf: extract primary variant and nullable status
    for my $union_key (qw(anyOf oneOf)) {
        if (exists $schema->{$union_key} && ref($schema->{$union_key}) eq 'ARRAY') {
            my $primary;
            for my $variant (@{ $schema->{$union_key} }) {
                if (ref($variant) eq 'HASH') {
                    if (defined $variant->{type} && $variant->{type} eq 'null') {
                        $cleaned{nullable} = \1;
                    } elsif (!defined $primary) {
                        $primary = $variant;
                    }
                }
            }
            $primary ||= $schema->{$union_key}[0];
            if (ref($primary) eq 'HASH') {
                my $clean_primary = _clean_gemini_schema($primary);
                for my $k (keys %$clean_primary) {
                    $cleaned{$k} = $clean_primary->{$k} unless exists $cleaned{$k};
                }
            }
        }
    }

    # Core allowed Gemini fields
    for my $k (qw(type format description nullable enum maxItems minItems required)) {
        if (exists $schema->{$k} && defined $schema->{$k}) {
            $cleaned{$k} = $schema->{$k};
        }
    }

    # Default type to object if properties exist and type is missing
    if (!exists $cleaned{type} && exists $schema->{properties}) {
        $cleaned{type} = 'object';
    }

    # Recursively clean properties
    if (exists $schema->{properties} && ref($schema->{properties}) eq 'HASH') {
        my %props;
        for my $prop_name (sort keys %{ $schema->{properties} }) {
            my $prop_schema = $schema->{properties}{$prop_name};
            $props{$prop_name} = _clean_gemini_schema($prop_schema);
        }
        $cleaned{properties} = \%props;
    }

    # Recursively clean items (for arrays)
    if (exists $schema->{items} && ref($schema->{items}) eq 'HASH') {
        $cleaned{items} = _clean_gemini_schema($schema->{items});
    }

    # Ensure required is an ARRAY
    if (exists $cleaned{required} && ref($cleaned{required}) ne 'ARRAY') {
        delete $cleaned{required};
    }

    return \%cleaned;
}

    my @function_declarations = map {
        +{ name => $_->{name}, description => $_->{description}, parameters => _clean_gemini_schema($_->{input_schema}) }
    } @$tools;

    return {
        contents          => \@contents,
        systemInstruction => { parts => [ { text => $system } ] },
        tools             => [ { functionDeclarations => \@function_declarations } ],
        generationConfig  => {
            maxOutputTokens => $max_tokens,
            thinkingConfig  => _gemini_thinking_config(),
        },
    };
}

# In Gemini 3.x, omitting thinkingLevel defaults to "HIGH" (think as deeply as possible),
# which can take dozens of seconds before the first character appears even for simple questions
# (verified on hardware). For interactive use on this low-powered iBook, we default to LOW
# for speed, and allow CLAUDE_GEMINI_THINKING=high to restore original behavior.
# Gemini 2.5 uses thinkingBudget (0..24576, -1 for dynamic) rather than thinkingLevel,
# so we branch on the model name.
sub _gemini_thinking_config {
    my $want_high = lc($ENV{CLAUDE_GEMINI_THINKING} || 'low') eq 'high';
    if (defined $MODEL && $MODEL =~ /^gemini-3/) {
        return { thinkingLevel => $want_high ? 'HIGH' : 'LOW' };
    }
    return { thinkingBudget => $want_high ? -1 : 0 };
}

# OpenAI compatible (chat/completions). Converts internal format (Anthropic content blocks)
# to OpenAI messages array. system is not a separate field but a leading role=system message.
# assistant tool_use becomes tool_calls[].function with arguments as a JSON string
# (OpenAI spec). tool_result becomes an independent role=tool message (linked by tool_call_id).
sub build_request_openai {
    my ($messages, $tools, $system, $max_tokens) = @_;
    $max_tokens = $MAX_TOKENS unless defined $max_tokens;

    my @out = ({ role => 'system', content => $system });
    for my $msg (@$messages) {
        if (!ref $msg->{content}) {
            push @out, { role => $msg->{role}, content => $msg->{content} };
            next;
        }
        if ($msg->{role} eq 'assistant') {
            my $text = '';
            my @tool_calls;
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'text') {
                    $text .= $block->{text};
                }
                elsif ($block->{type} eq 'tool_use') {
                    push @tool_calls, {
                        id       => $block->{id},
                        type     => 'function',
                        function => {
                            name      => $block->{name},
                            arguments => MiniJSON::encode($block->{input} || {}),
                        },
                    };
                }
            }
            my $m = { role => 'assistant', content => $text };
            $m->{tool_calls} = \@tool_calls if @tool_calls;
            push @out, $m;
        }
        else {
            # User-side blocks = run_tool results (tool_result).
            # In OpenAI, each becomes an independent role=tool message.
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'tool_result') {
                    push @out, {
                        role         => 'tool',
                        tool_call_id => $block->{tool_use_id},
                        content      => $block->{content},
                    };
                }
                elsif ($block->{type} eq 'text') {
                    push @out, { role => 'user', content => $block->{text} };
                }
            }
        }
    }

    my @tool_defs = map {
        +{ type => 'function', function => {
            name        => $_->{name},
            description => $_->{description},
            parameters  => $_->{input_schema},
        } }
    } @$tools;

    my $req = {
        model      => $MODEL,
        messages   => \@out,
        max_tokens => $max_tokens,
    };
    $req->{tools} = \@tool_defs if @tool_defs;
    return $req;
}

sub parse_response {
    my ($resp) = @_;
    return parse_response_gemini($resp)   if $PROVIDER eq 'gemini';
    return parse_response_openai($resp)   if $PROVIDER eq 'openai';
    return parse_response_anthropic($resp);
}

sub parse_response_openai {
    my ($resp) = @_;
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $msg = $resp->{choices} && $resp->{choices}[0] && $resp->{choices}[0]{message};
    die "API error: no choices in response: " . MiniJSON::encode($resp) . "\n" unless $msg;

    my @blocks;
    if (defined $msg->{reasoning_content} && $msg->{reasoning_content} ne '') {
        push @blocks, { type => 'thinking', text => $msg->{reasoning_content} };
    }
    elsif (defined $msg->{reasoning} && $msg->{reasoning} ne '') {
        push @blocks, { type => 'thinking', text => $msg->{reasoning} };
    }
    if (defined $msg->{content} && $msg->{content} ne '') {
        push @blocks, { type => 'text', text => $msg->{content} };
    }
    for my $tc (@{ $msg->{tool_calls} || [] }) {
        my $args = $tc->{function}{arguments};
        my $input = eval { MiniJSON::decode($args) } || {};
        push @blocks, {
            type  => 'tool_use',
            id    => $tc->{id} || ('call-' . scalar(@blocks)),
            name  => $tc->{function}{name},
            input => $input,
        };
    }
    return @blocks;
}

sub parse_response_anthropic {
    my ($resp) = @_;
    if ($resp->{type} && $resp->{type} eq 'error') {
        die "API error: " . MiniJSON::encode($resp) . "\n";
    }
    return @{ $resp->{content} || [] };
}

my $gemini_call_seq = 0;

sub parse_response_gemini {
    my ($resp) = @_;
    if ($resp->{error}) {
        die "API error: " . MiniJSON::encode($resp->{error}) . "\n";
    }
    my $candidate = $resp->{candidates} && $resp->{candidates}[0];
    my @blocks;
    for my $part (@{ ($candidate && $candidate->{content}{parts}) || [] }) {
        # When Gemini uses thinking, parts representing intermediate thought processes
        # are flagged with thought: true. We normalize them to thinking blocks
        # so live thinking visuals can report elapsed time without spewing raw drafts.
        if ($part->{thought}) {
            my $block = { type => 'thinking', text => (defined $part->{text} ? $part->{text} : '') };
            $block->{thought_signature} = $part->{thoughtSignature} if defined $part->{thoughtSignature};
            push @blocks, $block;
            next;
        }
        if (defined $part->{text}) {
            my $block = { type => 'text', text => $part->{text} };
            $block->{thought_signature} = $part->{thoughtSignature} if defined $part->{thoughtSignature};
            push @blocks, $block;
        }
        elsif ($part->{functionCall}) {
            $gemini_call_seq++;
            my $block = {
                type  => 'tool_use',
                # Gemini functionCall has no native id, so generate a substitute ID
                # to align with Anthropic format internal representation when sending tool_result
                id    => "gemini-call-$gemini_call_seq",
                name  => $part->{functionCall}{name},
                input => $part->{functionCall}{args} || {},
            };
            # Reattached as-is when returning functionCall in the next turn
            # (see corresponding elsif in build_request_gemini)
            $block->{thought_signature} = $part->{thoughtSignature} if defined $part->{thoughtSignature};
            push @blocks, $block;
        }
    }
    return @blocks;
}

sub has_thinking_block {
    my ($blocks) = @_;
    return 0 unless ref $blocks eq 'ARRAY';
    for my $b (@$blocks) {
        return 1 if ref $b eq 'HASH' && defined $b->{type} && $b->{type} eq 'thinking';
    }
    return 0;
}

# --- Provider model discovery & schema adapters ---
sub fetch_models {
    my ($provider) = @_;
    $provider = (defined $provider && $provider ne '') ? $provider : $PROVIDER;
    if (!defined $provider || $provider eq '') {
        return wantarray ? (undef, "No provider configured") : undef;
    }

    my ($models, $err);
    eval {
        if ($provider eq 'anthropic') {
            $models = _fetch_models_anthropic();
        }
        elsif ($provider eq 'gemini') {
            $models = _fetch_models_gemini();
        }
        elsif ($provider eq 'openai') {
            $models = _fetch_models_openai();
        }
        else {
            die "Unknown provider '$provider'\n";
        }
    };
    if ($@) {
        $err = $@;
        $err =~ s/ at \S+ line \d+.*//s;
        $err =~ s/^\s+|\s+$//g;
        return wantarray ? (undef, $err) : undef;
    }

    return wantarray ? ($models, undef) : $models;
}

sub _fetch_models_anthropic {
    my $key = ($PROVIDER && $PROVIDER eq 'anthropic' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : $ENV{ANTHROPIC_API_KEY};
    die "ANTHROPIC_API_KEY is not set.\n" unless defined $key && $key ne '';

    my $url = 'https://api.anthropic.com/v1/models?limit=100';
    my $ver = (defined $ANTHROPIC_VERSION && $ANTHROPIC_VERSION ne '')
        ? $ANTHROPIC_VERSION
        : '2023-06-01';
    my $headers = [ "x-api-key: $key", "anthropic-version: $ver" ];

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $data = $resp->{data};
    die "Invalid response from Anthropic: missing data array\n" unless ref $data eq 'ARRAY';

    my @models;
    for my $item (@$data) {
        next unless ref $item eq 'HASH' && defined $item->{id};
        my $display = (defined $item->{display_name} && $item->{display_name} ne '')
            ? $item->{display_name}
            : $item->{id};
        push @models, { id => $item->{id}, display => $display };
    }
    return \@models;
}

sub _fetch_models_gemini {
    my $key = ($PROVIDER && $PROVIDER eq 'gemini' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : $ENV{GEMINI_API_KEY};
    die "GEMINI_API_KEY is not set.\n" unless defined $key && $key ne '';

    my $url = 'https://generativelanguage.googleapis.com/v1beta/models?pageSize=100';
    my $headers = [ "x-goog-api-key: $key" ];

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $list = $resp->{models};
    die "Invalid response from Gemini: missing models array\n" unless ref $list eq 'ARRAY';

    my @models;
    for my $item (@$list) {
        next unless ref $item eq 'HASH' && defined $item->{name};
        my $methods = $item->{supportedGenerationMethods};
        my $can_generate = 0;
        if (ref $methods eq 'ARRAY') {
            for my $m (@$methods) {
                if (defined $m && $m eq 'generateContent') {
                    $can_generate = 1;
                    last;
                }
            }
        }
        next unless $can_generate;

        my $id = $item->{name};
        $id =~ s{^models/}{};
        my $display = (defined $item->{displayName} && $item->{displayName} ne '')
            ? $item->{displayName}
            : $id;
        push @models, { id => $id, display => $display };
    }
    return \@models;
}

sub _fetch_models_openai {
    my $base;
    if (defined $API_URL && $API_URL =~ m{^(.*)/chat/completions$}) {
        $base = $1;
    }
    if (!defined $base || $base eq '') {
        $base = $ENV{OPENAI_BASE_URL};
    }
    die "OPENAI_BASE_URL is not set.\n" unless defined $base && $base ne '';
    $base =~ s{/+$}{};

    my $key = ($PROVIDER && $PROVIDER eq 'openai' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : (defined $ENV{OPENAI_API_KEY} ? $ENV{OPENAI_API_KEY} : 'not-needed');

    my $url = "$base/models";
    my $headers = [];
    if (defined $key && $key ne '' && $key ne 'not-needed') {
        push @$headers, "authorization: Bearer $key";
    }

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $data = $resp->{data};
    die "Invalid response from OpenAI: missing data array\n" unless ref $data eq 'ARRAY';

    my @models;
    for my $item (@$data) {
        next unless ref $item eq 'HASH' && defined $item->{id};
        my $display = (defined $item->{display_name} && $item->{display_name} ne '')
            ? $item->{display_name}
            : (defined $item->{name} && $item->{name} ne '')
                ? $item->{name}
                : $item->{id};
        push @models, { id => $item->{id}, display => $display };
    }
    return \@models;
}

