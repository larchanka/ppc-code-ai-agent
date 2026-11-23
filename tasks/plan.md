# Implementation Plan: Remote MCP Support (Model Context Protocol)

## Overview
Add native Remote Model Context Protocol (MCP) client support to `ppc-code-ai-agent` for Mac OS X 10.4 Tiger (PowerPC G3/G4/G5) and modern platforms, implemented in 100% standard Perl 5.8.6 with zero CPAN dependencies.

The agent will connect to remote MCP servers over HTTP/JSON-RPC 2.0 (using the bundled TLS 1.2/1.3 curl toolchain), negotiate the MCP protocol (`initialize`, `notifications/initialized`), discover remote tools via `tools/list`, dynamically register them into `@TOOLS`, and execute them via `tools/call`. Remote MCP tools will fully respect `$AUTO_MODE` confirmation rules, subagent isolation boundaries (`plan` vs `build`), and prompt injection spotlighting (`<untrusted_tool_output>`). Users can configure servers via `~/.code-agent-mcp.json` / `mcp_servers.json` / environment variables, and manage connections at runtime via a new `/mcp` slash command.

---

## Architecture Decisions

1. **Dedicated Modular File (`src/mcp.pl`)**:
   - Keep MCP logic isolated in `src/mcp.pl`, registered in `build.pl` between `src/tools.pl` and `src/terminal.pl`.
   - Conforms to the 12-file modular architecture without cluttering core tools or provider modules.

2. **Zero CPAN Dependencies & Pure Perl 5.8.6**:
   - MCP protocol framing (JSON-RPC 2.0) built on top of existing `MiniJSON` encoder/decoder.
   - HTTP transport relies on the prebuilt TLS curl binary via curl configuration files (`-K`), inheriting proxy, custom header, and SSL certificate (`cacert.pem`) capabilities.

3. **Tool Namespacing and Schema Normalization**:
   - Tools are namespaced as `mcp__<server>__<tool_name>` in `@TOOLS` to prevent name collisions with built-in tools (`read_file`, `write_file`, etc.) and across multiple servers.
   - Aliases without prefix are supported when non-conflicting.
   - Schema mapping: MCP `inputSchema` is normalized to `input_schema`, allowing seamless compatibility with Anthropic, Gemini, and OpenAI provider adapters in `src/providers.pl` without altering existing provider code.

4. **Security, Confirmation & Untrusted Output Tagging**:
   - In manual mode, all remote MCP tool calls require interactive user confirmation via `confirm_tool()`.
   - In `$AUTO_MODE` (`/auto`), confirmation is skipped.
   - MCP tool results are automatically classified under `%UNTRUSTED_OUTPUT_TOOLS`, enclosing remote output in `<untrusted_tool_output tool="...">` to prevent prompt injection attacks.
   - Subagent permissions: `build` subagents have access to remote MCP tools; `plan` subagents remain strictly read-only (`read_file`, `list_dir`).

5. **Fault Tolerance & Graceful Degradation**:
   - Failure to connect to a remote MCP server on startup prints a warning but never blocks agent startup or crashes the conversation loop.
   - Timeout for remote MCP HTTP requests is capped at 20 seconds.

6. **Interactive `/mcp` Management Command**:
   - `/mcp` / `/mcp list`: View connected servers, latency, and available remote tools.
   - `/mcp add <name> <url> [headers]`: Add and connect a new remote MCP server dynamically.
   - `/mcp remove <name>`: Disconnect a server and unregister its tools.
   - `/mcp refresh` / `/mcp reload`: Re-query `tools/list` and update registered tools.

---

## Task List

### Phase 1: Foundation — Configuration, Protocol Engine & Build Manifest

## Task 1: Build Manifest, Constants & Configuration Discovery
**Description:** Register `src/mcp.pl` in `build.pl` and `t/build.t`. Implement configuration file discovery (`~/.code-agent-mcp.json`, `mcp_servers.json`, `CLAUDE_MCP_CONFIG`, `CLAUDE_MCP_SERVERS`) and parser supporting both standard `{ "mcpServers": { ... } }` and flat server dictionaries.

**Acceptance criteria:**
- [ ] `build.pl` includes `src/mcp.pl` in `@MODULES` in manifest order.
- [ ] `t/build.t` manifest test matches the new build module list.
- [ ] `load_mcp_config()` discovers and parses server configs from file paths and environment variables.
- [ ] Invalid JSON or missing config degrades cleanly to an empty server set with no fatal errors.

**Verification:**
- [ ] Tests pass: `perl -I. t/build.t`
- [ ] Build succeeds: `perl build.pl --check`
- [ ] Unit tests pass: `perl -I. t/mcp.t` (config discovery tests)

