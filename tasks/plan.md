# Implementation Plan: `/stats` Session Statistics Command

## Overview
Implement the `/stats` slash command in `code-agent.pl` to display comprehensive, live session metrics. This command gives users immediate visibility into session lifetime, turns, token consumption (input, output, cache read/write) across Anthropic, Gemini, and OpenAI providers, tool execution counts (per-tool breakdown), context size, and context compaction savings.

## Architecture Decisions
- **Unified Usage Extraction (`extract_api_usage`)**: Normalize token usage extraction across disparate provider response payloads (Anthropic `usage`, Gemini `usageMetadata`, OpenAI `usage`) into a standard hash format (`input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`).
- **Session-Bound Accumulation**: Embed the `stats` metrics container directly inside `$CURRENT_SESSION` (`id`, `created_at`, `provider`, `model`, `messages`, `stats`). When `/new` starts a fresh conversation, stats cleanly reset automatically with the new session.
- **Graceful Fallback**: All stats helper functions (`get_session_stats`, `record_session_api_usage`, `record_session_tool_call`) lazily initialize `$session->{stats}` if missing, ensuring backward compatibility with external scripts, tests, or legacy session instances.
- **Sub-agent Activity Accounting**: Accumulate API calls, tokens, and tool executions from sub-agents (`invoke_subagent`) into `$CURRENT_SESSION->{stats}` while tracking sub-agent invocation count.
- **PowerPC / VT100 Ergonomics**: Render statistics using theme-safe ANSI attributes (`$COLOR_HEADER`, `$COLOR_CODE`, `$COLOR_DIM`, `$COLOR_RESET`) matching `src/ui.pl` and `src/header.pl`, degrading cleanly to plain text when `NO_COLOR` is set or stdout is non-interactive.
- **Zero CPAN Dependencies**: All formatting (time duration, comma-separated numbers, text alignment) uses pure Perl 5.8.6 standard library functions.

---

## Task List

### Phase 1: Foundation (Data Modeling & Usage Extraction)

## Task 1: Session Stats Data Structure & Provider Token Extraction
**Description:** Initialize the `stats` field inside `init_session()` in `src/session.pl` and implement `extract_api_usage($resp, $provider)` and `record_session_api_usage($resp, $session, $provider)` in `src/providers.pl` / `src/session.pl`.
**Acceptance criteria:**
- `init_session()` creates `stats` hash with `api_calls`, `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens`, `tool_calls`, `subagent_calls`, `compact_count`, `bytes_saved`.
- `extract_api_usage()` extracts tokens correctly from Anthropic (`usage`), Gemini (`usageMetadata`), and OpenAI (`usage`) payloads.
- `record_session_api_usage()` increments `api_calls` and accumulates token counts into `$session->{stats}`.
- Gracefully handles missing usage fields or legacy session objects without existing `stats`.
**Verification:**
- Unit tests verify extraction against sample responses for all three providers.
**Dependencies:** None
**Files likely touched:**
- `src/session.pl`
- `src/providers.pl`
**Estimated scope:** Small (2 files)

---

## Task 2: Live Activity & Tool Call Tracking
**Description:** Implement `record_session_tool_call($tool_name, $session)` and hook API usage and tool invocation tracking into the main conversation loop in `src/main.pl`, subagent runner in `src/tools.pl`, and context compactor in `src/session.pl`.
**Acceptance criteria:**
- Every executed tool call in `src/main.pl` calls `record_session_tool_call($name, $session)`.
- Every successful API call in `src/main.pl` calls `record_session_api_usage($resp, $session)`.
- `compact_session_history()` records compacted items and bytes saved in `$session->{stats}`.
- `run_subagent()` records subagent API usage, tool calls, and subagent invocation counts into `$CURRENT_SESSION`.
**Verification:**
- Verified that executing tools and API calls increments session stats counters.
**Dependencies:** Task 1
**Files likely touched:**
- `src/session.pl`
- `src/main.pl`
- `src/tools.pl`
**Estimated scope:** Medium (3 files)

---

### Checkpoint: Foundation
- [ ] Session data model tracks tokens, tool calls, API calls, and compactions accurately.
- [ ] Unit tests pass for tracking mechanisms.

---

### Phase 2: Core Feature (`/stats` Command & Formatting)

