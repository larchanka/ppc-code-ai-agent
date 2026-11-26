# Implementation Plan: Session Statistics (`/stats` Command)

## Overview
Add a `/stats` slash command to `ppc-claude-agent` that displays comprehensive runtime statistics for the active session. This includes active context size (characters, estimated tokens, and message turns), context window limit (`$MAX_TOKENS`), cumulative token usage (input/prompt, output/completion, total, and API request count), tool call counts (total and breakdown by tool), sub-agent invocations, and session uptime. As required, sub-agent stats are aggregated directly into the active session totals rather than tracked separately, ensuring an accurate overview of resource consumption across the entire conversation.

## Architecture Decisions
1. **Integrated Session State (`src/session.pl`)**:
   - Embed a `stats` hash directly in `$CURRENT_SESSION` in `init_session()` containing `prompt_tokens`, `completion_tokens`, `total_tokens`, `tool_calls`, `subagents`, `tool_counts`, `subagent_counts`, and `api_calls`.
   - Provide safe accessor and mutator functions (`get_session_stats`, `record_session_tokens`, `record_session_tool_call`, `record_session_subagent`).
   - Reset stats cleanly on new session creation (`handle_new_command()`).

2. **Multi-Provider Token Usage Extraction (`src/providers.pl`)**:
   - Normalize token usage across Anthropic (`$resp->{usage}{input_tokens|output_tokens}`), OpenAI (`$resp->{usage}{prompt_tokens|completion_tokens|total_tokens}`), and Gemini (`$resp->{usageMetadata}{promptTokenCount|candidatesTokenCount|totalTokenCount}`).
   - Provide `extract_token_usage($resp)` and `record_api_response_stats($resp, $session)` to safely parse usage without dying on mock or missing data.

3. **Unified Tracking Across Main and Sub-Agents (`src/tools.pl`, `src/main.pl`)**:
   - Call `record_session_tool_call($name)` centrally in `run_tool($name, $input)` so all tool invocations (standard, MCP, and `invoke_subagent`) are tracked.
   - Call `record_session_subagent($subagent_type)` when `run_subagent` begins.
   - Record token usage after every successful `call_api` turnaround in both the main REPL loop (`src/main.pl`) and sub-agent loop (`src/tools.pl`).

4. **Pure Perl 5.8.6 Formatting & Theme Safety (`src/session.pl`)**:
   - Provide `format_session_stats($session)` and `handle_stats_command($out_fh, $session)`.
   - Use theme-safe ANSI attributes (`$COLOR_HEADER`, `$COLOR_CODE`, `$COLOR_GRAY`, `$STYLE_BOLD`, `$COLOR_RESET`) matching `show_banner`.
   - Format numbers with readable comma separators (`_commify`).
   - Format context size using `format_context_size` and character/token estimates (`estimate_session_chars`).

## Task List

### Phase 1: Foundation (Session State & Helpers)

## Task 1: Session Stats State & Accessors
**Description:** Initialize session stats structure in `init_session` and create recording helper subroutines in `src/session.pl`.

**Acceptance criteria:**
- `init_session()` creates `stats` hash with zeroed counters (`prompt_tokens`, `completion_tokens`, `total_tokens`, `tool_calls`, `subagents`, `tool_counts`, `subagent_counts`, `api_calls`).
- `get_session_stats($session)` safely retrieves or initializes `stats` for any session hash.
- `record_session_tokens($in, $out, $total, $session)` increments token and API call counters.
- `record_session_tool_call($tool_name, $session)` increments total tool count and per-tool count.
- `record_session_subagent($subagent_type, $session)` increments subagent counter and per-type count.
- Calling `handle_new_command()` archives and resets stats for the new session.

**Verification:**
- Unit tests in `t/stats_command.t` verify stats initialization, increments, and reset on `/new`.
- `perl -c src/session.pl` passes syntax check.

**Dependencies:** None
**Files likely touched:**
- `src/session.pl`
**Estimated scope:** Small (1 file)

## Task 2: Provider Token Usage Extraction
**Description:** Implement `extract_token_usage($resp)` and `record_api_response_stats($resp, $session)` in `src/providers.pl` to parse token metrics across Anthropic, OpenAI, and Gemini responses.

**Acceptance criteria:**
- `extract_token_usage` correctly extracts `input`, `output`, `total` from Anthropic `$resp->{usage}`.
- `extract_token_usage` correctly extracts `input`, `output`, `total` from OpenAI `$resp->{usage}`.
- `extract_token_usage` correctly extracts `input`, `output`, `total` from Gemini `$resp->{usageMetadata}`.
- Returns `undef` safely if `$resp` is missing usage data without raising warnings or exceptions.
- `record_api_response_stats` feeds extracted tokens to `record_session_tokens`.

