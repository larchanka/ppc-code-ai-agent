# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L40 | 6 |
| `format_context_size` | `format_context_size()` | L59 | 4 |
| `init_max_tokens` | `init_max_tokens()` | L75 | 2 |
| `get_max_retries` | `get_max_retries()` | L91 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L99 | 4 |
| `init_retry_config` | `init_retry_config()` | L117 | 2 |
| `get_env_file_path` | `get_env_file_path()` | L126 | 8 |
| `load_env_file` | `load_env_file()` | L133 | 2 |
| `normalize_openai_endpoint` | `normalize_openai_endpoint()` | L157 | 2 |
| `save_env_vars` | `save_env_vars()` | L171 | 2 |
| `cursor_hide` | `cursor_hide()` | L239 | 6 |
| `cursor_show` | `cursor_show()` | L244 | 10 |
| `configure_provider` | `configure_provider()` | L279 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L394 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L400 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L408 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L414 | 2 |
| `read_agents_file` | `read_agents_file()` | L421 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L434 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L443 | 4 |
| `get_agents_context` | `get_agents_context()` | L454 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L480 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L492 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L517 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L529 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L559 | 2 |
| `discover_skills` | `discover_skills()` | L580 | 2 |
| `get_skills_context` | `get_skills_context()` | L594 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L614 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L626 | 6 |
| `encode` | `encode()` | L662 | 34 |
| `encode_string` | `encode_string()` | L691 | 2 |
| `decode` | `decode()` | L703 | 26 |
| `_skip_ws` | `_skip_ws()` | L711 | 6 |
| `_decode_value` | `_decode_value()` | L717 | 6 |
| `_decode_object` | `_decode_object()` | L753 | 2 |
| `_decode_array` | `_decode_array()` | L778 | 2 |
| `_decode_string` | `_decode_string()` | L799 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L879 | 6 |
| `_has_request_body` | `_has_request_body()` | L883 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L889 | 4 |
| `_create_secure_tempfile` | `_create_secure_tempfile()` | L905 | 2 |
| `_write_curl_config` | `_write_curl_config()` | L922 | 2 |
| `_build_curl_cmd` | `_build_curl_cmd()` | L951 | 4 |
| `_run_curl_sync` | `_run_curl_sync()` | L956 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L963 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L975 | 2 |
| `_execute_curl` | `_execute_curl()` | L992 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L1023 | 2 |
| `_is_retryable_error` | `_is_retryable_error()` | L1044 | 2 |
| `_call_api_once` | `_call_api_once()` | L1054 | 2 |
| `call_api` | `call_api()` | L1099 | 10 |
| `quote` | `quote()` | L1124 | 2 |
| `build_headers` | `build_headers()` | L1138 | 4 |
| `build_request` | `build_request()` | L1152 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L1161 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L1192 | 2 |
| `_clean_gemini_schema` | `_clean_gemini_schema()` | L1235 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1320 | 2 |
| `build_request_openai` | `build_request_openai()` | L1332 | 2 |
| `_merge_consecutive_blocks` | `_merge_consecutive_blocks()` | L1399 | 2 |
| `parse_response` | `parse_response()` | L1420 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1435 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1467 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1477 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1532 | 2 |
| `_to_int` | `_to_int()` | L1543 | 2 |
| `_make_token_usage` | `_make_token_usage()` | L1548 | 2 |
| `extract_token_usage` | `extract_token_usage()` | L1560 | 2 |
| `record_api_response_stats` | `record_api_response_stats()` | L1586 | 4 |
| `fetch_models` | `fetch_models()` | L1608 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1640 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1672 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1715 | 2 |
| `_normalize_models` | `_normalize_models()` | L1764 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1781 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1805 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1863 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1904 | 2 |
| `get_current_model` | `get_current_model()` | L2029 | 4 |
| `get_current_provider` | `get_current_provider()` | L2033 | 6 |
| `get_current_api_url` | `get_current_api_url()` | L2037 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L2041 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L2045 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L2051 | 4 |
| `set_max_tokens` | `set_max_tokens()` | L2055 | 2 |
| `generate_session_id` | `generate_session_id()` | L2065 | 4 |
| `init_session` | `init_session()` | L2072 | 4 |
| `get_session_stats` | `get_session_stats()` | L2097 | 8 |
| `record_session_tokens` | `record_session_tokens()` | L2119 | 2 |
| `record_session_tool_call` | `record_session_tool_call()` | L2142 | 2 |
| `record_session_subagent` | `record_session_subagent()` | L2160 | 2 |
| `get_current_session` | `get_current_session()` | L2178 | 6 |
| `archive_session` | `archive_session()` | L2183 | 2 |
| `handle_new_command` | `handle_new_command()` | L2192 | 2 |
| `show_help` | `show_help()` | L2204 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L2223 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L2248 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L2256 | 2 |
| `handle_models_command` | `handle_models_command()` | L2264 | 2 |
| `compact_tool_result_content` | `compact_tool_result_content()` | L2290 | 2 |
| `estimate_session_chars` | `estimate_session_chars()` | L2344 | 4 |
| `_find_user_turn_indices` | `_find_user_turn_indices()` | L2370 | 4 |
| `count_user_turns` | `count_user_turns()` | L2396 | 2 |
| `compact_session_history` | `compact_session_history()` | L2404 | 4 |
| `auto_compact_session_if_needed` | `auto_compact_session_if_needed()` | L2457 | 2 |
| `handle_compact_command` | `handle_compact_command()` | L2479 | 2 |
| `_commify` | `_commify()` | L2496 | 2 |
| `format_uptime` | `format_uptime()` | L2504 | 2 |
| `get_context_window_size` | `get_context_window_size()` | L2522 | 2 |
| `format_session_stats` | `format_session_stats()` | L2540 | 2 |
| `handle_stats_command` | `handle_stats_command()` | L2626 | 2 |
| `confirm` | `confirm()` | L2721 | 4 |
| `confirm_tool` | `confirm_tool()` | L2728 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L2737 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L2760 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L2847 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2883 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2927 | 4 |
| `read_line_or_cancel` | `read_line_or_cancel()` | L2934 | 2 |
| `_read_prompt_or_cancel` | `_read_prompt_or_cancel()` | L2939 | 4 |
| `format_tool_result` | `format_tool_result()` | L2993 | 4 |
| `run_tool` | `run_tool()` | L3003 | 4 |
| `run_subagent` | `run_subagent()` | L3207 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L3341 | 4 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L3361 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L3386 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L3430 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L3447 | 2 |
| `save_mcp_config` | `save_mcp_config()` | L3500 | 4 |
| `mcp_build_request` | `mcp_build_request()` | L3550 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L3565 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L3578 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L3596 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L3601 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L3608 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L3617 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L3634 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L3673 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L3698 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L3724 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L3732 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L3740 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L3747 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L3770 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L3794 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L3813 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L3884 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L4040 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L4069 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L4082 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L4116 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L4189 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L4216 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L4253 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L4295 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L4307 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L4318 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L4347 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L4404 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L4427 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L4448 | 2 |
| `_has_hires_time` | `_has_hires_time()` | L4488 | 2 |
| `_hires_time` | `_hires_time()` | L4489 | 6 |
| `_debug_log` | `_debug_log()` | L4497 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L4519 | 2 |
| `_char_width` | `_char_width()` | L4530 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L4543 | 6 |
| `_display_width` | `_display_width()` | L4550 | 0 |
| `_term_size` | `_term_size()` | L4562 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L4581 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L4638 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L4706 | 2 |
| `_walk_position` | `_walk_position()` | L4747 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L4767 | 8 |
| `_md_color` | `_md_color()` | L5121 | 20 |
| `_format_link_span` | `_format_link_span()` | L5126 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L5134 | 10 |
| `_visible_width` | `_visible_width()` | L5170 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L5177 | 2 |
| `_sum_widths` | `_sum_widths()` | L5191 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L5198 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L5218 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L5236 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L5251 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L5267 | 2 |
| `_break_long_token` | `_break_long_token()` | L5277 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L5304 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L5330 | 4 |
| `_split_table_row` | `_split_table_row()` | L5346 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L5354 | 2 |
| `_align_cell` | `_align_cell()` | L5373 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L5389 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L5405 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L5415 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L5432 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L5449 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L5461 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L5491 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L5500 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L5515 | 2 |
| `_format_header_line` | `_format_header_line()` | L5532 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L5551 | 2 |
| `_format_list_line` | `_format_list_line()` | L5562 | 2 |
| `_format_block_line` | `_format_block_line()` | L5587 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L5616 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L5623 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L5631 | 2 |
| `render_markdown` | `render_markdown()` | L5638 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L5672 | 0 |
| `extract_basename` | `extract_basename()` | L5710 | 2 |
| `truncate_text` | `truncate_text()` | L5721 | 4 |
| `_format_line_range` | `_format_line_range()` | L5736 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L5751 | 4 |
| `format_tool_call` | `format_tool_call()` | L5816 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L5825 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L5835 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L5840 | 4 |
| `format_retry_status` | `format_retry_status()` | L5844 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L5853 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L5862 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L5871 | 2 |
| `slow_print` | `slow_print()` | L5881 | 2 |
| `show_banner` | `show_banner()` | L5899 | 2 |
| `handle_openai_switch` | `handle_openai_switch()` | L5969 | 0 |