## Task 3: Formatting Engine & `handle_stats_command`
**Description:** Implement duration formatting (`format_duration`), number formatting (`format_number_comma`), turns calculation, and `format_session_stats($session)`. Implement `handle_stats_command($out_fh, $session)` to print the formatted report.
**Acceptance criteria:**
- `format_duration($seconds)` cleanly formats seconds, minutes, and hours (e.g. `14s`, `3m 22s`, `1h 15m 0s`).
- `format_number_comma($num)` formats integers with comma thousands separators (e.g. `12,345`).
- `format_session_stats()` outputs:
  - Header with Session ID, Provider, Model, and Duration with start timestamp.
  - Activity section: User turns, Assistant turns, Total messages, API calls, estimated Context size.
  - Token Usage section: Input tokens, Output tokens, Total tokens (and Cache read/write if non-zero).
  - Tool Invocations section: Total tool calls and alphabetical breakdown per tool.
  - Compaction section (if any compactions occurred).
- Theme-safe ANSI colors used when active, plain text when colors disabled.
- `handle_stats_command()` defaults to `\*STDOUT` and `$CURRENT_SESSION`.
**Verification:**
- Unit tests verify formatting output against known session state.
**Dependencies:** Task 1, Task 2
**Files likely touched:**
- `src/session.pl`
**Estimated scope:** Small (1 file)

---

## Task 4: CLI Command Dispatch & Help Documentation
**Description:** Wire `/stats` into the interactive command loop in `src/main.pl` and update `show_help()` in `src/session.pl`.
**Acceptance criteria:**
- Typing `/stats` in the main loop executes `handle_stats_command()`.
- `show_help()` lists `/stats` with concise description: `View current session statistics (duration, tokens, turns, tools)`.
- Typing `/new` resets stats and starts a new session whose `/stats` shows 0 tokens and clean counters.
**Verification:**
- Running simulated interactive input `/stats\nexit\n` dispatches command and outputs stats.
- `show_help()` output includes `/stats`.
**Dependencies:** Task 3
**Files likely touched:**
- `src/main.pl`
- `src/session.pl`
**Estimated scope:** Small (2 files)

---

### Checkpoint: Core Features
- [ ] Typing `/stats` in interactive CLI prints session stats.
- [ ] `/help` documents `/stats`.
- [ ] `/new` resets stats for fresh conversation.

---

### Phase 3: Integration, Documentation & Verification

## Task 5: Comprehensive Test Suite (`t/stats_command.t`)
**Description:** Author a complete test suite `t/stats_command.t` covering unit tests, provider usage extraction, formatting, command handling, and integration with the interactive conversation loop.
**Acceptance criteria:**
- Tests `init_session` stats structure.
- Tests `extract_api_usage` with Anthropic, Gemini, OpenAI mock responses.
- Tests tool call recording and turn counting.
- Tests `format_duration`, `format_number_comma`, and `format_session_stats`.
- Tests `handle_stats_command` filehandle redirection.
- Tests reset on `handle_new_command`.
- Tests interactive loop execution via mock curl and pipe.
**Verification:**
- `prove -v t/stats_command.t` passes with 100% success.
**Dependencies:** Tasks 1-4
**Files likely touched:**
- `t/stats_command.t`
**Estimated scope:** Small (1 file)

---

## Task 6: Documentation & Build Assembly Synchronization
**Description:** Update `README.md` and `README.txt` with `/stats` documentation. Rebuild `code-agent.pl` with `build.pl` and verify syntax and full test suite.
**Acceptance criteria:**
- `README.md` command table and feature list include `/stats`.
- `README.txt` includes `/stats`.
- `perl build.pl` regenerates `code-agent.pl` cleanly with syntax OK.
- `perl build.pl --check` confirms source synchronization.
- All tests in `t/` pass.
**Verification:**
- `perl build.pl --check` exits 0.
- `prove t/*.t` all pass.
**Dependencies:** Tasks 1-5
**Files likely touched:**
- `README.md`
- `README.txt`
- `code-agent.pl`
**Estimated scope:** Small (3 files)

---

### Checkpoint: Complete
- [ ] All 6 tasks completed and checked off.
- [ ] Full test suite passes.
- [ ] Ready for review.

---

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Provider response format changes or missing `usage` | Low | Use defensive hash navigation with `defined` checks and fallbacks to 0 tokens. |
| Existing tests creating manual session hashes without `stats` | Medium | `get_session_stats()` and mutators auto-vivify `$session->{stats}` if undefined. |
| Overhead of stats accumulation on vintage PowerPC CPUs | Low | Increments are simple O(1) integer arithmetic; string formatting only occurs when `/stats` is invoked. |
| Sub-agent recursion or isolation | Low | Sub-agents mutate `$CURRENT_SESSION->{stats}` or inherit parent session reference safely. |

## Open Questions
- None. Requirements are clear and follow existing slash command patterns (`/new`, `/ctx`, `/compact`).
