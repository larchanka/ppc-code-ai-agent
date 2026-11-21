# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L41 | 6 |
| `load_env_file` | `load_env_file()` | L51 | 2 |
| `cursor_hide` | `cursor_hide()` | L83 | 6 |
| `cursor_show` | `cursor_show()` | L88 | 10 |
| `configure_provider` | `configure_provider()` | L120 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L239 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L245 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L253 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L259 | 2 |
| `read_agents_file` | `read_agents_file()` | L266 | 2 |
| `get_agents_context` | `get_agents_context()` | L281 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L316 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L327 | 6 |
| `encode` | `encode()` | L352 | 20 |
| `encode_string` | `encode_string()` | L372 | 2 |
| `decode` | `decode()` | L383 | 12 |
| `_skip_ws` | `_skip_ws()` | L390 | 6 |
| `_decode_value` | `_decode_value()` | L395 | 6 |
| `_decode_object` | `_decode_object()` | L412 | 2 |
| `_decode_array` | `_decode_array()` | L434 | 2 |
| `_decode_string` | `_decode_string()` | L452 | 4 |
| `call_api` | `call_api()` | L488 | 10 |
| `quote` | `quote()` | L614 | 2 |
| `build_headers` | `build_headers()` | L628 | 4 |
| `build_request` | `build_request()` | L642 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L650 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L680 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L740 | 2 |
| `build_request_openai` | `build_request_openai()` | L752 | 2 |
| `parse_response` | `parse_response()` | L818 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L825 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L857 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L867 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L908 | 2 |
| `fetch_models` | `fetch_models()` | L918 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L950 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L982 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1025 | 2 |
| `_normalize_models` | `_normalize_models()` | L1074 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1091 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1115 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1173 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1214 | 2 |
| `get_current_model` | `get_current_model()` | L1339 | 2 |
| `get_current_provider` | `get_current_provider()` | L1343 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1347 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1351 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1355 | 4 |
| `generate_session_id` | `generate_session_id()` | L1361 | 4 |
| `init_session` | `init_session()` | L1368 | 4 |
| `get_current_session` | `get_current_session()` | L1381 | 2 |
| `archive_session` | `archive_session()` | L1386 | 2 |
| `handle_new_command` | `handle_new_command()` | L1395 | 2 |
| `show_help` | `show_help()` | L1407 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1422 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1430 | 2 |
| `handle_models_command` | `handle_models_command()` | L1438 | 2 |
| `confirm` | `confirm()` | L1546 | 4 |
| `confirm_tool` | `confirm_tool()` | L1553 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1562 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1585 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1672 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1708 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1746 | 4 |
| `run_tool` | `run_tool()` | L1783 | 4 |
| `run_subagent` | `run_subagent()` | L1898 | 2 |
| `_debug_log` | `_debug_log()` | L2021 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2043 | 2 |
| `_char_width` | `_char_width()` | L2054 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2067 | 4 |
| `_display_width` | `_display_width()` | L2074 | 0 |
| `_term_size` | `_term_size()` | L2086 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2105 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2161 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2228 | 2 |
| `_walk_position` | `_walk_position()` | L2269 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2289 | 8 |
| `extract_basename` | `extract_basename()` | L2643 | 2 |
| `truncate_text` | `truncate_text()` | L2654 | 4 |
| `_format_line_range` | `_format_line_range()` | L2669 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2684 | 4 |
| `format_tool_call` | `format_tool_call()` | L2749 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2758 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2768 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2773 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L2777 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L2786 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L2795 | 2 |
| `slow_print` | `slow_print()` | L2805 | 2 |
| `show_banner` | `show_banner()` | L2820 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L40 | 6 |
| `load_env_file` | `load_env_file()` | L50 | 2 |
| `cursor_hide` | `cursor_hide()` | L82 | 6 |
| `cursor_show` | `cursor_show()` | L87 | 10 |
| `configure_provider` | `configure_provider()` | L119 | 2 |

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
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L83 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L89 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L97 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L103 | 2 |
| `read_agents_file` | `read_agents_file()` | L110 | 2 |
| `get_agents_context` | `get_agents_context()` | L125 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L160 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L171 | 6 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 4 |
| `build_request` | `build_request()` | L21 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L29 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L59 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L119 | 2 |
| `build_request_openai` | `build_request_openai()` | L131 | 2 |
| `parse_response` | `parse_response()` | L197 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L204 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L236 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L246 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L287 | 2 |
| `fetch_models` | `fetch_models()` | L297 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L329 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L361 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L404 | 2 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 2 |
| `get_current_provider` | `get_current_provider()` | L6 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 4 |
| `generate_session_id` | `generate_session_id()` | L24 | 4 |
| `init_session` | `init_session()` | L31 | 4 |
| `get_current_session` | `get_current_session()` | L44 | 2 |
| `archive_session` | `archive_session()` | L49 | 2 |
| `handle_new_command` | `handle_new_command()` | L58 | 2 |
| `show_help` | `show_help()` | L70 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L85 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L93 | 2 |
| `handle_models_command` | `handle_models_command()` | L101 | 2 |

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
