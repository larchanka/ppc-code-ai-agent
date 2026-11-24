# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L39 | 6 |
| `format_context_size` | `format_context_size()` | L58 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L74 | 0 |
| `get_max_retries` | `get_max_retries()` | L90 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L98 | 4 |
| `init_retry_config` | `init_retry_config()` | L106 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L115 | 6 |
| `load_env_file` | `load_env_file()` | L122 | 2 |
| `cursor_hide` | `cursor_hide()` | L164 | 6 |
| `cursor_show` | `cursor_show()` | L169 | 10 |
| `configure_provider` | `configure_provider()` | L204 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L306 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L312 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L320 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L326 | 2 |
| `read_agents_file` | `read_agents_file()` | L333 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L346 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L355 | 4 |
| `get_agents_context` | `get_agents_context()` | L366 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L392 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L404 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L429 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L441 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L471 | 2 |
| `discover_skills` | `discover_skills()` | L492 | 2 |
| `get_skills_context` | `get_skills_context()` | L506 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L526 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L538 | 6 |
| `encode` | `encode()` | L573 | 32 |
| `encode_string` | `encode_string()` | L602 | 2 |
| `decode` | `decode()` | L613 | 24 |
| `_skip_ws` | `_skip_ws()` | L620 | 6 |
| `_decode_value` | `_decode_value()` | L625 | 6 |
| `_decode_object` | `_decode_object()` | L642 | 2 |
| `_decode_array` | `_decode_array()` | L664 | 2 |
| `_decode_string` | `_decode_string()` | L682 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L718 | 4 |
| `_has_request_body` | `_has_request_body()` | L722 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L728 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L742 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L770 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L782 | 2 |
| `_execute_curl` | `_execute_curl()` | L799 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L823 | 2 |
| `_call_api_once` | `_call_api_once()` | L841 | 2 |
| `call_api` | `call_api()` | L878 | 10 |
| `quote` | `quote()` | L901 | 2 |
| `build_headers` | `build_headers()` | L915 | 4 |
| `build_request` | `build_request()` | L929 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L938 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L969 | 2 |
| `_clean_gemini_schema` | `_clean_gemini_schema()` | L1012 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1097 | 2 |
| `build_request_openai` | `build_request_openai()` | L1109 | 2 |
| `parse_response` | `parse_response()` | L1176 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1183 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1215 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1225 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1266 | 2 |
| `fetch_models` | `fetch_models()` | L1276 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1308 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1340 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1383 | 2 |
| `_normalize_models` | `_normalize_models()` | L1432 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1449 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1473 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1531 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1572 | 2 |
| `get_current_model` | `get_current_model()` | L1697 | 2 |
| `get_current_provider` | `get_current_provider()` | L1701 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1705 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1709 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1713 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1719 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1723 | 2 |
| `generate_session_id` | `generate_session_id()` | L1733 | 4 |
| `init_session` | `init_session()` | L1740 | 4 |
| `get_current_session` | `get_current_session()` | L1753 | 2 |
| `archive_session` | `archive_session()` | L1758 | 2 |
| `handle_new_command` | `handle_new_command()` | L1767 | 2 |
| `show_help` | `show_help()` | L1779 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1796 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1821 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1829 | 2 |
| `handle_models_command` | `handle_models_command()` | L1837 | 2 |
| `confirm` | `confirm()` | L1945 | 4 |
| `confirm_tool` | `confirm_tool()` | L1952 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L1961 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1984 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L2071 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2107 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2151 | 4 |
| `format_tool_result` | `format_tool_result()` | L2195 | 4 |
| `run_tool` | `run_tool()` | L2205 | 4 |
| `run_subagent` | `run_subagent()` | L2323 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L2449 | 2 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L2469 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L2494 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L2538 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L2555 | 2 |
| `mcp_build_request` | `mcp_build_request()` | L2610 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L2625 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L2638 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L2656 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L2661 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L2668 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L2677 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L2694 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L2733 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L2758 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L2784 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L2792 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L2800 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L2807 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L2830 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L2854 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L2873 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L2944 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L3100 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3129 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3142 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3176 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3249 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3276 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3313 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3355 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L3367 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L3378 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L3407 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L3459 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L3481 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L3502 | 2 |
| `_debug_log` | `_debug_log()` | L3542 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L3564 | 2 |
| `_char_width` | `_char_width()` | L3575 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L3588 | 6 |
| `_display_width` | `_display_width()` | L3595 | 0 |
| `_term_size` | `_term_size()` | L3607 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L3626 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L3682 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L3749 | 2 |
| `_walk_position` | `_walk_position()` | L3790 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L3810 | 8 |
| `_md_color` | `_md_color()` | L4164 | 20 |
| `_format_link_span` | `_format_link_span()` | L4169 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4177 | 10 |
| `_visible_width` | `_visible_width()` | L4213 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4220 | 2 |
| `_sum_widths` | `_sum_widths()` | L4234 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4241 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4261 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4279 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4294 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4310 | 2 |
| `_break_long_token` | `_break_long_token()` | L4320 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4347 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L4373 | 4 |
| `_split_table_row` | `_split_table_row()` | L4389 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L4397 | 2 |
| `_align_cell` | `_align_cell()` | L4416 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L4432 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L4448 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L4458 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L4475 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L4492 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L4504 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L4534 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L4543 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L4558 | 2 |
| `_format_header_line` | `_format_header_line()` | L4575 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L4594 | 2 |
| `_format_list_line` | `_format_list_line()` | L4605 | 2 |
| `_format_block_line` | `_format_block_line()` | L4630 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L4659 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L4666 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L4674 | 2 |
| `render_markdown` | `render_markdown()` | L4681 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L4715 | 0 |
| `extract_basename` | `extract_basename()` | L4751 | 2 |
| `truncate_text` | `truncate_text()` | L4762 | 4 |
| `_format_line_range` | `_format_line_range()` | L4777 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L4792 | 4 |
| `format_tool_call` | `format_tool_call()` | L4857 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L4866 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L4876 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L4881 | 4 |
| `format_retry_status` | `format_retry_status()` | L4885 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L4894 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L4903 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L4912 | 2 |
| `slow_print` | `slow_print()` | L4922 | 2 |
| `show_banner` | `show_banner()` | L4940 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L38 | 6 |
| `format_context_size` | `format_context_size()` | L57 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L73 | 0 |
| `get_max_retries` | `get_max_retries()` | L89 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L97 | 4 |
| `init_retry_config` | `init_retry_config()` | L105 | 0 |
| `get_env_file_path` | `get_env_file_path()` | L114 | 6 |
| `load_env_file` | `load_env_file()` | L121 | 2 |
| `cursor_hide` | `cursor_hide()` | L163 | 6 |
| `cursor_show` | `cursor_show()` | L168 | 10 |
| `configure_provider` | `configure_provider()` | L203 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L6 | 32 |
| `encode_string` | `encode_string()` | L35 | 2 |
| `decode` | `decode()` | L46 | 24 |
| `_skip_ws` | `_skip_ws()` | L53 | 6 |
| `_decode_value` | `_decode_value()` | L58 | 6 |
| `_decode_object` | `_decode_object()` | L75 | 2 |
| `_decode_array` | `_decode_array()` | L97 | 2 |
| `_decode_string` | `_decode_string()` | L115 | 4 |

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
| `get_mcp_config_path` | `get_mcp_config_path()` | L14 | 2 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L34 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L59 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L103 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L120 | 2 |
| `mcp_build_request` | `mcp_build_request()` | L175 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L190 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L203 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L221 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L226 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L233 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L242 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L259 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L298 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L323 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L349 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L357 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L365 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L372 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L395 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L419 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L438 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L509 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L665 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L694 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L707 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L741 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L814 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L841 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L878 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L920 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L932 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L943 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L972 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L1024 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L1046 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L1067 | 2 |

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
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L66 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L72 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L80 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L86 | 2 |
| `read_agents_file` | `read_agents_file()` | L93 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L106 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L115 | 4 |
| `get_agents_context` | `get_agents_context()` | L126 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L152 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L164 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L189 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L201 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L231 | 2 |
| `discover_skills` | `discover_skills()` | L252 | 2 |
| `get_skills_context` | `get_skills_context()` | L266 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L286 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L298 | 6 |

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
| `parse_response` | `parse_response()` | L268 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L275 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L307 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L317 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L358 | 2 |
| `fetch_models` | `fetch_models()` | L368 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L400 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L432 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L475 | 2 |

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
| `handle_ctx_command` | `handle_ctx_command()` | L101 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L126 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L134 | 2 |
| `handle_models_command` | `handle_models_command()` | L142 | 2 |

## [`src/terminal.pl`](../src/terminal.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `_debug_log` | `_debug_log()` | L12 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L34 | 2 |
| `_char_width` | `_char_width()` | L45 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L58 | 6 |
| `_display_width` | `_display_width()` | L65 | 0 |
| `_term_size` | `_term_size()` | L77 | 4 |
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
| `confirm_tool` | `confirm_tool()` | L87 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L96 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L119 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L206 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L242 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L286 | 4 |
| `format_tool_result` | `format_tool_result()` | L330 | 4 |
| `run_tool` | `run_tool()` | L340 | 4 |
| `run_subagent` | `run_subagent()` | L458 | 2 |

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
