# --- Main entrypoint & Conversation loop ---

sub handle_openai_switch {
    if ($PROVIDER && $PROVIDER eq 'openai') {
        print "\nAlready on [$PROVIDER / $MODEL].\n";
        return 1;
    }

    my $base_url = $ENV{OPENAI_BASE_URL};
    my $is_interactive = 0;

    if (!defined $base_url || $base_url eq '') {
        $is_interactive = 1;
        print "\nEnter OpenAI / local LLM base URL (e.g. http://192.168.1.50:8080/v1 or http://localhost:11434/v1) [Esc or Ctrl+C to cancel]:\n";
        my $raw_url = read_line_or_cancel("> ");
        if (!defined $raw_url) {
            print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
            return 0;
        }
        $raw_url =~ s/^\s+|\s+$//g;
        if ($raw_url eq '') {
            print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
            return 0;
        }
        $base_url = normalize_openai_endpoint($raw_url);
    }

    my $custom_model;
    my $custom_key;

    if ($is_interactive) {
        my $default_model = $ENV{CLAUDE_MODEL} || 'local-model';
        print "Enter model name [default: $default_model] (Esc or Ctrl+C to cancel):\n";
        my $m_input = read_line_or_cancel("> ");
        if (!defined $m_input) {
            print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
            return 0;
        }
        $m_input =~ s/^\s+|\s+$//g;
        $custom_model = length($m_input) ? $m_input : $default_model;

        my $default_key = $ENV{OPENAI_API_KEY} || 'not-needed';
        print "Enter API key [default: $default_key] (Esc or Ctrl+C to cancel):\n";
        my $k_input = read_line_or_cancel("> ");
        if (!defined $k_input) {
            print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
            return 0;
        }
        $k_input =~ s/^\s+|\s+$//g;
        $custom_key = length($k_input) ? $k_input : $default_key;

        $ENV{OPENAI_BASE_URL} = $base_url;
        $ENV{CLAUDE_MODEL}    = $custom_model;
        $ENV{OPENAI_API_KEY}  = $custom_key;
    }

    eval { configure_provider('openai') };
    if ($@) {
        print "\nCould not switch: $@";
        return 0;
    }

    print "\nSwitched to [$PROVIDER / $MODEL]. The conversation so far carries over.\n";

    if ($is_interactive) {
        my $target_file = get_env_file_path();
        if (confirm("Save this configuration to $target_file so you don't need to enter it again?")) {
            my %to_save = ( OPENAI_BASE_URL => $base_url );
            $to_save{CLAUDE_MODEL}   = $custom_model if defined $custom_model && $custom_model ne '';
            $to_save{OPENAI_API_KEY} = $custom_key   if defined $custom_key && $custom_key ne '' && $custom_key ne 'not-needed';
            if (save_env_vars(\%to_save, $target_file)) {
                print "Saved.\n";
            }
            else {
                print "Could not save (cannot write $target_file).\n";
            }
        }
    }

    return 1;
}

