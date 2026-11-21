# Implementation Plan: LLM API Call Retry Mechanism

Implement automatic retry behavior for LLM API calls in `code-agent.pl` (`src/transport.pl`), retrying failed requests up to a maximum of 3 retries (4 total attempts) with a 5-second delay between retries.

---

## Overview

Network connections on vintage PowerPC Macs running Mac OS X 10.4 Tiger (or transient provider API errors/rate limits such as HTTP 429, 500, 502, 503, 529, connection drops, or malformed/error payloads) can intermittently fail during multi-turn conversations or sub-agent delegations. Currently, `call_api` in `src/transport.pl` immediately `die`s on any non-2xx HTTP status or JSON decoding failure, aborting the active turn or sub-agent run.

This feature introduces a resilient retry mechanism around LLM API requests:
1. **Default Policy**: Maximum **3 retries** (`$MAX_RETRIES = 3`, i.e. 1 initial attempt + up to 3 retry attempts) with a **5-second** wait (`$RETRY_DELAY = 5`) between retries.
2. **Configurable Overrides**: Support environment variables `CLAUDE_MAX_RETRIES` (default `3`) and `CLAUDE_RETRY_DELAY` (default `5`) so users can tune behavior and automated tests can run hermetically with `0` delay.
3. **Transport-Level Integration**: Implement retry logic inside `call_api` in `src/transport.pl` (via a single-attempt helper `_call_api_once`), automatically covering both main conversation turns (`src/main.pl`), sub-agent turns (`src/tools.pl`), and model discovery calls (`src/providers.pl`).
4. **Provider-Level Error Payload Detection**: Ensure JSON responses containing a top-level `{ "error": ... }` object or `{ "type": "error" }` (even if returned with HTTP 200 by an upstream proxy or local OpenAI server) are detected and eligible for retry.
5. **Visual Terminal Feedback**: Display a clear, non-cluttering retry status message during the wait interval when running interactively (and clean up thinking timer lines properly).

---

## Architecture Decisions

### 1. Where to Perform Retries (`src/transport.pl`)
- **Single-Attempt Helper (`_call_api_once`)**: Extract the single HTTP request execution and response decoding logic of `call_api` into `_call_api_once($url, $headers, $body_json, $method)`.
- **Retry Wrapper (`call_api`)**: `call_api($url, $headers, $body_json, $method)` orchestrates the retry loop:
  - Reads max retries via `get_max_retries()` (checks `$ENV{CLAUDE_MAX_RETRIES}`, defaults to `$MAX_RETRIES = 3`, clamped to `>= 0`).
  - Reads retry delay via `get_retry_delay()` (checks `$ENV{CLAUDE_RETRY_DELAY}`, defaults to `$RETRY_DELAY = 5`, clamped to `>= 0`).
  - Loops `$attempt` from `0` to `$max_retries`:
    - Calls `my $resp = eval { _call_api_once($url, $headers, $body_json, $method) };`
    - Also checks if `$resp` is a hashref containing an explicit error object (`$resp->{error}` or `($resp->{type} && $resp->{type} eq 'error')`) and converts that into a `die "API error: ...\n"` so provider-level errors are caught uniformly.
    - If no error (`!$@`), returns `$resp` immediately.
    - If an error occurred and `$attempt < $max_retries`:
      - Displays retry notification / countdown on TTY (or dim status notification) and waits `$retry_delay` seconds (using `select(undef, undef, undef, $retry_delay)` when `$retry_delay > 0`).
    - If `$attempt == $max_retries` (all retries exhausted), re-throws `die $err`.

### 2. Why `select(undef, undef, undef, $delay)` for Delay
- Perl 5.8.6 standard `sleep()` only accepts integer seconds, whereas `select(undef, undef, undef, $delay)` supports both integer seconds (like `5`) and fractional seconds (like `0.01` in tests) without requiring `Time::HiRes` or external CPAN modules. This pattern is already established across `src/transport.pl` and `src/ui.pl`.
- When `$retry_delay == 0` (e.g., in unit tests with `CLAUDE_RETRY_DELAY=0`), no sleep is performed, keeping test execution instantaneous.

### 3. Configuration & Environment Variables (`src/header.pl`)
- Define globals in `src/header.pl`:
  - `our $MAX_RETRIES = defined $ENV{CLAUDE_MAX_RETRIES} ? int($ENV{CLAUDE_MAX_RETRIES}) : 3;`
  - `our $RETRY_DELAY = defined $ENV{CLAUDE_RETRY_DELAY} ? ($ENV{CLAUDE_RETRY_DELAY} + 0) : 5;`
- Provide accessors in `src/transport.pl` (or `src/header.pl`):
  - `get_max_retries()`: Returns `$ENV{CLAUDE_MAX_RETRIES}` if defined, else `$MAX_RETRIES` (default 3).
  - `get_retry_delay()`: Returns `$ENV{CLAUDE_RETRY_DELAY}` if defined, else `$RETRY_DELAY` (default 5).