**Verification:**
- Unit tests in `t/stats_command.t` verify token extraction from all 3 provider mock payloads.
- `perl -c src/providers.pl` passes syntax check.

**Dependencies:** Task 1
**Files likely touched:**
- `src/providers.pl`
**Estimated scope:** Small (1 file)

### Checkpoint: Foundation
- [x] Tests for Task 1 and Task 2 pass in `t/stats_command.t`.
- [x] Code complies with Perl 5.8.6 syntax.

---

### Phase 2: Core Execution & Aggregation

## Task 3: Instrument Tool Execution & Sub-Agent Aggregation
**Description:** Wire stats recording into `run_tool`, `run_subagent`, and API request loops so tool executions and tokens (including sub-agents) accumulate into the active session.

**Acceptance criteria:**
- `run_tool($name, $input)` in `src/tools.pl` records each tool call via `record_session_tool_call($name)`.
- `run_subagent($task, $subagent_type)` records subagent launch via `record_session_subagent($subagent_type)`.
- Sub-agent API responses record tokens to current session stats after `call_api`.
- Main agent API responses in `src/main.pl` record tokens to current session stats after `call_api`.

**Verification:**
- Unit test in `t/stats_command.t` simulating a turn and sub-agent invocation confirms aggregated tool and token totals.
- All existing tests in `t/subagents.t` and `t/tool_read_edit_file.t` continue to pass.

**Dependencies:** Task 1, Task 2
**Files likely touched:**
- `src/tools.pl`
- `src/main.pl`
**Estimated scope:** Small (2 files)

## Task 4: Implement `/stats` Command & Formatting
**Description:** Add `format_session_stats($session)` and `handle_stats_command($out_fh, $session)` in `src/session.pl`, register `/stats` in `show_help()` and `src/main.pl`.

**Acceptance criteria:**
- `format_session_stats` outputs formatted section blocks:
  - Session metadata (ID, provider/model, uptime/start time)
  - Context size (chars, estimated tokens, message count, max output tokens)
  - Cumulative token usage (prompt, completion, total, API calls)
  - Tool calls (total and tool name breakdown)
  - Sub-agents (total and type breakdown)
- Formats numbers cleanly with comma separators (`_commify`).
- `/stats` command is wired in `src/main.pl` and documented in `show_help()`.
- Supports output to any handle `$out_fh` (defaults to `STDOUT`).

**Verification:**
- Unit tests in `t/stats_command.t` check `/stats` formatting with full stats and empty stats.
- `prove -I. t/ctx_command.t t/stats_command.t` pass cleanly.

**Dependencies:** Task 3
**Files likely touched:**
- `src/session.pl`
- `src/main.pl`
- `t/stats_command.t`
**Estimated scope:** Medium (3 files)

### Checkpoint: Core Features
- [x] `/stats` command displays accurate information matching all requirements.
- [x] End-to-end integration test passes.
- [x] No regression in existing tests (`prove -I. t/*.t`).

---

### Phase 3: Build & Verification

## Task 5: Build Reassembly & Compatibility Verification
**Description:** Reassemble `code-agent.pl` via `build.pl`, verify Perl 5.8.6 syntax compatibility, and run full test suite.

**Acceptance criteria:**
- `perl build.pl` compiles cleanly and `perl build.pl --check` exits 0.
- `perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl src/*.pl` passes with 0 violations.
- `prove -I. t/*.t` runs all test suites with 100% pass rate.
- Symbol graph and context documentation are refreshed.

**Verification:**
- `prove -I. t/*.t`
- `perl build.pl --check`
- `perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl src/*.pl`

**Dependencies:** Tasks 1-4
**Files likely touched:**
- `code-agent.pl`
- `context/*`
**Estimated scope:** Small (1 file + generated artifacts)

### Checkpoint: Complete
- [x] All 5 tasks complete and verified.
- [x] Full regression suite passes cleanly.
- [x] Ready for review.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing usage metadata in mock or non-standard OpenAI endpoints | Low | Make token extraction strictly defensive (`extract_token_usage` checks hash references and returns undef if absent). |
| Multibyte string length discrepancy in context char estimates | Low | Reuse existing `estimate_session_chars` which handles both plain text and structured content blocks. |
| Sub-agent recursion or isolation issues | Low | Sub-agents run synchronously in `run_subagent` under `$CURRENT_SESSION`, so recording to `$CURRENT_SESSION->{stats}` naturally accumulates without cross-session leakage. |

## Open Questions
- None. Requirements clearly specified aggregating sub-agent token and tool stats into the main session totals.