unless (caller) {
    load_env_file();

    # Determine provider: if not explicitly specified, use Anthropic if key exists,
    # otherwise Gemini (free tier; new users are guided here).
    my $_want_provider = $ENV{CLAUDE_PROVIDER};
    if (!defined $_want_provider || $_want_provider eq '') {
        $_want_provider = $ENV{ANTHROPIC_API_KEY} ? 'anthropic' : 'gemini';
    }
    unless (eval { configure_provider($_want_provider); 1 }) {
        my $err = $@ || "Configuration error\n";
        # Only when launched without a Gemini key, guide user through obtaining one with steps.
        # Otherwise (Anthropic key unset, unknown provider, etc.), die as usual.
        if ($_want_provider eq 'gemini' && !$ENV{GEMINI_API_KEY}) {
            my $key = gemini_key_setup();
            unless (defined $key && $key ne '') {
                print "\nNo API key was set, so exiting.\n";
                exit 1;
            }
            $ENV{GEMINI_API_KEY} = $key;
            configure_provider('gemini');
        }
        else {
            die $err;
        }
    }

get_current_session();

mcp_init_all();

show_banner();

while (1) {
    my $input = read_line_interactive("\nUser> ${COLOR_RESET}", 1, $COLOR_USER);
    last unless defined $input;
    $input = decode('UTF-8', $input, FB_DEFAULT);
    next if $input eq '';
    last if $input eq 'exit';

    if ($input eq '/help') {
        show_help();
        next;
    }

    if ($input eq '/new') {
        handle_new_command();
        next;
    }

    if ($input eq '/models') {
        handle_models_command();
        next;
    }

    if ($input eq '/auto') {
        handle_auto_command();
        next;
    }

    if ($input eq '/manual') {
        handle_manual_command();
        next;
    }

    if ($input =~ m{^/(?:ctx|context)(?:\s+(.*))?$}) {
        handle_ctx_command($1);
        next;
    }

    if ($input =~ m{^/compact(?:\s+(.*))?$}) {
        handle_compact_command();
        next;
    }

    if ($input =~ m{^/mcp(?:\s+(.*))?$}) {
        handle_mcp_command($1);
        next;
    }

    if ($input eq '/openai' || $input eq '/local') {
        handle_openai_switch();
        next;
    }

    if ($input eq '/claude' || $input eq '/gemini') {
        my $target = $input eq '/claude' ? 'anthropic' : 'gemini';
        if ($target eq $PROVIDER) {
            print "\nAlready on [$PROVIDER / $MODEL].\n";
        }
        else {
            eval { configure_provider($target) };
            if ($@) {
                # If key is missing, prompt interactively.
                # Cancel with Esc or Ctrl+C to stay on current provider.
                my $key_name = $target eq 'gemini' ? 'GEMINI_API_KEY' : 'ANTHROPIC_API_KEY';
                my $key = read_secret_or_cancel(
                    "\n$key_name is not set yet. Please enter it (Esc or Ctrl+C to cancel)\n> "
                );
                if (!defined $key || $key eq '') {
                    print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
                }
                else {
                    $ENV{$key_name} = $key;
                    eval { configure_provider($target) };
                    if ($@) {
                        print "\nStill could not switch: $@";
                    }
                    else {
                        print "\nSwitched to [$PROVIDER / $MODEL]. The conversation so far carries over.\n";
                        my $target_file = get_env_file_path();
                        if (confirm("Save this key to $target_file so you don't need to enter it again?")) {
                            if (open(my $ef, '>>', $target_file)) {
                                print $ef "export $key_name=$key\n";
                                close $ef;
                                chmod 0600, $target_file;
                                print "Saved.\n";
                            }
                            else {
                                print "Could not save (cannot write $target_file).\n";
                            }
                        }
                    }
                }
            }
            else {
                print "\nSwitched to [$PROVIDER / $MODEL]. The conversation so far carries over.\n";
            }
        }
        next;
    }

    my $session = get_current_session();
    push @{$session->{messages}}, { role => 'user', content => $input };

    while (1) {
        auto_compact_session_if_needed($session);
        my $body = build_request($session->{messages}, \@TOOLS, get_effective_system_prompt());
        my $resp = eval { call_api($API_URL, build_headers(), MiniJSON::encode($body)) };
        if ($@) {
            print clear_thinking_line() if -t STDOUT;
            cursor_show();
            print $@;
            last;
        }

        my @content_blocks = eval { parse_response($resp) };
        if ($@) {
            print clear_thinking_line() if -t STDOUT;
            cursor_show();
            print $@;
            last;
        }

        if (-t STDOUT) {
            if (has_thinking_block(\@content_blocks)) {
                print finalize_thinking_line($LAST_API_ELAPSED);
            }
            else {
                print clear_thinking_line();
            }
        }

        push @{$session->{messages}}, { role => 'assistant', content => \@content_blocks };

        my @tool_results;
        my $printed_code_ai_prompt = 0;
        for my $block (@content_blocks) {
            if ($block->{type} eq 'text') {
                print "\n${COLOR_MODEL}Code AI>${COLOR_RESET} " unless $printed_code_ai_prompt;
                $printed_code_ai_prompt = 1;
                my $rendered = render_markdown($block->{text});
                slow_print("$rendered\n");
                print $COLOR_RESET;
            }
            elsif ($block->{type} eq 'tool_use') {
                $printed_code_ai_prompt = 0;
                print "\n" . format_tool_call($block->{name}, $block->{input}) . "\n";
                my $result = run_tool($block->{name}, $block->{input});
                push @tool_results, {
                    type => 'tool_result',
                    tool_use_id => $block->{id},
                    name => $block->{name},
                    content => format_tool_result($block->{name}, $result),
                };
            }
        }

        if (@tool_results) {
            push @{$session->{messages}}, { role => 'user', content => \@tool_results };
            next;
        }

        last;
    }
}

print "\nGoodbye.\n";
cursor_show();

}

1;
