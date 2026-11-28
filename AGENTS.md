# Agent Instructions & Codebase Guidelines

Welcome to `ppc-code-ai-agent`. This file provides essential guidelines, architecture overview, verified commands, and operating constraints for AI agents and automated tools working in this repository.

---

## 1. Project Overview
- **Repository Purpose**: Self-contained terminal AI agent designed for vintage PowerPC Macs running Mac OS X 10.4 (Tiger). It enables interactive chat and agentic tool usage (reading/writing files, executing shell commands) via Anthropic Claude, Google Gemini, or local OpenAI-compatible endpoints with zero CPAN dependencies.
- **Core Languages & Frameworks**: Perl 5.8.6 (pure Perl standard library only, no external modules), Bash / POSIX shell.
- **Primary Runtime / Environment**: Mac OS X 10.4 Tiger (PowerPC G3/G4/G5), Perl >= 5.8.6, bundled TLS 1.2/1.3 `curl` binary with OpenSSL 1.0.2u.

---

## 2. Essential Commands & Workflow

> [!IMPORTANT]
> Run all commands from the repository root unless explicitly noted.

### Build & Setup
```bash
# Assemble code-agent.pl from modular source files (src/*.pl)
perl build.pl

# Verify source-to-artifact synchronization
perl build.pl --check

# Verify Perl syntax of the standalone agent script
perl -c code-agent.pl

# Run installation workflow for PowerPC Tiger (Finder double-click or CLI)
./Install.command

# Run installation workflow for modern macOS / Linux (Finder double-click or CLI)
./modern-install.command
```

### Execution & Running
```bash
# Direct execution (with Anthropic API)
export ANTHROPIC_API_KEY="sk-ant-..."
export CLAUDE_PROVIDER="anthropic"
perl code-agent.pl

# Direct execution (with Gemini API)
export GEMINI_API_KEY="AIzaSy..."
export CLAUDE_PROVIDER="gemini"
perl code-agent.pl

# Execution with custom toolchain curl & cacert
export CLAUDE_CURL="./curl"
export CLAUDE_CACERT="./cacert.pem"
perl code-agent.pl

# Execution using saved configuration file (~/.code-agent/env)
# Launched via wrapper script:
code
# or
code-agent

# Resume an existing session via CLI flag (exact ID or unique prefix)
perl code-agent.pl --session 1128-a1b2
code --session 1128-a1b2
```

### Environment Configuration (`~/.code-agent/env`)
Credentials and runtime settings are placed in `~/.code-agent/env` (`chmod 0600`):
- `load_env_file()` in `src/header.pl` automatically parses `export KEY=VALUE` or `KEY=VALUE`.
- Precedence: Active environment variables in `%ENV` override file entries.
- Migration: Install scripts (`Install.command`, `modern-install.command`) migrate legacy `~/.code-agent-env` and `~/.claude-agent-env` into `~/.code-agent/env`.
- Key variables: `CLAUDE_PROVIDER`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_API_KEY`, `CLAUDE_MODEL`, `CLAUDE_AUTO_MODE`, `CLAUDE_AUTO_COMPACT`, `CLAUDE_COMPACT_THRESHOLD_CHARS`, `CLAUDE_COMPACT_THRESHOLD_TURNS`, `CLAUDE_SESSIONS_DIR`, `CLAUDE_MAX_SESSIONS`, `CLAUDE_SESSION_AUTO_TITLE`, `CLAUDE_CURL`, `CLAUDE_CACERT`, `CLAUDE_MCP_CONFIG`, `CLAUDE_MCP_SERVERS`.
- Interactive `/openai` (and `/local`) switching automatically normalizes base URLs (via `normalize_openai_endpoint()`) and can persist them to `~/.code-agent/env` via `save_env_vars()`.
- Remote MCP server configuration is discovered from `~/.code-agent/mcp.json`, `./mcp_servers.json`, or environment variables.

### Session Persistence & Lifecycle
- Sessions are identified by short human-friendly IDs (`MMDD-XXXX`, e.g. `1128-a1b2`) and persisted as schema-v1 JSON under `~/.code-agent/sessions/<id>.json` (`0600` permissions) with metadata cached in `~/.code-agent/sessions/index.json`.
- Automatic saving triggers after each assistant turn and upon exit. Automatic titling generates concise, descriptive titles (< 25 chars) after the first complete exchange.
- Slash commands:
  - `/sessions`: Interactive menu to browse and resume recent sessions in current directory.
  - `/sessions all`: Browse and resume recent sessions across all directories.
  - `/session <id>`: Switch directly to session by exact ID or unique case-insensitive prefix.
  - `/session delete <id>`: Delete saved session and purge from index.
- CLI startup flag: `--session <id>` (or `--session=<id>`) resumes target session immediately at startup.
- Configuration:
  - `CLAUDE_SESSIONS_DIR`: Custom directory for session storage (default: `~/.code-agent/sessions`).
  - `CLAUDE_MAX_SESSIONS`: Retention limit for saved sessions (default: `100`; oldest pruned by `updated_at`).
  - `CLAUDE_SESSION_AUTO_TITLE`: Enable/disable background LLM auto-titling (default: `1`).

### Verification & Testing
```bash
# Perl syntax check
perl -c code-agent.pl