**Dependencies:** None
**Files likely touched:**
- `build.pl`
- `src/mcp.pl`
- `t/build.t`
- `t/mcp.t`

**Estimated scope:** Medium (4 files)

---

## Task 2: Pure-Perl MCP JSON-RPC 2.0 Protocol Engine
**Description:** Implement JSON-RPC 2.0 message construction and parsing in `src/mcp.pl` for MCP `initialize`, `notifications/initialized`, `tools/list`, and `tools/call`.

**Acceptance criteria:**
- [x] `mcp_build_request($method, $params, $id)` returns valid JSON-RPC 2.0 request hash.
- [x] `mcp_build_notification($method, $params)` returns valid JSON-RPC 2.0 notification hash without id.
- [x] `mcp_parse_response($json_or_hash)` parses responses, extracting `result` or raising descriptive MCP errors on `error` payloads.
- [x] Normalizes MCP tool schemas (`inputSchema` -> `input_schema`).

**Verification:**
- [x] Tests pass: `perl -I. t/mcp.t` (protocol serialization and parsing tests)
- [x] Build succeeds: `perl -c src/mcp.pl`

**Dependencies:** Task 1
**Files likely touched:**
- `src/mcp.pl`
- `t/mcp.t`

**Estimated scope:** Small (2 files)

---

### Checkpoint: Foundation & Protocol Engine Verified
- [x] `perl -I. t/build.t` passes
- [x] `perl -I. t/mcp.t` verifies config and JSON-RPC protocol handling
- [x] `perl build.pl` compiles cleanly

---

### Phase 2: Core Vertical Slice — Remote MCP Client Transport & Tool Discovery

## Task 3: Remote MCP HTTP Transport Client
**Description:** Implement `mcp_http_post($server_info, $payload_hash)` in `src/mcp.pl` using curl config files (`-K`) with headers (`Content-Type: application/json`, `Accept: application/json`, custom auth headers, and `mcp-session-id`). Handles timeouts, network errors, and non-200 responses gracefully.

**Acceptance criteria:**
- [x] Executes POST requests using configured `$CURL` and `$CACERT`.
- [x] Passwords and API tokens in headers are passed via temporary config files (`chmod 0600`) to prevent leaking in `ps`.
- [x] Captures and parses HTTP status codes, handling 4xx/5xx errors without throwing uncaught exceptions.
- [x] Tracks `mcp-session-id` when returned by server.

**Verification:**
- [x] Tests pass: `perl -I. t/mcp.t` (mock curl transport tests)
- [x] Build succeeds: `perl -c src/mcp.pl`

**Dependencies:** Task 2
**Files likely touched:**
- `src/mcp.pl`
- `t/mcp.t`

**Estimated scope:** Small (2 files)

---

## Task 4: Server Connection Lifecycle & Dynamic Tool Registration
**Description:** Implement `mcp_connect_server($name)` and `mcp_init_all()` in `src/mcp.pl`. Executes handshake (`initialize` -> `notifications/initialized` -> `tools/list`), registers tools with namespacing (`mcp__<server>__<name>`) into `%MCP_TOOLS` and `@TOOLS`, and handles server unregistration.

**Acceptance criteria:**
- [x] Completes full MCP handshake sequence with remote endpoint.
- [x] Adds discovered tools into global `@TOOLS` array with sanitized names and descriptions.
- [x] Connection failures emit user-visible warnings without halting the application.
- [x] Disconnecting a server removes its tools from `@TOOLS` and `%MCP_TOOLS`.

**Verification:**
- [x] Tests pass: `perl -I. t/mcp.t` (lifecycle and tool registration tests)
- [x] Verification: `perl -e 'require "src/tools.pl"; require "src/mcp.pl";'` passes

**Dependencies:** Task 3
**Files likely touched:**
- `src/mcp.pl`
- `t/mcp.t`

**Estimated scope:** Medium (2 files)

---

### Checkpoint: Tool Discovery & Registration Verified
- [x] Full MCP handshake and tool discovery verified in unit tests
- [x] Dynamic `@TOOLS` manipulation verified without breaking existing tool suites

---

### Phase 3: Execution & Agent Integration — Tool Dispatch, Confirmation & Subagents

## Task 5: Tool Invocation Dispatcher, Confirmation & Output Sanitization
**Description:** Integrate MCP tool execution into `run_tool()` in `src/tools.pl`. Implement `mcp_execute_tool($tool_name, $arguments)` sending `tools/call` JSON-RPC requests, enforcing `confirm_tool()` in manual mode, formatting responses, and tagging output as untrusted.

