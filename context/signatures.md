# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L38 | 6 |
| `format_context_size` | `format_context_size()` | L57 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L73 | 0 |
| `get_max_retries` | `get_max_retries()` | L89 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L97 | 4 |
| `init_retry_config` | `init_retry_config()` | L105 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L115 | 6 |
| `load_env_file` | `load_env_file()` | L125 | 2 |
| `cursor_hide` | `cursor_hide()` | L159 | 6 |
| `cursor_show` | `cursor_show()` | L164 | 10 |
| `configure_provider` | `configure_provider()` | L196 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L290 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L296 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L304 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L310 | 2 |
| `read_agents_file` | `read_agents_file()` | L317 | 2 |
| `get_agents_context` | `get_agents_context()` | L332 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L367 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L378 | 6 |
| `encode` | `encode()` | L403 | 22 |
| `encode_string` | `encode_string()` | L423 | 2 |
| `decode` | `decode()` | L434 | 14 |
| `_skip_ws` | `_skip_ws()` | L441 | 6 |
| `_decode_value` | `_decode_value()` | L446 | 6 |
| `_decode_object` | `_decode_object()` | L463 | 2 |
| `_decode_array` | `_decode_array()` | L485 | 2 |
| `_decode_string` | `_decode_string()` | L503 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L539 | 4 |
| `_has_request_body` | `_has_request_body()` | L543 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L549 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L563 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L591 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L603 | 2 |
| `_execute_curl` | `_execute_curl()` | L620 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L644 | 2 |
| `_call_api_once` | `_call_api_once()` | L662 | 2 |
| `call_api` | `call_api()` | L699 | 10 |
| `quote` | `quote()` | L722 | 2 |
| `build_headers` | `build_headers()` | L736 | 4 |
| `build_request` | `build_request()` | L750 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L759 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L790 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L851 | 2 |
| `build_request_openai` | `build_request_openai()` | L863 | 2 |
| `parse_response` | `parse_response()` | L930 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L937 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L969 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L979 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1020 | 2 |
| `fetch_models` | `fetch_models()` | L1030 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1062 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1094 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1137 | 2 |
| `_normalize_models` | `_normalize_models()` | L1186 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1203 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1227 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1285 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1326 | 2 |
| `get_current_model` | `get_current_model()` | L1451 | 2 |
| `get_current_provider` | `get_current_provider()` | L1455 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1459 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1463 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1467 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1473 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1477 | 2 |
| `generate_session_id` | `generate_session_id()` | L1487 | 4 |
| `init_session` | `init_session()` | L1494 | 4 |
| `get_current_session` | `get_current_session()` | L1507 | 2 |
| `archive_session` | `archive_session()` | L1512 | 2 |
| `handle_new_command` | `handle_new_command()` | L1521 | 2 |
| `show_help` | `show_help()` | L1533 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1549 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1574 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1582 | 2 |
| `handle_models_command` | `handle_models_command()` | L1590 | 2 |
| `confirm` | `confirm()` | L1698 | 4 |
| `confirm_tool` | `confirm_tool()` | L1705 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1714 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1737 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1824 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1860 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1898 | 4 |
| `run_tool` | `run_tool()` | L1935 | 4 |
| `run_subagent` | `run_subagent()` | L2050 | 2 |
| `_debug_log` | `_debug_log()` | L2173 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2195 | 2 |
| `_char_width` | `_char_width()` | L2206 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2219 | 4 |
| `_display_width` | `_display_width()` | L2226 | 0 |
| `_term_size` | `_term_size()` | L2238 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2257 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2313 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2380 | 2 |
| `_walk_position` | `_walk_position()` | L2421 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2441 | 8 |
| `extract_basename` | `extract_basename()` | L2795 | 2 |
| `truncate_text` | `truncate_text()` | L2806 | 4 |
| `_format_line_range` | `_format_line_range()` | L2821 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2836 | 4 |
| `format_tool_call` | `format_tool_call()` | L2901 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2910 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2920 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2925 | 4 |
| `format_retry_status` | `format_retry_status()` | L2929 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L2938 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L2947 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L2956 | 2 |
| `slow_print` | `slow_print()` | L2966 | 2 |
| `show_banner` | `show_banner()` | L2981 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L37 | 6 |
| `format_context_size` | `format_context_size()` | L56 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L72 | 0 |
| `get_max_retries` | `get_max_retries()` | L88 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L96 | 4 |
| `init_retry_config` | `init_retry_config()` | L104 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L114 | 6 |
| `load_env_file` | `load_env_file()` | L124 | 2 |
| `cursor_hide` | `cursor_hide()` | L158 | 6 |
| `cursor_show` | `cursor_show()` | L163 | 10 |
| `configure_provider` | `configure_provider()` | L195 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 22 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 14 |
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
| `_is_tty_active` | `_is_tty_active()` | L3 | 4 |
| `_has_request_body` | `_has_request_body()` | L7 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L13 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L27 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L55 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L67 | 2 |
| `_execute_curl` | `_execute_curl()` | L84 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L108 | 2 |
| `_call_api_once` | `_call_api_once()` | L126 | 2 |
| `call_api` | `call_api()` | L163 | 10 |
| `quote` | `quote()` | L186 | 2 |

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
| `format_retry_status` | `format_retry_status()` | L137 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L146 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L155 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L164 | 2 |
| `slow_print` | `slow_print()` | L174 | 2 |
| `show_banner` | `show_banner()` | L189 | 1 |
