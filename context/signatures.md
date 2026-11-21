# Codebase Signatures & Symbol Index

Quick-reference catalog of function and method signatures, arguments, and return types.

## [`code-agent.pl`](../code-agent.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L41 | 6 |
| `load_env_file` | `load_env_file()` | L51 | 2 |
| `cursor_hide` | `cursor_hide()` | L83 | 6 |
| `cursor_show` | `cursor_show()` | L88 | 10 |
| `configure_provider` | `configure_provider()` | L120 | 2 |
| `get_subagent_base_prompt` | `get_subagent_base_prompt()` | L214 | 2 |
| `get_subagent_system_prompt` | `get_subagent_system_prompt()` | L220 | 2 |
| `get_subagent_initial_prompt` | `get_subagent_initial_prompt()` | L228 | 2 |
| `get_subagent_countdown_note` | `get_subagent_countdown_note()` | L234 | 2 |
| `read_agents_file` | `read_agents_file()` | L241 | 2 |
| `get_agents_context` | `get_agents_context()` | L256 | 2 |
| `get_current_datetime_string` | `get_current_datetime_string()` | L291 | 2 |
| `get_effective_system_prompt` | `get_effective_system_prompt()` | L302 | 6 |
| `encode` | `encode()` | L327 | 20 |
| `encode_string` | `encode_string()` | L347 | 2 |
| `decode` | `decode()` | L358 | 12 |
| `_skip_ws` | `_skip_ws()` | L365 | 6 |
| `_decode_value` | `_decode_value()` | L370 | 6 |
| `_decode_object` | `_decode_object()` | L387 | 2 |
| `_decode_array` | `_decode_array()` | L409 | 2 |
| `_decode_string` | `_decode_string()` | L427 | 4 |
| `call_api` | `call_api()` | L463 | 10 |
| `quote` | `quote()` | L589 | 2 |
| `build_headers` | `build_headers()` | L603 | 4 |
| `build_request` | `build_request()` | L617 | 4 |
| `build_request_anthropic` | `build_request_anthropic()` | L626 | 2 |
| `build_request_gemini` | `build_request_gemini()` | L657 | 2 |
| `_gemini_thinking_config` | `_gemini_thinking_config()` | L718 | 2 |
| `build_request_openai` | `build_request_openai()` | L730 | 2 |
| `parse_response` | `parse_response()` | L797 | 4 |
| `parse_response_openai` | `parse_response_openai()` | L804 | 2 |
| `parse_response_anthropic` | `parse_response_anthropic()` | L836 | 2 |
| `parse_response_gemini` | `parse_response_gemini()` | L846 | 2 |
| `has_thinking_block` | `has_thinking_block()` | L887 | 2 |
| `fetch_models` | `fetch_models()` | L897 | 2 |
| `_fetch_models_anthropic` | `_fetch_models_anthropic()` | L929 | 2 |
| `_fetch_models_gemini` | `_fetch_models_gemini()` | L961 | 2 |
| `_fetch_models_openai` | `_fetch_models_openai()` | L1004 | 2 |
| `_normalize_models` | `_normalize_models()` | L1053 | 2 |
| `_select_model_nontty` | `_select_model_nontty()` | L1070 | 2 |
| `_read_menu_key` | `_read_menu_key()` | L1094 | 2 |
| `_render_menu_lines` | `_render_menu_lines()` | L1152 | 2 |
| `select_model_interactive` | `select_model_interactive()` | L1193 | 2 |
| `get_current_model` | `get_current_model()` | L1318 | 2 |
| `get_current_provider` | `get_current_provider()` | L1322 | 2 |
| `get_current_api_url` | `get_current_api_url()` | L1326 | 2 |
| `get_auto_mode` | `get_auto_mode()` | L1330 | 2 |
| `set_auto_mode` | `set_auto_mode()` | L1334 | 4 |
| `generate_session_id` | `generate_session_id()` | L1340 | 4 |
| `init_session` | `init_session()` | L1347 | 4 |
| `get_current_session` | `get_current_session()` | L1360 | 2 |
| `archive_session` | `archive_session()` | L1365 | 2 |
| `handle_new_command` | `handle_new_command()` | L1374 | 2 |
| `show_help` | `show_help()` | L1386 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L1401 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L1409 | 2 |
| `handle_models_command` | `handle_models_command()` | L1417 | 2 |
| `confirm` | `confirm()` | L1525 | 4 |
| `confirm_tool` | `confirm_tool()` | L1532 | 2 |
| `get_subagent_tools` | `get_subagent_tools()` | L1541 | 2 |
| `gemini_key_setup` | `gemini_key_setup()` | L1564 | 2 |
| `_validate_gemini_key` | `_validate_gemini_key()` | L1651 | 0 |
| `_maybe_save_gemini_key` | `_maybe_save_gemini_key()` | L1687 | 0 |
| `read_secret_or_cancel` | `read_secret_or_cancel()` | L1725 | 4 |
| `run_tool` | `run_tool()` | L1762 | 4 |
| `run_subagent` | `run_subagent()` | L1877 | 2 |
| `_debug_log` | `_debug_log()` | L2000 | 4 |
| `_utf8_char_len` | `_utf8_char_len()` | L2022 | 2 |
| `_char_width` | `_char_width()` | L2033 | 4 |
| `_display_width_chars` | `_display_width_chars()` | L2046 | 4 |
| `_display_width` | `_display_width()` | L2053 | 0 |
| `_term_size` | `_term_size()` | L2065 | 2 |
| `_query_cursor_row` | `_query_cursor_row()` | L2084 | 2 |
| `_query_cursor_pos` | `_query_cursor_pos()` | L2140 | 2 |
| `_probe_terminal_size` | `_probe_terminal_size()` | L2207 | 2 |
| `_walk_position` | `_walk_position()` | L2248 | 2 |
| `read_line_interactive` | `read_line_interactive()` | L2268 | 8 |
| `extract_basename` | `extract_basename()` | L2622 | 2 |
| `truncate_text` | `truncate_text()` | L2633 | 4 |
| `_format_line_range` | `_format_line_range()` | L2648 | 2 |
| `format_tool_summary` | `format_tool_summary()` | L2663 | 4 |
| `format_tool_call` | `format_tool_call()` | L2728 | 2 |
| `format_thinking_status` | `format_thinking_status()` | L2737 | 4 |
| `finalize_thinking_line` | `finalize_thinking_line()` | L2747 | 2 |
| `clear_thinking_line` | `clear_thinking_line()` | L2752 | 4 |
| `format_subagent_start` | `format_subagent_start()` | L2756 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L2765 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L2774 | 2 |
| `slow_print` | `slow_print()` | L2784 | 2 |
| `show_banner` | `show_banner()` | L2799 | 1 |