**Acceptance criteria:**
- [x] `run_tool($name, $input)` recognizes MCP tools and routes to `mcp_execute_tool()`.
- [x] In manual mode (`!$AUTO_MODE`), prompts user confirmation: `[Confirm] Call remote MCP tool...`.
- [x] In auto mode (`$AUTO_MODE`), runs immediately without confirmation.
- [x] MCP tool outputs are registered in `%UNTRUSTED_OUTPUT_TOOLS` and sanitized with `<untrusted_tool_output>`.
- [x] `plan` subagents exclude MCP tools, while `build` subagents include them.

**Verification:**
- [x] Tests pass: `perl -I. t/mcp.t`
- [x] Tests pass: `perl -I. t/subagents.t`
- [x] Tests pass: `perl -I. t/prompt_injection.t`

**Dependencies:** Task 4
**Files likely touched:**
- `src/tools.pl`
- `src/mcp.pl`
- `t/mcp.t`
- `t/subagents.t`

**Estimated scope:** Medium (4 files)

---

## Task 6: Interactive `/mcp` Slash Command & REPL Startup Integration
**Description:** Implement `/mcp` slash command handler (`handle_mcp_command`) in `src/session.pl` / `src/mcp.pl`, update REPL loop in `src/main.pl`, update `/help` and startup banner.

**Acceptance criteria:**
- [x] `/mcp` and `/mcp list` display server statuses and tool inventories.
- [x] `/mcp add <name> <url> [headers]` adds a server and discovers its tools at runtime.
- [x] `/mcp remove <name>` unregisters a server and purges its tools from `@TOOLS`.
- [x] `/mcp refresh` or `/mcp reload` re-fetches tools from all active servers.
- [x] `/help` lists `/mcp` command.
- [x] Agent startup calls `mcp_init_all()` to connect configured servers before entering REPL.

**Verification:**
- [x] Tests pass: `perl -I. t/mcp.t`
- [x] Tests pass: `perl -I. t/models_command.t`
- [x] Manual check: verify `/help` output includes `/mcp`

**Dependencies:** Task 5
**Files likely touched:**
- `src/session.pl`
- `src/main.pl`
- `src/mcp.pl`
- `t/mcp.t`

**Estimated scope:** Medium (4 files)

---

### Checkpoint: Complete End-to-End Remote MCP Flow Verified
- [x] All 19+ existing test suites pass: `prove -l t/`
- [x] `t/mcp.t` passes 100% of tests
- [x] Standalone build `code-agent.pl` builds cleanly and passes syntax check

---

### Phase 4: Polish, Documentation & Verification

## Task 7: Codebase Context & Symbol Graphs Update
**Description:** Run build verification (`perl build.pl`, `perl build.pl --check`), execute full test suite (`prove t/`), update AST scanner, symbol graph, dependency graph, `context/signatures.md`, `AGENTS.md`, and user documentation.

**Acceptance criteria:**
- [x] `perl build.pl --check` returns 0.
- [x] Entire test suite passes (`prove -l t/`).
- [x] AST and symbol graphs refreshed via context generator scripts.
- [x] Documentation updated with remote MCP configuration and usage examples.

**Verification:**
- [x] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .` passes.

**Dependencies:** Task 6
**Files likely touched:**
- `code-agent.pl`
- `context/architecture.md`
- `context/modules.md`
- `context/signatures.md`
- `AGENTS.md`
- `README.txt`

**Estimated scope:** Medium (5 files)

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| Remote MCP server unreachable or slow | High | Enforce 20s curl timeout, warn on startup rather than crashing, keep built-in tools functional. |
| Tool name collision between servers or built-in tools | High | Namespace tools as `mcp__<server>__<tool_name>` and maintain internal lookup table `%MCP_TOOLS`. |
| Prompt injection via malicious MCP server responses | High | Register MCP tools under `%UNTRUSTED_OUTPUT_TOOLS` so responses are wrapped in `<untrusted_tool_output>`. |
| Breaking existing test suites checking `@TOOLS` in `main.pl` | High | Directly push discovered MCP tools into `@TOOLS` array, preserving the exact `build_request(..., \@TOOLS, ...)` call signature tested in `t/agents_context.t`. |
| PowerPC Tiger Perl 5.8.6 incompatibilities | Medium | Avoid modern Perl features (`//`, `state`, `say`, named captures); use only pure-Perl core standard library and curl config files. |

---

## Open Questions
- *None identified:* The MCP HTTP JSON-RPC 2.0 specification maps cleanly to the existing curl transport and `MiniJSON` infrastructure.
