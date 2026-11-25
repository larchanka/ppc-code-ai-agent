# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `parse_context_size` | `parse_context_size()` | L39 | 6 |
| `format_context_size` | `format_context_size()` | L58 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L74 | 2 |
| `get_max_retries` | `get_max_retries()` | L90 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L98 | 4 |
| `init_retry_config` | `init_retry_config()` | L106 | 2 |
| `get_env_file_path` | `get_env_file_path()` | L115 | 8 |
| `load_env_file` | `load_env_file()` | L122 | 2 |
| `normalize_openai_endpoint` | `normalize_openai_endpoint()` | L146 | 2 |
| `save_env_vars` | `save_env_vars()` | L160 | 2 |
| `cursor_hide` | `cursor_hide()` | L228 | 6 |
| `cursor_show` | `cursor_show()` | L233 | 10 |
| `configure_provider` | `configure_provider()` | L268 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L370 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L376 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L384 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L390 | 2 |
| `read_agents_file` | `read_agents_file()` | L397 | 2 |
| `_resolve_context_dirs` | `_resolve_context_dirs()` | L410 | 4 |
| `_is_same_inode` | `_is_same_inode()` | L419 | 4 |
| `get_agents_context` | `get_agents_context()` | L430 | 2 |
| `_clean_yaml_scalar` | `_clean_yaml_scalar()` | L456 | 2 |
| `_parse_frontmatter_block` | `_parse_frontmatter_block()` | L468 | 2 |
| `_first_body_summary_line` | `_first_body_summary_line()` | L493 | 2 |
| `parse_skill_frontmatter` | `parse_skill_frontmatter()` | L505 | 2 |
| `_scan_skills_dir` | `_scan_skills_dir()` | L535 | 2 |
| `discover_skills` | `discover_skills()` | L556 | 2 |
| `get_skills_context` | `get_skills_context()` | L570 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L590 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L602 | 6 |
| `encode` | `encode()` | L638 | 34 |
| `encode_string` | `encode_string()` | L667 | 2 |
| `decode` | `decode()` | L679 | 26 |
| `_skip_ws` | `_skip_ws()` | L687 | 6 |
| `_decode_value` | `_decode_value()` | L693 | 6 |
| `_decode_object` | `_decode_object()` | L729 | 2 |
| `_decode_array` | `_decode_array()` | L754 | 2 |
| `_decode_string` | `_decode_string()` | L775 | 4 |
| `_is_tty_active` | `_is_tty_active()` | L855 | 4 |
| `_has_request_body` | `_has_request_body()` | L859 | 4 |
| `_read_and_unlink` | `_read_and_unlink()` | L865 | 4 |
| `_write_curl_config` | `_write_curl_config()` | L879 | 2 |
| `_exec_curl_child` | `_exec_curl_child()` | L907 | 2 |
| `_wait_curl_timer` | `_wait_curl_timer()` | L919 | 2 |
| `_execute_curl` | `_execute_curl()` | L936 | 2 |
| `_decode_api_response` | `_decode_api_response()` | L960 | 2 |
| `_call_api_once` | `_call_api_once()` | L978 | 2 |
| `call_api` | `call_api()` | L1015 | 10 |
| `quote` | `quote()` | L1038 | 2 |
| `build_headers` | `build_headers()` | L1052 | 4 |
| `build_request` | `build_request()` | L1066 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L1075 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L1106 | 2 |
| `_clean_gemini_schema` | `_clean_gemini_schema()` | L1149 | 0 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L1234 | 2 |
| `build_request_openai` | `build_request_openai()` | L1246 | 2 |
| `_merge_consecutive_blocks` | `_merge_consecutive_blocks()` | L1313 | 2 |
| `parse_response` | `parse_response()` | L1334 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L1349 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L1381 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L1391 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L1446 | 2 |
| `fetch_models` | `fetch_models()` | L1456 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L1488 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L1520 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1563 | 2 |
| `_normalize_models` | `_normalize_models()` | L1612 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1629 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1653 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1711 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1752 | 2 |
| `get_current_model` | `get_current_model()` | L1877 | 2 |
| `get_current_provider` | `get_current_provider()` | L1881 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1885 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1889 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1893 | 4 |
| `get_max_tokens` | `get_max_tokens()` | L1899 | 2 |
| `set_max_tokens` | `set_max_tokens()` | L1903 | 2 |
| `generate_session_id` | `generate_session_id()` | L1913 | 4 |
| `init_session` | `init_session()` | L1920 | 4 |
| `get_current_session` | `get_current_session()` | L1933 | 2 |
| `archive_session` | `archive_session()` | L1938 | 2 |
| `handle_new_command` | `handle_new_command()` | L1947 | 2 |
| `show_help` | `show_help()` | L1959 | 2 |
| `handle_ctx_command` | `handle_ctx_command()` | L1977 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L2002 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L2010 | 2 |
| `handle_models_command` | `handle_models_command()` | L2018 | 2 |
| `compact_tool_result_content` | `compact_tool_result_content()` | L2044 | 2 |
| `estimate_session_chars` | `estimate_session_chars()` | L2098 | 2 |
| `_find_user_turn_indices` | `_find_user_turn_indices()` | L2124 | 4 |
| `count_user_turns` | `count_user_turns()` | L2150 | 2 |
| `compact_session_history` | `compact_session_history()` | L2158 | 4 |
| `auto_compact_session_if_needed` | `auto_compact_session_if_needed()` | L2211 | 2 |
| `handle_compact_command` | `handle_compact_command()` | L2233 | 2 |
| `confirm` | `confirm()` | L2333 | 4 |
| `confirm_tool` | `confirm_tool()` | L2340 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L2349 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L2372 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L2459 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L2495 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L2539 | 4 |
| `read_line_or_cancel` | `read_line_or_cancel()` | L2546 | 2 |
| `_read_prompt_or_cancel` | `_read_prompt_or_cancel()` | L2551 | 4 |
| `format_tool_result` | `format_tool_result()` | L2605 | 4 |
| `run_tool` | `run_tool()` | L2615 | 4 |
| `run_subagent` | `run_subagent()` | L2733 | 2 |
| `get_mcp_config_path` | `get_mcp_config_path()` | L2859 | 4 |
| `_normalize_mcp_headers` | `_normalize_mcp_headers()` | L2879 | 2 |
| `parse_mcp_config` | `parse_mcp_config()` | L2904 | 2 |
| `mcp_read_file` | `mcp_read_file()` | L2948 | 2 |
| `load_mcp_config` | `load_mcp_config()` | L2965 | 2 |
| `save_mcp_config` | `save_mcp_config()` | L3018 | 4 |
| `mcp_build_request` | `mcp_build_request()` | L3068 | 6 |
| `mcp_build_notification` | `mcp_build_notification()` | L3083 | 2 |
| `mcp_build_init_request` | `mcp_build_init_request()` | L3096 | 2 |
| `mcp_build_init_notification` | `mcp_build_init_notification()` | L3114 | 2 |
| `mcp_build_tools_list_request` | `mcp_build_tools_list_request()` | L3119 | 2 |
| `mcp_build_tools_call_request` | `mcp_build_tools_call_request()` | L3126 | 2 |
| `_mcp_extract_sse_data` | `_mcp_extract_sse_data()` | L3135 | 4 |
| `mcp_parse_response` | `mcp_parse_response()` | L3152 | 0 |
| `mcp_normalize_tool_schema` | `mcp_normalize_tool_schema()` | L3191 | 2 |
| `mcp_normalize_tool` | `mcp_normalize_tool()` | L3216 | 2 |
| `_mcp_get_curl` | `_mcp_get_curl()` | L3242 | 2 |
| `_mcp_get_cacert` | `_mcp_get_cacert()` | L3250 | 2 |
| `_mcp_quote` | `_mcp_quote()` | L3258 | 0 |
| `_mcp_prepare_headers` | `_mcp_prepare_headers()` | L3265 | 2 |
| `_mcp_write_curl_config` | `_mcp_write_curl_config()` | L3288 | 2 |
| `_mcp_extract_session_id` | `_mcp_extract_session_id()` | L3312 | 2 |
| `_mcp_format_result` | `_mcp_format_result()` | L3331 | 2 |
| `mcp_http_post` | `mcp_http_post()` | L3402 | 6 |
| `mcp_unregister_server_tools` | `mcp_unregister_server_tools()` | L3558 | 4 |
| `mcp_disconnect_server` | `mcp_disconnect_server()` | L3587 | 4 |
| `_mcp_fetch_server_tools` | `_mcp_fetch_server_tools()` | L3600 | 2 |
| `mcp_connect_server` | `mcp_connect_server()` | L3634 | 6 |
| `_mcp_format_content_item` | `_mcp_format_content_item()` | L3707 | 2 |
| `mcp_format_call_result` | `mcp_format_call_result()` | L3734 | 2 |
| `mcp_execute_tool` | `mcp_execute_tool()` | L3771 | 2 |
| `mcp_init_all` | `mcp_init_all()` | L3813 | 2 |
| `_mcp_cmd_help` | `_mcp_cmd_help()` | L3825 | 2 |
| `_mcp_cmd_list` | `_mcp_cmd_list()` | L3836 | 2 |
| `_mcp_cmd_add` | `_mcp_cmd_add()` | L3865 | 2 |
| `_mcp_cmd_remove` | `_mcp_cmd_remove()` | L3922 | 2 |
| `_mcp_cmd_refresh` | `_mcp_cmd_refresh()` | L3945 | 2 |
| `handle_mcp_command` | `handle_mcp_command()` | L3966 | 2 |
| `_has_hires_time` | `_has_hires_time()` | L4006 | 2 |
| `_hires_time` | `_hires_time()` | L4007 | 6 |
| `_debug_log` | `_debug_log()` | L4015 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L4037 | 2 |
| `_char_width` | `_char_width()` | L4048 | 6 |
| `_display_width_chars` | `_display_width_chars()` | L4061 | 6 |
| `_display_width` | `_display_width()` | L4068 | 0 |
| `_term_size` | `_term_size()` | L4080 | 4 |
| `_query_cursor_row` | `_query_cursor_row()` | L4099 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L4156 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L4224 | 2 |
| `_walk_position` | `_walk_position()` | L4265 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L4285 | 8 |
| `_md_color` | `_md_color()` | L4639 | 20 |
| `_format_link_span` | `_format_link_span()` | L4644 | 2 |
| `format_inline_markdown` | `format_inline_markdown()` | L4652 | 10 |
| `_visible_width` | `_visible_width()` | L4688 | 8 |
| `_get_markdown_term_cols` | `_get_markdown_term_cols()` | L4695 | 2 |
| `_sum_widths` | `_sum_widths()` | L4709 | 2 |
| `_lock_narrow_columns` | `_lock_narrow_columns()` | L4716 | 2 |
| `_balance_col_remainder` | `_balance_col_remainder()` | L4736 | 2 |
| `_distribute_wide_columns` | `_distribute_wide_columns()` | L4754 | 2 |
| `_allocate_table_col_widths` | `_allocate_table_col_widths()` | L4769 | 2 |
| `_update_active_sgr` | `_update_active_sgr()` | L4785 | 2 |
| `_break_long_token` | `_break_long_token()` | L4795 | 2 |
| `_wrap_words_raw` | `_wrap_words_raw()` | L4822 | 2 |
| `_wrap_table_cell` | `_wrap_table_cell()` | L4848 | 4 |
| `_split_table_row` | `_split_table_row()` | L4864 | 2 |
| `_parse_table_alignment` | `_parse_table_alignment()` | L4872 | 2 |
| `_align_cell` | `_align_cell()` | L4891 | 4 |
| `_format_table_row_cells` | `_format_table_row_cells()` | L4907 | 2 |
| `_pad_table_row` | `_pad_table_row()` | L4923 | 2 |
| `_render_wrapped_grid_row` | `_render_wrapped_grid_row()` | L4933 | 2 |
| `_collect_table_metrics` | `_collect_table_metrics()` | L4950 | 2 |
| `_resolve_card_headers` | `_resolve_card_headers()` | L4967 | 2 |
| `_render_markdown_table_cards` | `_render_markdown_table_cards()` | L4979 | 2 |
| `_max_row_cols` | `_max_row_cols()` | L5009 | 2 |
| `_assemble_grid_table` | `_assemble_grid_table()` | L5018 | 2 |
| `_render_markdown_table` | `_render_markdown_table()` | L5033 | 2 |
| `_format_header_line` | `_format_header_line()` | L5050 | 2 |
| `_format_blockquote_line` | `_format_blockquote_line()` | L5069 | 2 |
| `_format_list_line` | `_format_list_line()` | L5080 | 2 |
| `_format_block_line` | `_format_block_line()` | L5105 | 2 |
| `_format_code_block_line` | `_format_code_block_line()` | L5134 | 0 |
| `_format_code_fence_header` | `_format_code_fence_header()` | L5141 | 2 |
| `_flush_markdown_table_buf` | `_flush_markdown_table_buf()` | L5149 | 2 |
| `render_markdown` | `render_markdown()` | L5156 | 4 |
| `_init_standalone_markdown_colors` | `_init_standalone_markdown_colors()` | L5190 | 0 |
| `extract_basename` | `extract_basename()` | L5228 | 2 |
| `truncate_text` | `truncate_text()` | L5239 | 4 |
| `_format_line_range` | `_format_line_range()` | L5254 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L5269 | 4 |
| `format_tool_call` | `format_tool_call()` | L5334 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L5343 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L5353 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L5358 | 4 |
| `format_retry_status` | `format_retry_status()` | L5362 | 2 |
| `format_subagent_start` | `format_subagent_start()` | L5371 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L5380 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L5389 | 2 |
| `slow_print` | `slow_print()` | L5399 | 2 |
| `show_banner` | `show_banner()` | L5417 | 2 |
| `handle_openai_switch` | `handle_openai_switch()` | L5487 | 0 |

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
| `parse_context_size` | `parse_context_size()` | L38 | 6 |
| `format_context_size` | `format_context_size()` | L57 | 2 |
| `init_max_tokens` | `init_max_tokens()` | L73 | 2 |
| `get_max_retries` | `get_max_retries()` | L89 | 4 |
| `get_retry_delay` | `get_retry_delay()` | L97 | 4 |
| `init_retry_config` | `init_retry_config()` | L105 | 2 |
| `get_env_file_path` | `get_env_file_path()` | L114 | 8 |
| `load_env_file` | `load_env_file()` | L121 | 2 |
| `normalize_openai_endpoint` | `normalize_openai_endpoint()` | L145 | 2 |
| `save_env_vars` | `save_env_vars()` | L159 | 2 |
| `cursor_hide` | `cursor_hide()` | L227 | 6 |
| `cursor_show` | `cursor_show()` | L232 | 10 |
| `configure_provider` | `configure_provider()` | L267 | 2 |

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
| `confirm` | `confirm()` | L80 | 4 |
| `confirm_tool` | `confirm_tool()` | L87 | 4 |
| `get_subagent_tools` | `get_subagent_tools()` | L96 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L119 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L206 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L242 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L286 | 4 |
| `read_line_or_cancel` | `read_line_or_cancel()` | L293 | 2 |
| `_read_prompt_or_cancel` | `_read_prompt_or_cancel()` | L298 | 4 |
| `format_tool_result` | `format_tool_result()` | L352 | 4 |
| `run_tool` | `run_tool()` | L362 | 4 |
| `run_subagent` | `run_subagent()` | L480 | 2 |

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
| `show_banner` | `show_banner()` | L192 | 2 |