## [`src/header.pl`](../src/header.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `get_env_file_path` | `get_env_file_path()` | L40 | 6 |
| `load_env_file` | `load_env_file()` | L50 | 2 |
| `cursor_hide` | `cursor_hide()` | L82 | 6 |
| `cursor_show` | `cursor_show()` | L87 | 10 |
| `configure_provider` | `configure_provider()` | L119 | 2 |

## [`src/json.pl`](../src/json.pl)

### Functions & Methods
| Symbol | Signature | Line | Callers |
| :--- | :--- | :--- | :--- |
| `encode` | `encode()` | L4 | 20 |
| `encode_string` | `encode_string()` | L24 | 2 |
| `decode` | `decode()` | L35 | 12 |
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
| `generate_session_id` | `generate_session_id()` | L24 | 4 |
| `init_session` | `init_session()` | L31 | 4 |
| `get_current_session` | `get_current_session()` | L44 | 2 |
| `archive_session` | `archive_session()` | L49 | 2 |
| `handle_new_command` | `handle_new_command()` | L58 | 2 |
| `show_help` | `show_help()` | L70 | 2 |
| `handle_auto_command` | `handle_auto_command()` | L85 | 2 |
| `handle_manual_command` | `handle_manual_command()` | L93 | 2 |
| `handle_models_command` | `handle_models_command()` | L101 | 2 |

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
| `call_api` | `call_api()` | L3 | 10 |
| `quote` | `quote()` | L129 | 2 |

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
| `format_subagent_start` | `format_subagent_start()` | L137 | 2 |
| `format_subagent_tool_call` | `format_subagent_tool_call()` | L146 | 2 |
| `format_subagent_finish` | `format_subagent_finish()` | L155 | 2 |
| `slow_print` | `slow_print()` | L165 | 2 |
| `show_banner` | `show_banner()` | L180 | 1 |
