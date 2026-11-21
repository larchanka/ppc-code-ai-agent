# Module Catalog

This document details the modules, script architectures, subroutines, and system roles across the repository.

---

## 1. Module: `code-agent.pl`

### Overview
The primary executable for the PowerPC AI agent. It is a single, self-contained Perl script designed to run on Perl 5.8.6 under Mac OS X 10.4 Tiger without any CPAN dependencies.

### Packages & Namespaces

#### Package `MiniJSON` (Lines 134–270)
A recursive-descent JSON parser and encoder tailored for standard Perl scalars, arrays, and hashes.
- `MiniJSON::encode($value)`: Encodes a Perl reference or scalar into JSON text.
- `MiniJSON::encode_string($str)`: Escapes quotes, backslashes, control characters, and Unicode sequences.
- `MiniJSON::decode($json_text)`: Decodes JSON text into Perl data structures.
- `MiniJSON::_skip_ws($str_ref, $pos_ref)`: Advances index past whitespace.
- `MiniJSON::_decode_value($str_ref, $pos_ref)`: Identifies token type (string, object, array, boolean, number, null).
- `MiniJSON::_decode_object($str_ref, $pos_ref)`: Parses JSON key-value mappings.
- `MiniJSON::_decode_array($str_ref, $pos_ref)`: Parses JSON arrays.
- `MiniJSON::_decode_string($str_ref, $pos_ref)`: Parses escaped JSON strings into Perl strings.

---

### Core Subroutines in `main`

#### Provider Management & Setup
- `configure_provider($provider)`: Configures `$API_KEY`, `$MODEL`, `$API_URL`, and `$ANTHROPIC_VERSION` for `anthropic`, `gemini`, or `openai`.
- `get_env_file_path()`: Resolves the environment file path, preferring `~/.code-agent-env` with fallback to `~/.claude-agent-env`.
- `load_env_file([$file])`: Loads environment variables from the environment file if not already set in `%ENV`.
- `gemini_key_setup()`: Interactive CLI wizard guiding users through setting up a free Google AI Studio key.
- `_validate_gemini_key($key)`: Performs a lightweight test query to verify validity.
- `_maybe_save_gemini_key($key)`: Prompts the user to save credentials to `~/.code-agent-env`.
- `read_secret_or_cancel($prompt)`: Prompts for sensitive input with echo disabled, supporting cancel via Escape or Ctrl+C.
- `get_current_model()`: Returns active `$MODEL`.
- `get_current_provider()`: Returns active `$PROVIDER`.
- `get_current_api_url()`: Returns active `$API_URL`.
- `init_retry_config()`: Initializes `$MAX_RETRIES` (default `3`) and `$RETRY_DELAY` (default `5`) from `CLAUDE_MAX_RETRIES` and `CLAUDE_RETRY_DELAY`.
- `get_max_retries()`: Returns effective maximum retry count (`>= 0`).
- `get_retry_delay()`: Returns effective retry delay in seconds (`>= 0`).

#### Model Discovery & Selection
- `fetch_models($provider)`: Dispatches to provider-specific fetchers and returns normalized `($models_ref, $error)`.
- `_fetch_models_anthropic()`: Queries Anthropic GET `/v1/models?limit=100` and extracts model descriptors.
- `_fetch_models_gemini()`: Queries Gemini GET `/v1beta/models?pageSize=100`, filters for `generateContent` support, and strips `models/` prefix.
- `_fetch_models_openai()`: Queries OpenAI-compatible GET `<base>/models` and extracts IDs.
- `_normalize_models($models_ref)`: Normalizes model array into uniform `[{ id => "...", display => "..." }]` structures.
- `select_model_interactive($models_ref, $current_model, $in_fh, $out_fh)`: Interactive full-terminal or non-TTY fallback selector with arrow keys, direct numeric typing, Enter to confirm, and Esc/Ctrl+C to cancel.
- `_select_model_nontty($models_ref, $current_model, $in_fh, $out_fh)`: Numbered model selector fallback for non-interactive or piped streams.
- `_read_menu_key($in_fh)`: Reads single keypress in raw mode with 50ms escape sequence disambiguation (Esc vs Arrow keys).
- `_render_menu_lines($models, $cursor, $window_start, $page_size, $current_model, $num_buf)`: Formats paginated windowed model list and status line for terminal rendering.
- `handle_models_command($in_fh, $out_fh)`: Command handler for `/models` slash command, coordinating fetch, selection, and model switching.
- `show_help($out_fh)`: Displays available slash commands and descriptions.
- `handle_auto_command($out_fh)`: Command handler for `/auto` slash command, setting `$AUTO_MODE = 1` and printing confirmation.
- `handle_manual_command($out_fh)`: Command handler for `/manual` slash command, setting `$AUTO_MODE = 0` and printing confirmation.
- `get_auto_mode()`: Returns current autonomous mode status (`0` or `1`).
- `set_auto_mode($val)`: Sets `$AUTO_MODE` (`1` if truthy, `0` otherwise) and returns the normalized value.

