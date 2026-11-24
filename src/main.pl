# --- Main entrypoint & Conversation loop ---
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

    if ($input =~ m{^/mcp(?:\s+(.*))?$}) {
        handle_mcp_command($1);
        next;
    }

    if ($input eq '/claude' || $input eq '/gemini' || $input eq '/openai') {
        my $target = $input eq '/claude' ? 'anthropic'
                   : $input eq '/gemini' ? 'gemini'
                   :                       'openai';
        if ($target eq $PROVIDER) {
            print "\nAlready on [$PROVIDER / $MODEL].\n";
        }
        elsif ($target eq 'openai' && !$ENV{OPENAI_BASE_URL}) {
            # OpenAI requires a base URL rather than just an API key.
            # More reliable to set environment variables and restart.
            print "\nSwitching to an OpenAI-compatible server needs OPENAI_BASE_URL set.\n";
            print "e.g. export OPENAI_BASE_URL=http://192.168.1.50:8080/v1\n";
            print "(also OPENAI_API_KEY and CLAUDE_MODEL if needed)\n";
            print "Set it and restart. Staying on [$PROVIDER / $MODEL] for now.\n";
        }
        else {
            eval { configure_provider($target) };
            if ($@ && $target eq 'openai') {
                print "\nCould not switch: $@";
            }
            elsif ($@) {
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