- Update `load_env_file()` in `src/header.pl` so that if `CLAUDE_MAX_RETRIES` or `CLAUDE_RETRY_DELAY` is loaded from `~/.code-agent-env`, `$MAX_RETRIES` and `$RETRY_DELAY` are initialized accordingly.

### 4. UI & Thinking Line Interaction (`src/ui.pl` & `src/transport.pl`)
- Add `format_retry_status($attempt, $max_retries, $delay, $err)` in `src/ui.pl`:
  - Formats a concise, single-line dim warning/status (e.g., `* API error, retrying in 5s (attempt 1/3)...`).
  - When `$is_tty && $has_body`, prints `\r\033[K` followed by the retry status line before waiting, so the live `* Thinking Xs...` line is cleanly replaced during the 5-second pause and then resumes ticking on the next attempt.

### 5. Mock Curl Enhancement for Multi-Attempt Testing (`t/mock_curl.pl`)
- Enhance `t/mock_curl.pl` (or support sequence files via `$ENV{MOCK_CURL_SEQUENCE_FILE}`) so unit tests can simulate transient failures (e.g., attempt 1 returns HTTP 500, attempt 2 returns HTTP 503, attempt 3 returns HTTP 200 OK) as well as persistent failures (attempts 1..4 all fail).
- Keep 100% backward compatibility with existing `MOCK_CURL_HTTP_CODE` and `MOCK_CURL_RESPONSE` single-shot tests.

---

## Dependency Graph

```
src/header.pl ($MAX_RETRIES, $RETRY_DELAY, get_max_retries, get_retry_delay)
    │
    ├── src/ui.pl (format_retry_status)
    │       │
    │       └── src/transport.pl (_call_api_once + retry loop in call_api)
    │               │
    │               ├── src/main.pl (main REPL LLM calls)
    │               ├── src/tools.pl (run_subagent LLM calls)
    │               └── src/providers.pl (fetch_models API calls)
    │
    └── t/mock_curl.pl & t/call_api.t (hermetic retry test suite)
```

---

## Task List

### Phase 1: Configuration, UI Helper, and Transport Retry Logic

## Task 1: Retry Configuration & UI Status Formatter
**Description:** Add retry configuration defaults (`$MAX_RETRIES = 3`, `$RETRY_DELAY = 5`) and accessor helpers in `src/header.pl`, and add `format_retry_status` in `src/ui.pl`.

**Acceptance criteria:**
- [ ] `our $MAX_RETRIES = 3` and `our $RETRY_DELAY = 5` declared in `src/header.pl`.
- [ ] `get_max_retries()` and `get_retry_delay()` return active configuration, respecting `$ENV{CLAUDE_MAX_RETRIES}` and `$ENV{CLAUDE_RETRY_DELAY}` (including `0` values).
- [ ] `init_retry_config()` called at startup and at the end of `load_env_file()`.
- [ ] `format_retry_status($retry_num, $max_retries, $delay)` in `src/ui.pl` returns formatted retry message with `$COLOR_DIM` / `$COLOR_RESET` support.

**Verification:**
- [ ] `perl -c src/header.pl`
- [ ] `perl -c src/ui.pl`

**Dependencies:** None

**Files likely touched:**
- `src/header.pl`
- `src/ui.pl`

**Estimated scope:** Small (2 files)

---

## Task 2: Implement Retry Loop in `call_api` (`src/transport.pl`)
**Description:** Refactor `call_api` in `src/transport.pl` into `_call_api_once` and a retry loop in `call_api` that retries up to `get_max_retries()` times (default 3) with `get_retry_delay()` seconds (default 5s) between retries on HTTP errors, curl/network failures (empty/000 status), JSON parse errors, or provider error payloads. Reassemble `code-agent.pl`.

**Acceptance criteria:**
- [ ] `_call_api_once` executes a single HTTP request via `curl`, cleans up tempfiles, decodes JSON, checks for non-2xx HTTP status or top-level error object (`$resp->{error}` or `$resp->{type} eq 'error'`), and returns decoded hashref or `die`s.
- [ ] `call_api` retries failed calls up to `get_max_retries()` times (default 3 retries = 4 total attempts).
- [ ] Between retries, `call_api` waits `get_retry_delay()` seconds (default 5s) using `select(undef, undef, undef, $delay)` when `$delay > 0`.
- [ ] When `$is_tty` is active on body requests, `call_api` updates the terminal status line via `format_retry_status` during the retry delay.
- [ ] If an attempt succeeds, `call_api` immediately returns the decoded response without further retries.
- [ ] If all retries fail, `call_api` throws (`die`) the last error message matching existing format (`API error (HTTP ...): ...` or `API error: ...`).
- [ ] `perl build.pl` compiles `code-agent.pl` and `perl build.pl --check` passes.

**Verification:**
- [ ] `perl build.pl`
- [ ] `perl build.pl --check`
- [ ] `perl -c code-agent.pl`

**Dependencies:** Task 1

**Files likely touched:**
- `src/transport.pl`
- `code-agent.pl`

**Estimated scope:** Small (1 source file + built artifact)