#### Session Management & Lifecycle
- `generate_session_id()`: Generates unique timestamped session IDs (`session-YYYYMMDD-HHMMSS-NNN`) via monotonic counter and `localtime`.
- `init_session([$id])`: Creates and sets `$CURRENT_SESSION` with metadata (`id`, `created_at`, `provider`, `model`) and a fresh empty `messages` arrayref.
- `get_current_session()`: Returns active `$CURRENT_SESSION`, lazily calling `init_session()` if undefined.
- `archive_session($session)`: Lifecycle extension hook for future persistence / session resume before resetting context.
- `handle_new_command($out_fh, $session)`: Command handler for `/new` slash command; archives existing session, initializes a fresh session, and prints confirmation.

#### Context & Instruction Management
- `read_agents_file($path)`: Reads an `AGENTS.md` file safely, decoding UTF-8 and returning empty string on missing, unreadable, or non-regular files.
- `get_agents_context([$home_dir, $cwd])`: Discovers global (`~/.agents/AGENTS.md`) and local (`./AGENTS.md`) instructions, deduplicating identical files via device/inode check, and formats them into labeled markdown sections.
- `get_effective_system_prompt([$base_prompt, $home_dir, $cwd])`: Composes base system prompt with discovered `AGENTS.md` instructions, returning base prompt unchanged if no instructions exist.

#### Request & Response Construction
- `build_headers()`: Returns array of HTTP headers tailored to current provider (e.g. `x-api-key`, `anthropic-version`, `x-goog-api-key`, `Authorization`).
- `build_request($messages_ref, $tools_ref, $system_prompt)`: Dispatches to provider-specific request builder.
- `build_request_anthropic($messages_ref, $tools_ref, $system)`: Translates conversation history into Anthropic Messages API v1 format.
- `build_request_gemini($messages_ref, $tools_ref, $system)`: Translates history and tool declarations into Google Gemini `generateContent` format.
- `_gemini_thinking_config()`: Configures reasoning budget / thinking level for Gemini 3.x models.
- `build_request_openai($messages_ref, $tools_ref, $system)`: Formats request for OpenAI-compatible chat completions endpoints.
- `parse_response($response_json)`: Decodes provider response into uniform text or tool-call structures.
- `parse_response_anthropic($data)`: Extracts text and `tool_use` blocks from Anthropic API responses.
- `parse_response_gemini($data)`: Extracts text candidates and `functionCall` items from Gemini responses.
- `parse_response_openai($data)`: Extracts messages and `tool_calls` from OpenAI responses.

#### Interactive Terminal Engine & ANSI Helpers
- `read_line_interactive($prompt)`: Full raw-mode terminal reader with ANSI line editing, history, wrapping, and multibyte UTF-8 handling.
- `_probe_terminal_size()`: Determines column and row bounds using ioctl or escape sequences.
- `_term_size()`: Fallback terminal dimension detector.
- `_query_cursor_pos()` / `_query_cursor_row()`: Issues VT100 DSR `\e[6n` query to track actual cursor location.
- `_walk_position($text, $cols)`: Simulates cursor wrap mechanics across terminal columns.
- `_char_width($codepoint)`: East Asian Width calculation for proper double-width character layout.
- `_display_width($str)` / `_display_width_chars(@chars)`: Calculates visual column footprint of strings.
- `_utf8_char_len($byte)`: Inspects leading UTF-8 byte to determine expected continuation length.

