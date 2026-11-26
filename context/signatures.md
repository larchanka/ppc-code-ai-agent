# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L40 | 6 |
| `format_context_size` | `format_context_size()` | L59 | 2 |
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
| `fetch_models` | `fetch_models()` | L1542 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1574 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1606 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1649 | 2 |
| `_normalize_models` | `_normalize_models()` | L1698 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1715 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1739 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1797 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1838 | 2 |
| `get_current_model` | `get_current_model()` | L1963 | 2 |
| `get_current_provider` | `get_current_provider()` | L1967 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1971 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1975 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1979 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1985 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1989 | 2 |
| `generate_session_id` | `generate_session_id()` | L1999 | 4 |
| `init_session` | `init_session()` | L2006 | 4 |
| `get_current_session` | `get_current_session()` | L2019 | 2 |
| `archive_session` | `archive_session()` | L2024 | 2 |
| `handle_new_command` | `handle_new_command()` | L2033 | 2 |
| `show_help` | `show_help()` | L2045 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L2063 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L2088 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L2096 | 2 |
| `handle_models_command` | `handle_models_command()` | L2104 | 2 |
| `compact_tool_result_content` | `compact_tool_result_content()` | L2130 | 2 |
| `estimate_session_chars` | `estimate_session_chars()` | L2184 | 2 |
| `_find_user_turn_indices` | `_find_user_turn_indices()` | L2210 | 4 |
| `count_user_turns` | `count_user_turns()` | L2236 | 2 |
| `compact_session_history` | `compact_session_history()` | L2244 | 4 |
| `auto_compact_session_if_needed` | `auto_compact_session_if_needed()` | L2297 | 2 |
| `handle_compact_command` | `handle_compact_command()` | L2319 | 2 |
| `confirm` | `confirm()` | L2420 | 4 |
| `confirm_tool` | `confirm_tool()` | L2427 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L2436 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L2459 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L2546 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2582 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2626 | 4 |
| `read_line_or_cancel` | `read_line_or_cancel()` | L2633 | 2 |
| `_read_prompt_or_cancel` | `_read_prompt_or_cancel()` | L2638 | 4 |
| `format_tool_result` | `format_tool_result()` | L2692 | 4 |
| `run_tool` | `run_tool()` | L2702 | 4 |
| `run_subagent` | `run_subagent()` | L2904 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L3034 | 4 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L3054 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L3079 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L3123 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L3140 | 2 |
| `save_mcp_config` | `save_mcp_config()` | L3193 | 4 |
| `mcp_build_request` | `mcp_build_request()` | L3243 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L3258 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L3271 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L3289 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L3294 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L3301 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L3310 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L3327 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L3366 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L3391 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L3417 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L3425 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L3433 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L3440 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L3463 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L3487 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L3506 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L3577 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L3733 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3762 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3775 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3809 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3882 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3909 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3946 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3988 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L4000 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L4011 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L4040 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L4097 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L4120 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L4141 | 2 |
| `_has_hires_time` | `_has_hires_time()` | L4181 | 2 |
| `_hires_time` | `_hires_time()` | L4182 | 6 |
| `_debug_log` | `_debug_log()` | L4190 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L4212 | 2 |
| `_char_width` | `_char_width()` | L4223 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L4236 | 6 |
| `_display_width` | `_display_width()` | L4243 | 0 |
| `_term_size` | `_term_size()` | L4255 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L4274 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L4331 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L4399 | 2 |
| `_walk_position` | `_walk_position()` | L4440 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L4460 | 8 |
| `_md_color` | `_md_color()` | L4814 | 20 |
| `_format_link_span` | `_format_link_span()` | L4819 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4827 | 10 |
| `_visible_width` | `_visible_width()` | L4863 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4870 | 2 |
| `_sum_widths` | `_sum_widths()` | L4884 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4891 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4911 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4929 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4944 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4960 | 2 |
| `_break_long_token` | `_break_long_token()` | L4970 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4997 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L5023 | 4 |
| `_split_table_row` | `_split_table_row()` | L5039 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L5047 | 2 |
| `_align_cell` | `_align_cell()` | L5066 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L5082 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L5098 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L5108 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L5125 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L5142 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L5154 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L5184 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L5193 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L5208 | 2 |
| `_format_header_line` | `_format_header_line()` | L5225 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L5244 | 2 |
| `_format_list_line` | `_format_list_line()` | L5255 | 2 |
| `_format_block_line` | `_format_block_line()` | L5280 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L5309 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L5316 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L5324 | 2 |
| `render_markdown` | `render_markdown()` | L5331 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L5365 | 0 |
| `extract_basename` | `extract_basename()` | L5403 | 2 |
| `truncate_text` | `truncate_text()` | L5414 | 4 |
| `_format_line_range` | `_format_line_range()` | L5429 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L5444 | 4 |
| `format_tool_call` | `format_tool_call()` | L5509 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L5518 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L5528 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L5533 | 4 |
| `format_retry_status` | `format_retry_status()` | L5537 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L5546 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L5555 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L5564 | 2 |
| `slow_print` | `slow_print()` | L5574 | 2 |
| `show_banner` | `show_banner()` | L5592 | 2 |
| `handle_openai_switch` | `handle_openai_switch()` | L5662 | 0 |

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
| `format_context_size` | `format_context_size()` | L58 | 2 |
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
| `fetch_models` | `fetch_models()` | L411 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L443 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L475 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L518 | 2 |

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
| `handle_ctx_command` | `handle_ctx_command()` | L102 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L127 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L135 | 2 |
| `handle_models_command` | `handle_models_command()` | L143 | 2 |
| `compact_tool_result_content` | `compact_tool_result_content()` | L169 | 2 |
| `estimate_session_chars` | `estimate_session_chars()` | L223 | 2 |
| `_find_user_turn_indices` | `_find_user_turn_indices()` | L249 | 4 |
| `count_user_turns` | `count_user_turns()` | L275 | 2 |
| `compact_session_history` | `compact_session_history()` | L283 | 4 |
| `auto_compact_session_if_needed` | `auto_compact_session_if_needed()` | L336 | 2 |
| `handle_compact_command` | `handle_compact_command()` | L358 | 2 |

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
| `run_subagent` | `run_subagent()` | L565 | 2 |

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
