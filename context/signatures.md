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
| `encode` | `encode()` | L571 | 32 |
| `encode_string` | `encode_string()` | L591 | 2 |
| `decode` | `decode()` | L602 | 24 |
| `_skip_ws` | `_skip_ws()` | L609 | 6 |
| `_decode_value` | `_decode_value()` | L614 | 6 |
| `_decode_object` | `_decode_object()` | L631 | 2 |
| `_decode_array` | `_decode_array()` | L653 | 2 |
| `_decode_string` | `_decode_string()` | L671 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L707 | 4 |
| `_has_request_body` | `_has_request_body()` | L711 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L717 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L731 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L759 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L771 | 2 |
| `_execute_curl` | `_execute_curl()` | L788 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L812 | 2 |
| `_call_api_once` | `_call_api_once()` | L830 | 2 |
| `call_api` | `call_api()` | L867 | 10 |
| `quote` | `quote()` | L890 | 2 |
| `build_headers` | `build_headers()` | L904 | 4 |
| `build_request` | `build_request()` | L918 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L927 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L958 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1019 | 2 |
| `build_request_openai` | `build_request_openai()` | L1031 | 2 |
| `parse_response` | `parse_response()` | L1098 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1105 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1137 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1147 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1188 | 2 |
| `fetch_models` | `fetch_models()` | L1198 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1230 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1262 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1305 | 2 |
| `_normalize_models` | `_normalize_models()` | L1354 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1371 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1395 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1453 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1494 | 2 |
| `get_current_model` | `get_current_model()` | L1619 | 2 |
| `get_current_provider` | `get_current_provider()` | L1623 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1627 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1631 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1635 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1641 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1645 | 2 |
| `generate_session_id` | `generate_session_id()` | L1655 | 4 |
| `init_session` | `init_session()` | L1662 | 4 |
| `get_current_session` | `get_current_session()` | L1675 | 2 |
| `archive_session` | `archive_session()` | L1680 | 2 |
| `handle_new_command` | `handle_new_command()` | L1689 | 2 |
| `show_help` | `show_help()` | L1701 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1718 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1743 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1751 | 2 |
| `handle_models_command` | `handle_models_command()` | L1759 | 2 |
| `confirm` | `confirm()` | L1867 | 4 |
| `confirm_tool` | `confirm_tool()` | L1874 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L1883 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1906 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1993 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2029 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2073 | 4 |
| `format_tool_result` | `format_tool_result()` | L2117 | 4 |
| `run_tool` | `run_tool()` | L2127 | 4 |
| `run_subagent` | `run_subagent()` | L2245 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L2371 | 2 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L2391 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L2416 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L2460 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L2477 | 2 |
| `mcp_build_request` | `mcp_build_request()` | L2532 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L2547 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L2560 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L2578 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L2583 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L2590 | 2 |
| `mcp_parse_response` | `mcp_parse_response()` | L2600 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L2638 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L2663 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L2689 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L2697 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L2705 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L2712 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L2735 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L2759 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L2778 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L2841 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L2996 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3025 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3038 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3072 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3145 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3172 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3209 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3251 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L3263 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L3274 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L3303 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L3355 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L3377 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L3398 | 2 |
| `_debug_log` | `_debug_log()` | L3438 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L3460 | 2 |
| `_char_width` | `_char_width()` | L3471 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L3484 | 6 |
| `_display_width` | `_display_width()` | L3491 | 0 |
| `_term_size` | `_term_size()` | L3503 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L3522 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L3578 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L3645 | 2 |
| `_walk_position` | `_walk_position()` | L3686 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L3706 | 8 |
| `_md_color` | `_md_color()` | L4060 | 20 |
| `_format_link_span` | `_format_link_span()` | L4065 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4073 | 10 |
| `_visible_width` | `_visible_width()` | L4109 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4116 | 2 |
| `_sum_widths` | `_sum_widths()` | L4130 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4137 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4157 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4175 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4190 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4206 | 2 |
| `_break_long_token` | `_break_long_token()` | L4216 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4243 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L4269 | 4 |
| `_split_table_row` | `_split_table_row()` | L4285 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L4293 | 2 |
| `_align_cell` | `_align_cell()` | L4312 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L4328 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L4344 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L4354 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L4371 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L4388 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L4400 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L4430 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L4439 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L4454 | 2 |
| `_format_header_line` | `_format_header_line()` | L4471 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L4490 | 2 |
| `_format_list_line` | `_format_list_line()` | L4501 | 2 |
| `_format_block_line` | `_format_block_line()` | L4526 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L4555 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L4562 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L4570 | 2 |
| `render_markdown` | `render_markdown()` | L4577 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L4611 | 0 |
| `extract_basename` | `extract_basename()` | L4647 | 2 |
| `truncate_text` | `truncate_text()` | L4658 | 4 |
| `_format_line_range` | `_format_line_range()` | L4673 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L4688 | 4 |
| `format_tool_call` | `format_tool_call()` | L4753 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L4762 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L4772 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L4777 | 4 |
| `format_retry_status` | `format_retry_status()` | L4781 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L4790 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L4799 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L4808 | 2 |
| `slow_print` | `slow_print()` | L4818 | 2 |
| `show_banner` | `show_banner()` | L4836 | 1 |

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
| `encode` | `encode()` | L4 | 32 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 24 |
| `_skip_ws` | `_skip_ws()` | L42 | 6 |
| `_decode_value` | `_decode_value()` | L47 | 6 |
| `_decode_object` | `_decode_object()` | L64 | 2 |
| `_decode_array` | `_decode_array()` | L86 | 2 |
| `_decode_string` | `_decode_string()` | L104 | 4 |

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
| `mcp_parse_response` | `mcp_parse_response()` | L243 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L281 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L306 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L332 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L340 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L348 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L355 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L378 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L402 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L421 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L484 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L639 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L668 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L681 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L715 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L788 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L815 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L852 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L894 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L906 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L917 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L946 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L998 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L1020 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L1041 | 2 |

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