#### UI Formatting & Visuals
- `show_banner($out_fh)`: Renders retro two-tone ASCII art startup banner ("Code" in yellow, "Agent" in magenta) with active provider, model, and mode status indicators.
- `format_tool_call($name, $input)`: Formats tool invocation lines with ANSI colors and compact argument summaries.
- `format_tool_summary($name, $input)`: Produces concise, human-readable summaries of tool parameters (e.g. truncated file paths or commands).
- `format_subagent_start($subagent_type, $task)`: Formats indented sub-agent invocation header with Cyan ANSI tree brackets.
- `format_subagent_tool_call($subagent_type, $turn, $max_turns, $name, $input)`: Formats indented sub-agent tool call with turn countdown indicators (`[Turn X/50]`).
- `format_subagent_finish($subagent_type, $turns, $status)`: Formats indented sub-agent completion footer.
- `format_thinking_status($elapsed)`: Formats active reasoning/thinking progress indicator with elapsed timer.
- `format_retry_status($retry_num, $max_retries, $delay)`: Formats transient API error retry countdown indicator (`* API error, retrying in Xs (N/M)...`).
- `finalize_thinking_line($elapsed)`: Replaces active progress with final thinking duration.
- `clear_thinking_line()`: Clears transient thinking line via carriage return and ANSI line clear (`\r\033[K`).
- `slow_print($text)`: Prints output with simulated typewriter delay for vintage terminal ambiance.

#### Network & Tool Execution
- `_call_api_once($url, $headers_ref, $body_json, $method)`: Executes a single HTTP request via bundled `curl` with SSL certificate bundle, decodes JSON, and checks for HTTP non-2xx status or provider error objects.
- `call_api($url, $headers_ref, $body_json, $method)`: Wraps `_call_api_once` with automatic retry logic up to `get_max_retries()` times (default 3 retries) waiting `get_retry_delay()` seconds (default 5s) between attempts.
- `confirm($prompt)`: Displays an interactive `[y/N]` prompt requiring affirmative user consent.
- `confirm_tool($prompt)`: Tool permission gate returning `1` if `$AUTO_MODE` is enabled, or delegating to `confirm($prompt)` in manual mode (prefixed with `[Sub-agent: $type]` when invoked under a sub-agent).
- `run_tool($name, $input)`: Executes requested agent tools (`read_file`, `write_file`, `edit_file`, `list_dir`, `run_shell`, `invoke_subagent`), gating side effects through `confirm_tool()`.
- `get_subagent_tools($type)`: Returns filtered tool list for sub-agents (`plan`: strictly read-only `read_file` and `list_dir`; `build`: full tools excluding recursive `invoke_subagent`).
- `run_subagent($task, $subagent_type)`: Executes synchronous turn-based sub-agent loop up to 50 turns with isolated conversation session, turn countdown context injection, and visual tree formatting.

#### Prompts & Context Loading (`src/prompts.pl`)
- `$SYSTEM_PROMPT`: Default system prompt for the primary agent loop.
- `$SUBAGENT_PLAN_PROMPT`: Default prompt for the read-only planning sub-agent.
- `$SUBAGENT_BUILD_PROMPT`: Default prompt for the implementation build sub-agent.
- `get_subagent_base_prompt($type)`: Returns the base prompt template for `plan` or `build`.
- `get_subagent_system_prompt($type, $max_turns)`: Composes sub-agent system prompt with turn budget and `AGENTS.md` context.
- `get_subagent_initial_prompt($task, $max_turns)`: Constructs the initial task prompt with turn countdown metadata.
- `get_subagent_countdown_note($turn, $max_turns, $turns_left)`: Generates turn countdown reminder injected into tool results.
- `read_agents_file($path)`: Reads and UTF-8 decodes instructions file safely.
- `get_agents_context($home_dir, $cwd)`: Discovers and formats global (`~/.agents/AGENTS.md`) and local (`./AGENTS.md`) instructions.
- `get_effective_system_prompt($base_prompt, $home_dir, $cwd)`: Composes base system prompt with discovered context.

---

## 2. Module: `build.pl`

### Overview
A manifest-driven assembly script written in pure Perl 5.8.6 with zero CPAN dependencies. It concatenates the 11 domain modules from `src/` into the standalone `code-agent.pl` distribution artifact, applies `chmod 0755`, and validates syntax via `perl -c`.

