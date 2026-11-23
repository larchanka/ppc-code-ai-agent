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
| `configure_provider` | `configure_provider()` | L207 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L309 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L315 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L323 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L329 | 2 |
| `read_agents_file` | `read_agents_file()` | L336 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L349 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L358 | 4 |
| `get_agents_context` | `get_agents_context()` | L369 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L395 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L407 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L432 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L444 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L474 | 2 |
| `discover_skills` | `discover_skills()` | L495 | 2 |
| `get_skills_context` | `get_skills_context()` | L509 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L529 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L541 | 6 |
| `encode` | `encode()` | L574 | 32 |
| `encode_string` | `encode_string()` | L594 | 2 |
| `decode` | `decode()` | L605 | 24 |
| `_skip_ws` | `_skip_ws()` | L612 | 6 |
| `_decode_value` | `_decode_value()` | L617 | 6 |
| `_decode_object` | `_decode_object()` | L634 | 2 |
| `_decode_array` | `_decode_array()` | L656 | 2 |
| `_decode_string` | `_decode_string()` | L674 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L710 | 4 |
| `_has_request_body` | `_has_request_body()` | L714 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L720 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L734 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L762 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L774 | 2 |
| `_execute_curl` | `_execute_curl()` | L791 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L815 | 2 |
| `_call_api_once` | `_call_api_once()` | L833 | 2 |
| `call_api` | `call_api()` | L870 | 10 |
| `quote` | `quote()` | L893 | 2 |
| `build_headers` | `build_headers()` | L907 | 4 |
| `build_request` | `build_request()` | L921 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L930 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L961 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1022 | 2 |
| `build_request_openai` | `build_request_openai()` | L1034 | 2 |
| `parse_response` | `parse_response()` | L1101 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1108 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1140 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1150 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1191 | 2 |
| `fetch_models` | `fetch_models()` | L1201 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1233 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1265 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1308 | 2 |
| `_normalize_models` | `_normalize_models()` | L1357 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1374 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1398 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1456 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1497 | 2 |
| `get_current_model` | `get_current_model()` | L1622 | 2 |
| `get_current_provider` | `get_current_provider()` | L1626 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1630 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1634 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1638 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1644 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1648 | 2 |
| `generate_session_id` | `generate_session_id()` | L1658 | 4 |
| `init_session` | `init_session()` | L1665 | 4 |
| `get_current_session` | `get_current_session()` | L1678 | 2 |
| `archive_session` | `archive_session()` | L1683 | 2 |
| `handle_new_command` | `handle_new_command()` | L1692 | 2 |
| `show_help` | `show_help()` | L1704 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1721 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1746 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1754 | 2 |
| `handle_models_command` | `handle_models_command()` | L1762 | 2 |
| `confirm` | `confirm()` | L1870 | 4 |
| `confirm_tool` | `confirm_tool()` | L1877 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L1886 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1909 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1996 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2032 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2070 | 4 |
| `format_tool_result` | `format_tool_result()` | L2114 | 4 |
| `run_tool` | `run_tool()` | L2124 | 4 |
| `run_subagent` | `run_subagent()` | L2242 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L2369 | 2 |
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
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L2695 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L2701 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L2708 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L2731 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L2755 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L2774 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L2837 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L2992 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3021 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3034 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3068 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3141 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3168 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3205 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3247 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L3259 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L3270 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L3299 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L3351 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L3373 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L3394 | 2 |
| `_debug_log` | `_debug_log()` | L3434 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L3456 | 2 |
| `_char_width` | `_char_width()` | L3467 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L3480 | 6 |
| `_display_width` | `_display_width()` | L3487 | 0 |
| `_term_size` | `_term_size()` | L3499 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L3518 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L3574 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L3641 | 2 |
| `_walk_position` | `_walk_position()` | L3682 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L3702 | 8 |
| `_md_color` | `_md_color()` | L4056 | 20 |
| `_format_link_span` | `_format_link_span()` | L4061 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4069 | 10 |
| `_visible_width` | `_visible_width()` | L4105 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4112 | 2 |
| `_sum_widths` | `_sum_widths()` | L4126 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4133 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4153 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4171 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4186 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4202 | 2 |
| `_break_long_token` | `_break_long_token()` | L4212 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4239 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L4265 | 4 |
| `_split_table_row` | `_split_table_row()` | L4281 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L4289 | 2 |
| `_align_cell` | `_align_cell()` | L4308 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L4324 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L4340 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L4350 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L4367 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L4384 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L4396 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L4426 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L4435 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L4450 | 2 |
| `_format_header_line` | `_format_header_line()` | L4467 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L4486 | 2 |
| `_format_list_line` | `_format_list_line()` | L4497 | 2 |
| `_format_block_line` | `_format_block_line()` | L4522 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L4551 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L4558 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L4566 | 2 |
| `render_markdown` | `render_markdown()` | L4573 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L4607 | 0 |
| `extract_basename` | `extract_basename()` | L4643 | 2 |
| `truncate_text` | `truncate_text()` | L4654 | 4 |
| `_format_line_range` | `_format_line_range()` | L4669 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L4684 | 4 |
| `format_tool_call` | `format_tool_call()` | L4749 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L4758 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L4768 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L4773 | 4 |
| `format_retry_status` | `format_retry_status()` | L4777 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L4786 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L4795 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L4804 | 2 |
| `slow_print` | `slow_print()` | L4814 | 2 |
| `show_banner` | `show_banner()` | L4832 | 1 |

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
| `configure_provider` | `configure_provider()` | L206 | 2 |

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
| `get_mcp_config_path` | `get_mcp_config_path()` | L15 | 2 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L37 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L62 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L106 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L123 | 2 |
| `mcp_build_request` | `mcp_build_request()` | L178 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L193 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L206 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L224 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L229 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L236 | 2 |
| `mcp_parse_response` | `mcp_parse_response()` | L246 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L284 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L309 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L335 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L341 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L347 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L354 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L377 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L401 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L420 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L483 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L638 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L667 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L680 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L714 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L787 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L814 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L851 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L893 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L905 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L916 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L945 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L997 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L1019 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L1040 | 2 |

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
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L280 | 4 |
| `format_tool_result` | `format_tool_result()` | L324 | 4 |
| `run_tool` | `run_tool()` | L334 | 4 |
| `run_subagent` | `run_subagent()` | L452 | 2 |

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