# Verify strict Perl 5.8.6 syntax compatibility across repository
perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl build.pl scripts/check_minimum_version.pl src/*.pl

# Run full test suite
prove -I. t/*.t

# Verify context documentation integrity
python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .
```

---

## 3. Architecture & Context Navigation

For in-depth architectural details, refer to the documentation in the [`context/`](./context/) directory:

- [**context/index.md**](./context/index.md): Documentation map and quick index.
- [**context/architecture.md**](./context/architecture.md): High-level system design, subsystem relationships, and data flows.
- [**context/modules.md**](./context/modules.md): Complete module catalog with public interfaces and responsibilities.
- [**context/signatures.md**](./context/signatures.md): Searchable index of all function signatures, parameters, and return types.
- [**context/dependencies.md**](./context/dependencies.md): Internal call graphs and third-party dependencies.
- [**context/conventions.md**](./context/conventions.md): Code style, error handling patterns, and test standards.

### Key Entry Points & Core Components
| Component / File | Role | Type |
| :--- | :--- | :--- |
| [`code-agent.pl`](./code-agent.pl) | Standalone interactive CLI agent loop, JSON engine, API adapters, and tool executors | Entrypoint / Distribution Artifact |
| [`build.pl`](./build.pl) | Pure Perl 5.8.6 manifest-driven build script that compiles `src/*.pl` into `code-agent.pl` | Build Tool |
| [`src/`](./src/) | Modular source files (15 functional modules, see breakdown below) | Source Tree |
| [`scripts/check_minimum_version.pl`](./scripts/check_minimum_version.pl) | Perl 5.8.6 static syntax checker and compatibility verification tool | Verification Tool |
| [`Install.command`](./Install.command) | Interactive setup script for PowerPC Tiger (Finder and terminal, toolchain deployment, API key setup) | Installer Entrypoint |
| [`modern-install.command`](./modern-install.command) | Interactive setup script for modern macOS (Intel/Apple Silicon) and Linux | Installer Entrypoint |
| [`curl`](./curl) | Prebuilt TLS 1.2/1.3 PowerPC Tiger curl binary | Binary Utility |
| [`cacert.pem`](./cacert.pem) | Mozilla root certificate bundle for TLS verification | Security Asset |
| [`README.txt`](./README.txt) | User installation and operational manual | Documentation |

### Modular Source Layout (`src/*.pl`) & Build System
`code-agent.pl` is generated from 15 modular files in `src/` concatenated in an explicit manifest order:
1. `src/header.pl`: Pragmas, config, colors, cursor, env helpers, globals, `configure_provider`.
2. `src/prompts.pl`: System prompts (`$SYSTEM_PROMPT`), sub-agent instructions (`$SUBAGENT_PLAN_PROMPT`, `$SUBAGENT_BUILD_PROMPT`), AGENTS.md discovery and prompt composition helpers.
3. `src/json.pl`: Pure-Perl JSON parser & encoder (`MiniJSON`).
4. `src/transport.pl`: Curl invocation (`call_api`) and shell quotation (`quote`).
5. `src/providers.pl`: Provider adapters for Anthropic, Gemini, OpenAI, model discovery.
6. `src/models_menu.pl`: Interactive curses-like terminal model selection menu.
7. `src/session_store.pl`: Session persistence (schema v1), atomic JSON file writes (`0600`), rebuildable index (`index.json`), retention pruning, and exact/prefix ID resolution.
8. `src/session.pl`: Session lifecycle, state accessors, slash command handlers (`/new`, `/compact`, `/stats`, `/ctx`, `/session`, `/sessions`, LLM auto-titling).
9. `src/sessions_menu.pl`: Interactive curses-like terminal session switcher (`/sessions`, `/sessions all`), non-TTY fallback, and recent session query helpers.
10. `src/tools.pl`: Tool definitions (`@TOOLS`, including `invoke_subagent`), sub-agent runner (`run_subagent`), confirmation helpers, Gemini setup helpers, `run_tool`.
11. `src/mcp.pl`: Remote Model Context Protocol (MCP) client, JSON-RPC 2.0 protocol engine, dynamic tool discovery and registration, curl transport, and `/mcp` command handler.
12. `src/terminal.pl`: Pure-Perl interactive readline implementation with history and ANSI cursor positioning.
13. `src/markdown.pl`: Pure-Perl 5.8.6 Markdown renderer tailored for Mac OS X 10.4 Tiger `Terminal.app` (`render_markdown`, `format_inline_markdown`, ASCII tables, and standalone CLI preview mode).
14. `src/ui.pl`: Formatting helpers for tool calls, session resume summaries, sub-agent tree visuals, summaries, thinking status, and ANSI-aware `slow_print`.
15. `src/main.pl`: Guarded entrypoint under `unless (caller)` with CLI argument parsing (`--session`), session auto-saving, REPL loop, and turnaround.

#### Build Tool Usage (`build.pl`)
- `perl build.pl`: Concatenates `src/*.pl`, applies `chmod 0755`, runs `perl -c code-agent.pl`.
- `perl build.pl --check`: Non-destructive sync check; returns exit code 0 if `code-agent.pl` matches `src/`, non-zero otherwise.
- `perl build.pl --src-dir <dir>`: Custom source directory (default: `src`).
- `perl build.pl --output <file>`: Custom output artifact path (default: `code-agent.pl`).

---

## 4. Agent Rules & Operational Constraints

Follow these rules on every task:

1. **Zero External Perl Dependencies**: `code-agent.pl` MUST remain 100% self-contained in standard Perl 5.8.6. Never introduce `cpan` dependencies or modern modules (e.g., `JSON::XS`, `LWP::UserAgent`, `Mojo::*`).
2. **Mac OS X 10.4 Tiger Compatibility**: Do not use Perl features newer than 5.8.6 (avoid `state` variables, `say`, defined-or `//`, named regex captures, modern unicode properties). Compatibility is mechanically enforced in CI and verified via `scripts/check_minimum_version.pl`.
3. **Surgical Changes & Source Editing**: Touch only lines necessary for requested features or fixes. Do not reformat unrelated subroutines or comments. When modifying functionality, edit the appropriate source file in `src/*.pl` and run `perl build.pl` to regenerate `code-agent.pl`.
4. **Preserve Raw STDIN / UTF-8 Separation**: Keep STDIN as raw bytes to prevent multibyte boundary corruption in Perl 5.8.6 PerlIO. Decode explicitly at line or buffer boundaries.
5. **Preserve User Confirmations on Side Effects**: All filesystem modifications (`write_file`, `edit_file`), command executions (`run_shell`), and remote MCP tool calls (`mcp__<server>__<tool>`) MUST check user permissions via `confirm_tool()`, which respects `$AUTO_MODE` (controlled by `/auto` and `/manual` slash commands or `$ENV{CLAUDE_AUTO_MODE}`) and delegates to interactive `confirm()` when in manual mode. Outputs from remote MCP tools and file/shell executions must remain protected via untrusted output spotlighting (`<untrusted_tool_output>`). Direct user prompts (e.g. saving API keys) must continue using `confirm()`.
6. **Preserve Strict Tool Pairing During Compaction**: When managing session context and compaction (`compact_session_history`), every `tool_result` block MUST remain paired with its corresponding `tool_use_id` and retain its role in the message sequence. Never produce orphaned tool uses or results.

---

## 5. Automatic Context & Graph Maintenance (Post-Change Instruction)

> [!IMPORTANT]
> **Always Keep Context & Symbol Graphs In Sync**:
> If any code was created, modified, or deleted during your task, you MUST refresh the symbol graph and context artifacts.

Run the following update sequence:

```bash
# 1. Rescan AST and update symbol/call graphs
python3 ~/.gemini/config/skills/codebase-context-generator/scripts/ast_scanner.py --root .
python3 ~/.gemini/config/skills/codebase-context-generator/scripts/dependency_graph.py --manifest .context_cache/ast_manifest.json
python3 ~/.gemini/config/skills/codebase-context-generator/scripts/symbol_graph.py \
  --manifest .context_cache/ast_manifest.json \
  --save-graph .context_cache/symbol_graph.json \
  --export-signatures context/signatures.md

# 2. Verify documentation integrity
python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .
```