### Command Line Interface
- `perl build.pl`: Concatenates `src/*.pl` in manifest order, writes `code-agent.pl`, and verifies syntax.
- `perl build.pl --check`: Compares current `code-agent.pl` against `src/` modules without modifying disk, returning exit code 0 if in sync or non-zero if out of sync.
- `perl build.pl --src-dir <dir>`: Sets custom source directory.
- `perl build.pl --output <file>`: Sets custom output file.

### Ordered Assembly Manifest
1. `src/header.pl`: Pragmas, UTF-8 binmode, constants, colors, cursor helpers, env helpers, globals, `configure_provider`, `$SYSTEM_PROMPT`.
2. `src/json.pl`: Pure-Perl JSON parser and encoder (`MiniJSON`).
3. `src/transport.pl`: Curl invocation (`call_api`) and shell quotation (`quote`).
4. `src/providers.pl`: Provider-specific header/request builders, response parsers, model discovery.
5. `src/models_menu.pl`: Interactive curses-like terminal model selector.
6. `src/session.pl`: Session management, state accessors, slash command handlers.
7. `src/tools.pl`: Tool definitions (`@TOOLS`), confirmation helpers, Gemini setup helpers, `run_tool` dispatcher.
8. `src/terminal.pl`: Pure-Perl interactive readline engine with history and ANSI cursor positioning.
9. `src/ui.pl`: Formatting helpers for tool summaries, tool calls, and thinking status.
10. `src/main.pl`: Guarded entrypoint under `unless (caller)` with REPL loop and turnaround.

---

## 3. Module: `Install.command`

### Overview
A standalone Bash script providing one-click installation on Mac OS X 10.4 Tiger.

### Key Operations
1. **Toolchain Installation**: Copies `curl` to `$HOME/code-toolchain/bin/curl` and sets executable permissions.
2. **Build from Source**: Automatically executes `perl build.pl` if `build.pl` and `src/` are present before copying to the build directory.
3. **Runtime Deployment**: Copies `code-agent.pl` and `cacert.pem` to `$HOME/code-build/`.
4. **Curl Verification**: Executes `curl --version` to verify PowerPC CPU and kernel compatibility.
5. **Interactive Provider Selection**: Guides user to choose Anthropic or Gemini, prompts for API key without echo, and writes `~/.code-agent-env` with permissions `0600`.
6. **Launcher Wrapper**: Generates `$HOME/bin/code`, which sources the environment and launches `code-agent.pl`.
7. **Path Configuration**: Updates `$HOME/.bash_profile` with `$HOME/bin` if not already present.
8. **End-to-End Connectivity Verification**: Makes a test HTTP request to verify API keys and network connectivity before concluding setup.

---

## 4. Module: `modern-install.command`

### Overview
A Bash installation script tailored for modern macOS (Intel and Apple Silicon) and Linux environments.

### Key Operations
1. **Host Environment Checks**: Verifies availability of system `perl` and TLS-capable `curl`.
2. **Build from Source**: Executes `perl build.pl` if `build.pl` and `src/` are present.
3. **Runtime Deployment**: Copies `code-agent.pl` and `cacert.pem` to `$HOME/code-build/`.
4. **Interactive Provider Selection**: Configures Anthropic or Gemini keys securely in `~/.code-agent-env` (`0600` permissions).
5. **Launcher Wrappers**: Generates `$HOME/bin/code-agent` and symlinks `$HOME/bin/code` (checking for conflicts with VS Code).
6. **Shell Profile Configuration**: Updates `~/.zshrc`, `~/.bashrc`, and/or `~/.bash_profile` based on active shell and OS platform.
7. **End-to-End Connectivity Verification**: Verifies API keys against Anthropic or Google Gemini endpoints.

---

## 5. Supplementary Assets

| File | Purpose |
| :--- | :--- |
| [`curl`](../curl) | PowerPC Darwin executable, statically linked against OpenSSL 1.0.2u supporting TLS 1.2 and 1.3 |
| [`cacert.pem`](../cacert.pem) | Mozilla CA certificate bundle required for HTTPS verification |
| [`README.txt`](../README.txt) | Plain-text end-user guide for setup and requirements |
