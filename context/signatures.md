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
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L330 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L339 | 4 |
| `get_agents_context` | `get_agents_context()` | L350 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L376 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L388 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L413 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L425 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L455 | 2 |
| `discover_skills` | `discover_skills()` | L476 | 2 |
| `get_skills_context` | `get_skills_context()` | L490 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L510 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L522 | 6 |
| `encode` | `encode()` | L555 | 22 |
| `encode_string` | `encode_string()` | L575 | 2 |
| `decode` | `decode()` | L586 | 16 |
| `_skip_ws` | `_skip_ws()` | L593 | 6 |
| `_decode_value` | `_decode_value()` | L598 | 6 |
| `_decode_object` | `_decode_object()` | L615 | 2 |
| `_decode_array` | `_decode_array()` | L637 | 2 |
| `_decode_string` | `_decode_string()` | L655 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L691 | 4 |
| `_has_request_body` | `_has_request_body()` | L695 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L701 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L715 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L743 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L755 | 2 |
| `_execute_curl` | `_execute_curl()` | L772 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L796 | 2 |
| `_call_api_once` | `_call_api_once()` | L814 | 2 |
| `call_api` | `call_api()` | L851 | 10 |
| `quote` | `quote()` | L874 | 2 |
| `build_headers` | `build_headers()` | L888 | 4 |
| `build_request` | `build_request()` | L902 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L911 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L942 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1003 | 2 |
| `build_request_openai` | `build_request_openai()` | L1015 | 2 |
| `parse_response` | `parse_response()` | L1082 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1089 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1121 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1131 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1172 | 2 |
| `fetch_models` | `fetch_models()` | L1182 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1214 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1246 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1289 | 2 |
| `_normalize_models` | `_normalize_models()` | L1338 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1355 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1379 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1437 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1478 | 2 |
| `get_current_model` | `get_current_model()` | L1603 | 2 |
| `get_current_provider` | `get_current_provider()` | L1607 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1611 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1615 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1619 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1625 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1629 | 2 |
| `generate_session_id` | `generate_session_id()` | L1639 | 4 |
| `init_session` | `init_session()` | L1646 | 4 |
| `get_current_session` | `get_current_session()` | L1659 | 2 |
| `archive_session` | `archive_session()` | L1664 | 2 |
| `handle_new_command` | `handle_new_command()` | L1673 | 2 |
| `show_help` | `show_help()` | L1685 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1701 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1726 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1734 | 2 |
| `handle_models_command` | `handle_models_command()` | L1742 | 2 |
| `confirm` | `confirm()` | L1850 | 4 |
| `confirm_tool` | `confirm_tool()` | L1857 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1866 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1889 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1976 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2012 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2050 | 4 |
| `run_tool` | `run_tool()` | L2087 | 4 |
| `run_subagent` | `run_subagent()` | L2202 | 2 |
| `_debug_log` | `_debug_log()` | L2325 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2347 | 2 |
| `_char_width` | `_char_width()` | L2358 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2371 | 4 |
| `_display_width` | `_display_width()` | L2378 | 0 |
| `_term_size` | `_term_size()` | L2390 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2409 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2465 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2532 | 2 |
| `_walk_position` | `_walk_position()` | L2573 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2593 | 8 |
| `extract_basename` | `extract_basename()` | L2947 | 2 |
| `truncate_text` | `truncate_text()` | L2958 | 4 |
| `_format_line_range` | `_format_line_range()` | L2973 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2988 | 4 |
| `format_tool_call` | `format_tool_call()` | L3053 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L3062 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L3072 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L3077 | 4 |
| `format_retry_status` | `format_retry_status()` | L3081 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L3090 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L3099 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L3108 | 2 |
| `slow_print` | `slow_print()` | L3118 | 2 |
| `show_banner` | `show_banner()` | L3133 | 1 |

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
| `decode` | `decode()` | L35 | 16 |
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
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L98 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L107 | 4 |
| `get_agents_context` | `get_agents_context()` | L118 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L144 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L156 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L181 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L193 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L223 | 2 |
| `discover_skills` | `discover_skills()` | L244 | 2 |
| `get_skills_context` | `get_skills_context()` | L258 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L278 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L290 | 6 |

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