## [`scripts/check_minimum_version.pl`](../scripts/check_minimum_version.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `normalize_version` | `normalize_version()` | L93 | 2 |
| `static_check_file` | `static_check_file()` | L110 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L39 | 6 |
| `format_context_size` | `format_context_size()` | L58 | 4 |
| `init_max_tokens` | `init_max_tokens()` | L74 | 2 |
| `get_max_retries` | `get_max_retries()` | L90 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L98 | 4 |
| `init_retry_config` | `init_retry_config()` | L116 | 2 |
| `get_env_file_path` | `get_env_file_path()` | L125 | 8 |
| `load_env_file` | `load_env_file()` | L132 | 2 |
| `normalize_openai_endpoint` | `normalize_openai_endpoint()` | L156 | 2 |
| `save_env_vars` | `save_env_vars()` | L170 | 2 |
| `cursor_hide` | `cursor_hide()` | L238 | 6 |
| `cursor_show` | `cursor_show()` | L243 | 10 |
| `configure_provider` | `configure_provider()` | L278 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L7 | 34 |
| `encode_string` | `encode_string()` | L36 | 2 |
| `decode` | `decode()` | L48 | 26 |
| `_skip_ws` | `_skip_ws()` | L56 | 6 |
| `_decode_value` | `_decode_value()` | L62 | 6 |
| `_decode_object` | `_decode_object()` | L98 | 2 |
| `_decode_array` | `_decode_array()` | L123 | 2 |
| `_decode_string` | `_decode_string()` | L144 | 4 |

