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
| `encode` | `encode()` | L573 | 34 |
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
| `get_mcp_config_path` | `get_mcp_config_path()` | L2449 | 4 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L2469 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L2494 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L2538 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L2555 | 2 |
| `save_mcp_config` | `save_mcp_config()` | L2608 | 4 |
| `mcp_build_request` | `mcp_build_request()` | L2658 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L2673 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L2686 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L2704 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L2709 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L2716 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L2725 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L2742 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L2781 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L2806 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L2832 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L2840 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L2848 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L2855 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L2878 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L2902 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L2921 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L2992 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L3148 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3177 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3190 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3224 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3297 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3324 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3361 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3403 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L3415 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L3426 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L3455 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L3512 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L3535 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L3556 | 2 |
| `_debug_log` | `_debug_log()` | L3596 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L3618 | 2 |
| `_char_width` | `_char_width()` | L3629 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L3642 | 6 |
| `_display_width` | `_display_width()` | L3649 | 0 |
| `_term_size` | `_term_size()` | L3661 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L3680 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L3736 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L3803 | 2 |
| `_walk_position` | `_walk_position()` | L3844 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L3864 | 8 |
| `_md_color` | `_md_color()` | L4218 | 20 |
| `_format_link_span` | `_format_link_span()` | L4223 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4231 | 10 |
| `_visible_width` | `_visible_width()` | L4267 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4274 | 2 |
| `_sum_widths` | `_sum_widths()` | L4288 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4295 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4315 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4333 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4348 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4364 | 2 |
| `_break_long_token` | `_break_long_token()` | L4374 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4401 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L4427 | 4 |
| `_split_table_row` | `_split_table_row()` | L4443 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L4451 | 2 |
| `_align_cell` | `_align_cell()` | L4470 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L4486 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L4502 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L4512 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L4529 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L4546 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L4558 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L4588 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L4597 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L4612 | 2 |
| `_format_header_line` | `_format_header_line()` | L4629 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L4648 | 2 |
| `_format_list_line` | `_format_list_line()` | L4659 | 2 |
| `_format_block_line` | `_format_block_line()` | L4684 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L4713 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L4720 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L4728 | 2 |
| `render_markdown` | `render_markdown()` | L4735 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L4769 | 0 |
| `extract_basename` | `extract_basename()` | L4805 | 2 |
| `truncate_text` | `truncate_text()` | L4816 | 4 |
| `_format_line_range` | `_format_line_range()` | L4831 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L4846 | 4 |
| `format_tool_call` | `format_tool_call()` | L4911 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L4920 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L4930 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L4935 | 4 |
| `format_retry_status` | `format_retry_status()` | L4939 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L4948 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L4957 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L4966 | 2 |
| `slow_print` | `slow_print()` | L4976 | 2 |
| `show_banner` | `show_banner()` | L4994 | 1 |

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
| `encode` | `encode()` | L6 | 34 |
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
