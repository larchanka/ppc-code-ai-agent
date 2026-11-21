# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L38 | 6 |
| `format_context_size` | `format_context_size()` | L57 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L73 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L88 | 6 |
| `load_env_file` | `load_env_file()` | L98 | 2 |
| `cursor_hide` | `cursor_hide()` | L131 | 6 |
| `cursor_show` | `cursor_show()` | L136 | 10 |
| `configure_provider` | `configure_provider()` | L168 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L262 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L268 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L276 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L282 | 2 |
| `read_agents_file` | `read_agents_file()` | L289 | 2 |
| `get_agents_context` | `get_agents_context()` | L304 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L339 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L350 | 6 |
| `encode` | `encode()` | L375 | 20 |
| `encode_string` | `encode_string()` | L395 | 2 |
| `decode` | `decode()` | L406 | 12 |
| `_skip_ws` | `_skip_ws()` | L413 | 6 |
| `_decode_value` | `_decode_value()` | L418 | 6 |
| `_decode_object` | `_decode_object()` | L435 | 2 |
| `_decode_array` | `_decode_array()` | L457 | 2 |
| `_decode_string` | `_decode_string()` | L475 | 4 |
| `call_api` | `call_api()` | L511 | 10 |
| `quote` | `quote()` | L637 | 2 |
| `build_headers` | `build_headers()` | L651 | 4 |
| `build_request` | `build_request()` | L665 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L674 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L705 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L766 | 2 |
| `build_request_openai` | `build_request_openai()` | L778 | 2 |
| `parse_response` | `parse_response()` | L845 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L852 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L884 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L894 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L935 | 2 |
| `fetch_models` | `fetch_models()` | L945 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L977 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1009 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1052 | 2 |
| `_normalize_models` | `_normalize_models()` | L1101 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1118 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1142 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1200 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1241 | 2 |
| `get_current_model` | `get_current_model()` | L1366 | 2 |
| `get_current_provider` | `get_current_provider()` | L1370 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1374 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1378 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1382 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1388 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1392 | 2 |
| `generate_session_id` | `generate_session_id()` | L1402 | 4 |
| `init_session` | `init_session()` | L1409 | 4 |
| `get_current_session` | `get_current_session()` | L1422 | 2 |
| `archive_session` | `archive_session()` | L1427 | 2 |
| `handle_new_command` | `handle_new_command()` | L1436 | 2 |
| `show_help` | `show_help()` | L1448 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1464 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1489 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1497 | 2 |
| `handle_models_command` | `handle_models_command()` | L1505 | 2 |
| `confirm` | `confirm()` | L1613 | 4 |
| `confirm_tool` | `confirm_tool()` | L1620 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1629 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1652 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1739 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1775 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1813 | 4 |
| `run_tool` | `run_tool()` | L1850 | 4 |
| `run_subagent` | `run_subagent()` | L1965 | 2 |
| `_debug_log` | `_debug_log()` | L2088 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2110 | 2 |
| `_char_width` | `_char_width()` | L2121 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2134 | 4 |
| `_display_width` | `_display_width()` | L2141 | 0 |
| `_term_size` | `_term_size()` | L2153 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2172 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2228 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2295 | 2 |
| `_walk_position` | `_walk_position()` | L2336 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2356 | 8 |
| `extract_basename` | `extract_basename()` | L2710 | 2 |
| `truncate_text` | `truncate_text()` | L2721 | 4 |
| `_format_line_range` | `_format_line_range()` | L2736 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2751 | 4 |
| `format_tool_call` | `format_tool_call()` | L2816 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2825 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2835 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2840 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L2844 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L2853 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L2862 | 2 |
| `slow_print` | `slow_print()` | L2872 | 2 |
| `show_banner` | `show_banner()` | L2887 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L37 | 6 |
| `format_context_size` | `format_context_size()` | L56 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L72 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L87 | 6 |
| `load_env_file` | `load_env_file()` | L97 | 2 |
| `cursor_hide` | `cursor_hide()` | L130 | 6 |
| `cursor_show` | `cursor_show()` | L135 | 10 |
| `configure_provider` | `configure_provider()` | L167 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 20 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 12 |
| `_skip_ws` | `_skip_ws()` | L42 | 6 |
| `_decode_value` | `_decode_value()` | L47 | 6 |
| `_decode_object` | `_decode_object()` | L64 | 2 |
| `_decode_array` | `_decode_array()` | L86 | 2 |
| `_decode_string` | `_decode_string()` | L104 | 4 |

## [`src/models_menu.pl`](../src/models_menu.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_normalize_models` | `_normalize_models()` | L4 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L21 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L45 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L103 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L144 | 2 |

## [`src/prompts.pl`](../src/prompts.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L58 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L64 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L72 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L78 | 2 |
| `read_agents_file` | `read_agents_file()` | L85 | 2 |
| `get_agents_context` | `get_agents_context()` | L100 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L135 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L146 | 6 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 4 |
| `build_request` | `build_request()` | L21 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L30 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L61 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L122 | 2 |
| `build_request_openai` | `build_request_openai()` | L134 | 2 |
| `parse_response` | `parse_response()` | L201 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L208 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L240 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L250 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L291 | 2 |
| `fetch_models` | `fetch_models()` | L301 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L333 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L365 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L408 | 2 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 2 |
| `get_current_provider` | `get_current_provider()` | L6 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L24 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L28 | 2 |
| `generate_session_id` | `generate_session_id()` | L38 | 4 |
| `init_session` | `init_session()` | L45 | 4 |
| `get_current_session` | `get_current_session()` | L58 | 2 |
| `archive_session` | `archive_session()` | L63 | 2 |
| `handle_new_command` | `handle_new_command()` | L72 | 2 |
| `show_help` | `show_help()` | L84 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L100 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L125 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L133 | 2 |
| `handle_models_command` | `handle_models_command()` | L141 | 2 |

## [`src/terminal.pl`](../src/terminal.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_debug_log` | `_debug_log()` | L12 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L34 | 2 |
| `_char_width` | `_char_width()` | L45 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L58 | 4 |
| `_display_width` | `_display_width()` | L65 | 0 |
| `_term_size` | `_term_size()` | L77 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L96 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L152 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L219 | 2 |
| `_walk_position` | `_walk_position()` | L260 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L280 | 8 |

## [`src/tools.pl`](../src/tools.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `confirm` | `confirm()` | L80 | 4 |
| `confirm_tool` | `confirm_tool()` | L87 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L96 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L119 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L206 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L242 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L280 | 4 |
| `run_tool` | `run_tool()` | L317 | 4 |
| `run_subagent` | `run_subagent()` | L432 | 2 |

## [`src/transport.pl`](../src/transport.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `call_api` | `call_api()` | L3 | 10 |
| `quote` | `quote()` | L129 | 2 |

## [`src/ui.pl`](../src/ui.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `extract_basename` | `extract_basename()` | L3 | 2 |
| `truncate_text` | `truncate_text()` | L14 | 4 |
| `_format_line_range` | `_format_line_range()` | L29 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L44 | 4 |
| `format_tool_call` | `format_tool_call()` | L109 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L118 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L128 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L133 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L137 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L146 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L155 | 2 |
| `slow_print` | `slow_print()` | L165 | 2 |
| `show_banner` | `show_banner()` | L180 | 1 |
