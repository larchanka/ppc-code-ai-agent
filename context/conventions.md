# Engineering Conventions & Invariants

This document outlines the coding standards, environment invariants, and architectural constraints for `ppc-code-ai-agent`.

---

## 1. Code Style & Naming

### Perl Conventions
- **Language Level**: Strictly **Perl 5.8.6** compatible. Do NOT use modern Perl 5.10+ syntax:
  - Do NOT use the defined-or operator (`//`). Use `defined $var ? $var : $default` or boolean fallback `||`.
  - Do NOT use `say`. Use `print ... . "\n"`.
  - Do NOT use `state` variables. Use file-scoped `my` or package variables.
  - Do NOT use modern regex features or named captures (`(?<name>...)`).
- **Subroutine Naming**:
  - Public / workflow subroutines: `snake_case` (e.g., `configure_provider`, `call_api`, `run_tool`).
  - Internal / private helpers: `_snake_case` with leading underscore (e.g., `_decode_value`, `_walk_position`, `_char_width`).
- **Variables & Packages**:
  - Global / environment variables: `UPPER_SNAKE_CASE` (e.g., `$CURL`, `$CACERT`, `$API_KEY`, `@HISTORY`).
  - Packages / Modules: `PascalCase` (e.g., `package MiniJSON;`).
- **Formatting**:
  - Indentation: 4 spaces per indent level (no hard tabs).
  - Explicit autoflush: Keep `$| = 1;` active when using custom terminal layers so prompts flush immediately.

---

## 2. Platform Invariants (Mac OS X 10.4 Tiger)

### Zero CPAN Dependencies
All parsing, network orchestration, and terminal control must remain self-contained. Never add dependencies requiring `CPAN` or external compilation tools (e.g. do not add `JSON::XS`, `LWP::UserAgent`, or `Term::ReadLine`).

### Safe Multibyte STDIN Processing
In Perl 5.8.6, applying the `:encoding(UTF-8)` layer directly to interactive STDIN can split multibyte characters across incremental read buffer boundaries, triggering `utf8 does not map to Unicode` errors.
- **Rule**: Keep STDIN as raw bytes during interactive reads.
- **Rule**: Explicitly decode full lines or validated multibyte slices using `Encode::decode('UTF-8', $bytes, FB_DEFAULT)`.

### Vintage Display Performance
Redrawing full lines on every keystroke causes noticeable screen flicker on 800MHz–1.5GHz G4 processors.
- **Rule**: Maintain the fast-path single-character print optimization in `read_line_interactive` for end-of-line character appending.
- **Rule**: Only invoke full line redraws on cursor repositioning, line wrap, deletion, or history scrolling.

---

## 3. Error Handling Pattern

### Defensive Evaluation
- Use `eval { ... }` blocks with `$@` inspection for external operations, JSON parsing, and provider switches.
- During interactive provider switching (`/claude`, `/gemini`), catch failures without exiting the process, keeping the user in the existing session.
- Check `$!` and return clean, informative error strings from tool handlers (e.g. `Error: cannot open $path: $!`).

### Sensitive Input Handling
- Always mask or suppress terminal echo using `stty -echo` when prompting for API keys.
- Restore terminal discipline safely with `stty echo` or `system('stty', $orig_stty)`.

---

## 4. Operational Invariants & Agent Safety

### Explicit Confirmation for Mutations
Any action that alters disk contents or executes arbitrary system instructions MUST be approved by the human operator via `confirm_tool(...)`:
- `write_file`: Mandatory call to `confirm_tool("Write to file '$path'?")`.
- `edit_file`: Mandatory call to `confirm_tool("Edit file '$path' (lines $start_line-$end_line)?")`.
- `run_shell`: Mandatory call to `confirm_tool("Run this command: $command")`.
- Remote MCP tools (`mcp__<server>__<tool>`): Mandatory call to `confirm_tool("Call remote MCP tool '$tool_name'?")`.
- If the user declines, the tool must return `"Cancelled by user."` rather than throwing an exception.
- `confirm_tool(...)` respects `$AUTO_MODE` (toggled by `/auto` and `/manual` slash commands): in autonomous mode, prompts execute immediately; in manual mode, it prompts the user with `[y/N]`.
- When executed from an active sub-agent, `confirm_tool(...)` automatically tags prompts with `[Sub-agent: $type]` for user attribution.

### Prompt Injection Defense & Untrusted Output Tagging
- Outputs from all tools returning unverified external data (`read_file`, `list_dir`, `run_shell`, `invoke_subagent`, and all remote MCP tools) are wrapped via `format_tool_result()` in `<untrusted_tool_output tool="$name">...</untrusted_tool_output>` fences.
- Embedded `</untrusted_tool_output>` strings within tool outputs are escaped to `<\/untrusted_tool_output>` to prevent fence escape.

### Sub-Agent Safety & Context Isolation
- **Role Permissions**: `plan` sub-agents are strictly read-only (`read_file`, `list_dir`) and must never be granted mutation tools (`write_file`, `edit_file`, `run_shell`) or remote MCP tools. Attempts to invoke mutation tools under `plan` are rejected at runtime. `build` sub-agents have access to full tools including remote MCP tools.
- **Recursion Guard**: Sub-agents cannot invoke further sub-agents (`invoke_subagent` is excluded from sub-agent toolsets).
- **Turn Budget Limit**: Sub-agent loops are capped at a hard limit of 50 turns. The remaining turn count is injected into the initial task prompt and every subsequent tool result context (`[Turn X of 50. Turns remaining: Y]`).

---

## 5. Testing & Verification

1. **Perl Syntax Verification**:
   ```bash
   perl -c code-agent.pl
   ```
2. **Context & Link Verification**:
   ```bash
   python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .
   ```