## [`src/main.pl`](../src/main.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `handle_openai_switch` | `handle_openai_switch()` | L3 | 0 |

## [`src/markdown.pl`](../src/markdown.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_md_color` | `_md_color()` | L3 | 20 |
| `_format_link_span` | `_format_link_span()` | L8 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L16 | 10 |
| `_visible_width` | `_visible_width()` | L52 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L59 | 2 |
| `_sum_widths` | `_sum_widths()` | L73 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L80 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L100 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L118 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L133 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L149 | 2 |
| `_break_long_token` | `_break_long_token()` | L159 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L186 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L212 | 4 |
| `_split_table_row` | `_split_table_row()` | L228 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L236 | 2 |
| `_align_cell` | `_align_cell()` | L255 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L271 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L287 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L297 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L314 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L331 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L343 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L373 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L382 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L397 | 2 |
| `_format_header_line` | `_format_header_line()` | L414 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L433 | 2 |
| `_format_list_line` | `_format_list_line()` | L444 | 2 |
| `_format_block_line` | `_format_block_line()` | L469 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L498 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L505 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L513 | 2 |
| `render_markdown` | `render_markdown()` | L520 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L554 | 0 |

## [`src/mcp.pl`](../src/mcp.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_mcp_config_path` | `get_mcp_config_path()` | L14 | 4 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L34 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L59 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L103 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L120 | 2 |
| `save_mcp_config` | `save_mcp_config()` | L173 | 4 |
| `mcp_build_request` | `mcp_build_request()` | L223 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L238 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L251 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L269 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L274 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L281 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L290 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L307 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L346 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L371 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L397 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L405 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L413 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L420 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L443 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L467 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L486 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L557 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L713 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L742 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L755 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L789 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L862 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L889 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L926 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L968 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L980 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L991 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L1020 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L1077 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L1100 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L1121 | 2 |

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
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L79 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L85 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L93 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L99 | 2 |
| `read_agents_file` | `read_agents_file()` | L106 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L119 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L128 | 4 |
| `get_agents_context` | `get_agents_context()` | L139 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L165 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L177 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L202 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L214 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L244 | 2 |
| `discover_skills` | `discover_skills()` | L265 | 2 |
| `get_skills_context` | `get_skills_context()` | L279 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L299 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L311 | 6 |

## [`src/providers.pl`](../src/providers.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `build_headers` | `build_headers()` | L7 | 4 |
| `build_request` | `build_request()` | L21 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L30 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L61 | 2 |
| `_clean_gemini_schema` | `_clean_gemini_schema()` | L104 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L189 | 2 |
| `build_request_openai` | `build_request_openai()` | L201 | 2 |
| `_merge_consecutive_blocks` | `_merge_consecutive_blocks()` | L268 | 2 |
| `parse_response` | `parse_response()` | L289 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L304 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L336 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L346 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L401 | 2 |
| `_to_int` | `_to_int()` | L412 | 2 |
| `_make_token_usage` | `_make_token_usage()` | L417 | 2 |
| `extract_token_usage` | `extract_token_usage()` | L429 | 2 |
| `record_api_response_stats` | `record_api_response_stats()` | L455 | 4 |
| `fetch_models` | `fetch_models()` | L477 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L509 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L541 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L584 | 2 |

