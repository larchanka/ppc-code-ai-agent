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
| `cursor_hide` | `cursor_hide()` | L167 | 6 |
| `cursor_show` | `cursor_show()` | L172 | 10 |
| `configure_provider` | `configure_provider()` | L204 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L298 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L304 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L312 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L318 | 2 |
| `read_agents_file` | `read_agents_file()` | L325 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L338 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L347 | 4 |
| `get_agents_context` | `get_agents_context()` | L358 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L384 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L396 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L421 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L433 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L463 | 2 |
| `discover_skills` | `discover_skills()` | L484 | 2 |
| `get_skills_context` | `get_skills_context()` | L498 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L518 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L530 | 6 |
| `encode` | `encode()` | L563 | 22 |
| `encode_string` | `encode_string()` | L583 | 2 |
| `decode` | `decode()` | L594 | 16 |
| `_skip_ws` | `_skip_ws()` | L601 | 6 |
| `_decode_value` | `_decode_value()` | L606 | 6 |
| `_decode_object` | `_decode_object()` | L623 | 2 |
| `_decode_array` | `_decode_array()` | L645 | 2 |
| `_decode_string` | `_decode_string()` | L663 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L699 | 4 |
| `_has_request_body` | `_has_request_body()` | L703 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L709 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L723 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L751 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L763 | 2 |
| `_execute_curl` | `_execute_curl()` | L780 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L804 | 2 |
| `_call_api_once` | `_call_api_once()` | L822 | 2 |
| `call_api` | `call_api()` | L859 | 10 |
| `quote` | `quote()` | L882 | 2 |
| `build_headers` | `build_headers()` | L896 | 4 |
| `build_request` | `build_request()` | L910 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L919 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L950 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1011 | 2 |
| `build_request_openai` | `build_request_openai()` | L1023 | 2 |
| `parse_response` | `parse_response()` | L1090 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1097 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1129 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1139 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1180 | 2 |
| `fetch_models` | `fetch_models()` | L1190 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1222 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1254 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1297 | 2 |
| `_normalize_models` | `_normalize_models()` | L1346 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1363 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1387 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1445 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1486 | 2 |
| `get_current_model` | `get_current_model()` | L1611 | 2 |
| `get_current_provider` | `get_current_provider()` | L1615 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1619 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1623 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1627 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1633 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1637 | 2 |
| `generate_session_id` | `generate_session_id()` | L1647 | 4 |
| `init_session` | `init_session()` | L1654 | 4 |
| `get_current_session` | `get_current_session()` | L1667 | 2 |
| `archive_session` | `archive_session()` | L1672 | 2 |
| `handle_new_command` | `handle_new_command()` | L1681 | 2 |
| `show_help` | `show_help()` | L1693 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1709 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1734 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1742 | 2 |
| `handle_models_command` | `handle_models_command()` | L1750 | 2 |
| `confirm` | `confirm()` | L1858 | 4 |
| `confirm_tool` | `confirm_tool()` | L1865 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1874 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1897 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1984 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2020 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2058 | 4 |
| `run_tool` | `run_tool()` | L2095 | 4 |
| `run_subagent` | `run_subagent()` | L2210 | 2 |
| `_debug_log` | `_debug_log()` | L2333 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2355 | 2 |
| `_char_width` | `_char_width()` | L2366 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2379 | 6 |
| `_display_width` | `_display_width()` | L2386 | 0 |
| `_term_size` | `_term_size()` | L2398 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2417 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2473 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2540 | 2 |
| `_walk_position` | `_walk_position()` | L2581 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2601 | 8 |
| `_format_link_span` | `_format_link_span()` | L2955 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L2963 | 10 |
| `_visible_width` | `_visible_width()` | L2999 | 4 |
| `_split_table_row` | `_split_table_row()` | L3006 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L3014 | 2 |
| `_align_cell` | `_align_cell()` | L3033 | 2 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L3049 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L3065 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L3075 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L3092 | 2 |
| `_format_header_line` | `_format_header_line()` | L3116 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L3135 | 2 |
| `_format_list_line` | `_format_list_line()` | L3146 | 2 |
| `_format_block_line` | `_format_block_line()` | L3171 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L3200 | 2 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L3207 | 0 |
| `render_markdown` | `render_markdown()` | L3215 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L3255 | 0 |
| `extract_basename` | `extract_basename()` | L3291 | 2 |
| `truncate_text` | `truncate_text()` | L3302 | 4 |
| `_format_line_range` | `_format_line_range()` | L3317 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L3332 | 4 |
| `format_tool_call` | `format_tool_call()` | L3397 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L3406 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L3416 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L3421 | 4 |
| `format_retry_status` | `format_retry_status()` | L3425 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L3434 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L3443 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L3452 | 2 |
| `slow_print` | `slow_print()` | L3462 | 2 |
| `show_banner` | `show_banner()` | L3480 | 1 |

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
| `cursor_hide` | `cursor_hide()` | L166 | 6 |
| `cursor_show` | `cursor_show()` | L171 | 10 |
| `configure_provider` | `configure_provider()` | L203 | 2 |

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

## [`src/markdown.pl`](../src/markdown.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_format_link_span` | `_format_link_span()` | L3 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L11 | 10 |
| `_visible_width` | `_visible_width()` | L47 | 4 |
| `_split_table_row` | `_split_table_row()` | L54 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L62 | 2 |
| `_align_cell` | `_align_cell()` | L81 | 2 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L97 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L113 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L123 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L140 | 2 |
| `_format_header_line` | `_format_header_line()` | L164 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L183 | 2 |
| `_format_list_line` | `_format_list_line()` | L194 | 2 |
| `_format_block_line` | `_format_block_line()` | L219 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L248 | 2 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L255 | 0 |
| `render_markdown` | `render_markdown()` | L263 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L303 | 0 |

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
| `_display_width_chars` | `_display_width_chars()` | L58 | 6 |
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
| `show_banner` | `show_banner()` | L192 | 1 |