---

### Checkpoint: Core Retry Implementation
- [ ] `perl build.pl --check` exits with 0.
- [ ] `perl -c code-agent.pl` exits with 0.

---

### Phase 2: Testing & Verification

## Task 3: Update Mock Harness & Existing Tests, Add Comprehensive Retry Unit Tests
**Description:** Extend `t/mock_curl.pl` to support request counters and queued multi-attempt HTTP status/response sequences. Ensure existing error tests in `t/call_api.t`, `t/fetch_models.t`, and `t/models_command.t` run fast (with `CLAUDE_RETRY_DELAY=0`), and create `t/retry.t` (or expand `t/call_api.t`) to thoroughly test all retry scenarios.

**Acceptance criteria:**
- [ ] `t/mock_curl.pl` tracks attempt count (e.g. via `MOCK_CURL_COUNT_FILE`) and supports per-attempt status/response sequences (e.g. via `MOCK_CURL_HTTP_SEQUENCE` / `MOCK_CURL_RESP_SEQUENCE`) while remaining backward-compatible.
- [ ] Existing test files (`t/call_api.t`, `t/fetch_models.t`, `t/models_command.t`) pass without 15-second waits on negative test cases.
- [ ] Unit tests verify:
  - Default configuration: `get_max_retries() == 3` and `get_retry_delay() == 5`.
  - Immediate success on attempt 1 makes exactly 1 curl call and 0 retries.
  - Transient error (e.g., 2 failures followed by HTTP 200 on retry 2) makes 3 total attempts and returns the successful response.
  - Recovery on final (3rd) retry (3 failures followed by HTTP 200 on attempt 4) succeeds and returns response.
  - Exhausted retries (initial attempt + 3 retries = 4 total attempts all failing with HTTP 500/429/404) dies with the expected error after exactly 4 attempts.
  - Delay timing and callback/sleep verification (verifying 5s delay interval is respected).
  - Provider error object inside HTTP 200 response triggers retry and recovers or fails after 3 retries.
  - Sub-agent (`run_subagent`) transparently benefits from `call_api` retries when a turn encounters a transient error.

**Verification:**
- [ ] `prove -v t/call_api.t`
- [ ] `prove -v t/retry.t`
- [ ] `prove t/*.t`

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `t/mock_curl.pl`
- `t/call_api.t`
- `t/fetch_models.t`
- `t/models_command.t`
- `t/retry.t`

**Estimated scope:** Medium (4-5 test files)

---

### Checkpoint: All Tests Passing
- [ ] `prove -v t/retry.t` passes 100%.
- [ ] `prove t/*.t` passes 100% with zero regressions and fast execution time.

---

### Phase 3: Documentation & Context Maintenance

## Task 4: Documentation & Symbol Graph Synchronization
**Description:** Document the automatic retry mechanism (3 retries, 5s interval, and `CLAUDE_MAX_RETRIES` / `CLAUDE_RETRY_DELAY` environment variables) in `README.md` / `README.txt` and refresh the repository AST and symbol graphs.

**Acceptance criteria:**
- [ ] `README.md` and `README.txt` document the automatic retry policy (max 3 retries, 5s delay) and optional configuration variables.
- [ ] AST scanner, dependency graph, and symbol graph scripts executed cleanly.
- [ ] `verify_context.py` passes with 0 errors.

**Verification:**
- [ ] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/ast_scanner.py --root .`
- [ ] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/dependency_graph.py --manifest .context_cache/ast_manifest.json`
- [ ] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/symbol_graph.py --manifest .context_cache/ast_manifest.json --save-graph .context_cache/symbol_graph.json --export-signatures context/signatures.md`
- [ ] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .`

**Dependencies:** Task 1, Task 2, Task 3

**Files likely touched:**
- `README.md`
- `README.txt`
- `context/signatures.md`

**Estimated scope:** Small (2 doc files + context cache/signatures)

---

### Checkpoint: Complete
- [ ] All tests pass (`prove t/*.t`).
- [ ] Build check passes (`perl build.pl --check`).
- [ ] Context integrity check passes (`verify_context.py`).

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Existing negative tests (HTTP 401/404/500 in `t/call_api.t`, `t/fetch_models.t`, `t/models_command.t`) would sleep 15s (3 retries * 5s) each if delay isn't configurable | Medium | Support `CLAUDE_RETRY_DELAY` environment variable (set to `0` in negative unit tests while testing the 5s default explicitly in `t/retry.t`). |
| Live thinking timer (`* Thinking Xs...`) leaves artifacts on screen when an attempt fails and waits 5s before retrying | Low | Clear the current terminal line (`\r\033[K`) and display a clean dim retry status (`* API error, retrying in 5s (1/3)...`) on TTY before sleeping. |
| Tempfiles (`/tmp/code-agent-*`) leaked across retry attempts | Low | Ensure `_call_api_once` always unlinks all tempfiles before checking status or dying. |

---

## Open Questions
- None. The user request explicitly specifies max 3 retries and 5s time between retries when an LLM call returns an error.