## [`src/session.pl`](../src/session.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_current_model` | `get_current_model()` | L2 | 4 |
| `get_current_provider` | `get_current_provider()` | L6 | 6 |
| `get_current_api_url` | `get_current_api_url()` | L10 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L14 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L18 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L24 | 4 |
| `set_max_tokens` | `set_max_tokens()` | L28 | 2 |
| `generate_session_id` | `generate_session_id()` | L38 | 4 |
| `init_session` | `init_session()` | L45 | 4 |
| `get_session_stats` | `get_session_stats()` | L70 | 8 |
| `record_session_tokens` | `record_session_tokens()` | L92 | 2 |
| `record_session_tool_call` | `record_session_tool_call()` | L115 | 2 |
| `record_session_subagent` | `record_session_subagent()` | L133 | 2 |
| `get_current_session` | `get_current_session()` | L151 | 6 |
| `archive_session` | `archive_session()` | L156 | 2 |
| `handle_new_command` | `handle_new_command()` | L165 | 2 |
| `show_help` | `show_help()` | L177 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L196 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L221 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L229 | 2 |
| `handle_models_command` | `handle_models_command()` | L237 | 2 |
| `compact_tool_result_content` | `compact_tool_result_content()` | L263 | 2 |
| `estimate_session_chars` | `estimate_session_chars()` | L317 | 4 |
| `_find_user_turn_indices` | `_find_user_turn_indices()` | L343 | 4 |
| `count_user_turns` | `count_user_turns()` | L369 | 2 |
| `compact_session_history` | `compact_session_history()` | L377 | 4 |
| `auto_compact_session_if_needed` | `auto_compact_session_if_needed()` | L430 | 2 |
| `handle_compact_command` | `handle_compact_command()` | L452 | 2 |
| `_commify` | `_commify()` | L469 | 2 |
| `format_uptime` | `format_uptime()` | L477 | 2 |
| `get_context_window_size` | `get_context_window_size()` | L495 | 2 |
| `format_session_stats` | `format_session_stats()` | L513 | 2 |
| `handle_stats_command` | `handle_stats_command()` | L599 | 2 |

## [`src/terminal.pl`](../src/terminal.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_has_hires_time` | `_has_hires_time()` | L12 | 2 |
| `_hires_time` | `_hires_time()` | L13 | 6 |
| `_debug_log` | `_debug_log()` | L21 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L43 | 2 |
| `_char_width` | `_char_width()` | L54 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L67 | 6 |
| `_display_width` | `_display_width()` | L74 | 0 |
| `_term_size` | `_term_size()` | L86 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L105 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L162 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L230 | 2 |
| `_walk_position` | `_walk_position()` | L271 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L291 | 8 |

## [`src/tools.pl`](../src/tools.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `confirm` | `confirm()` | L81 | 4 |
| `confirm_tool` | `confirm_tool()` | L88 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L97 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L120 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L207 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L243 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L287 | 4 |
| `read_line_or_cancel` | `read_line_or_cancel()` | L294 | 2 |
| `_read_prompt_or_cancel` | `_read_prompt_or_cancel()` | L299 | 4 |
| `format_tool_result` | `format_tool_result()` | L353 | 4 |
| `run_tool` | `run_tool()` | L363 | 4 |
| `run_subagent` | `run_subagent()` | L567 | 2 |

## [`src/transport.pl`](../src/transport.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_is_tty_active` | `_is_tty_active()` | L3 | 6 |
| `_has_request_body` | `_has_request_body()` | L7 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L13 | 4 |
| `_create_secure_tempfile` | `_create_secure_tempfile()` | L29 | 2 |
| `_write_curl_config` | `_write_curl_config()` | L46 | 2 |
| `_build_curl_cmd` | `_build_curl_cmd()` | L75 | 4 |
| `_run_curl_sync` | `_run_curl_sync()` | L80 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L87 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L99 | 2 |
| `_execute_curl` | `_execute_curl()` | L116 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L147 | 2 |
| `_is_retryable_error` | `_is_retryable_error()` | L168 | 2 |
| `_call_api_once` | `_call_api_once()` | L178 | 2 |
| `call_api` | `call_api()` | L223 | 10 |
| `quote` | `quote()` | L248 | 2 |

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
| `show_banner` | `show_banner()` | L192 | 2 |
