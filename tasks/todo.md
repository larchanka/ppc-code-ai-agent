# Task List: LLM API Call Retry Mechanism

## Phase 1: Configuration, UI Helper, and Transport Retry Logic
- [x] Task 1: Retry Configuration & UI Status Formatter
  - [x] Declare `our $MAX_RETRIES = 3;` and `our $RETRY_DELAY = 5;` in `src/header.pl`
  - [x] Implement `init_retry_config()`, `get_max_retries()`, and `get_retry_delay()` in `src/header.pl` respecting `CLAUDE_MAX_RETRIES` and `CLAUDE_RETRY_DELAY`
  - [x] Call `init_retry_config()` at startup and inside `load_env_file()` in `src/header.pl`
  - [x] Implement `format_retry_status($retry_num, $max_retries, $delay)` in `src/ui.pl`
  - [x] Verify syntax: `perl -c src/header.pl` and `perl -c src/ui.pl`

- [x] Task 2: Implement Retry Loop in `call_api` (`src/transport.pl`)
  - [x] Extract single-attempt curl request and response decoding into `_call_api_once($url, $headers, $body_json, $method)` in `src/transport.pl`
  - [x] Detect HTTP non-2xx errors, empty/invalid responses, and top-level JSON error payloads (`$resp->{error}` or `$resp->{type} eq 'error'`)
  - [x] Implement retry loop in `call_api` with max retries (`get_max_retries()`, default 3) and delay (`get_retry_delay()`, default 5s) using `select(undef, undef, undef, $delay)`
  - [x] Display terminal retry status on TTY when waiting between retries
  - [x] Reassemble `code-agent.pl` via `perl build.pl`
  - [x] Verify build synchronization: `perl build.pl --check` and `perl -c code-agent.pl`

## Checkpoint: Core Retry Implementation
- [x] `perl build.pl --check` exits with 0
- [x] `perl -c code-agent.pl` exits with 0

## Phase 2: Testing & Verification
- [x] Task 3: Update Mock Harness & Existing Tests, Add Comprehensive Retry Unit Tests
  - [x] Extend `t/mock_curl.pl` to support attempt counting (`MOCK_CURL_COUNT_FILE`) and per-attempt response/status sequences (`MOCK_CURL_HTTP_SEQUENCE`, `MOCK_CURL_RESP_SEQUENCE`)
  - [x] Set `$ENV{CLAUDE_RETRY_DELAY} = 0` in existing test suites (`t/call_api.t`, `t/fetch_models.t`, `t/models_command.t`) so negative tests execute instantaneously while still exercising retry logic
  - [x] Create `t/retry.t` testing:
    - [x] Default configuration (`get_max_retries() == 3`, `get_retry_delay() == 5`)
    - [x] Environment variable overrides (`CLAUDE_MAX_RETRIES`, `CLAUDE_RETRY_DELAY`)
    - [x] Success on first attempt (1 call total, 0 retries)
    - [x] Transient HTTP 500/503 errors recovering on retry 1, 2, or 3
    - [x] Persistent error exhausting all 3 retries (4 attempts total) and dying with error message
    - [x] Provider error JSON payload triggering retry and recovering
    - [x] Retry delay timing and `format_retry_status` formatting
    - [x] Sub-agent (`run_subagent`) recovering from transient LLM error via `call_api` retry
  - [x] Run `prove -v t/retry.t` and full test suite `prove t/*.t`

## Checkpoint: All Tests Passing
- [x] `prove -v t/retry.t` passes 100%
- [x] `prove t/*.t` passes 100% with zero regressions

## Phase 3: Documentation & Context Maintenance
- [x] Task 4: Documentation & Symbol Graph Synchronization
  - [x] Document retry behavior (max 3 retries, 5s between retries) and `CLAUDE_MAX_RETRIES` / `CLAUDE_RETRY_DELAY` in `README.md` and `README.txt`
  - [x] Run AST scanner (`ast_scanner.py`)
  - [x] Update dependency graph (`dependency_graph.py`)
  - [x] Update symbol graph & signatures (`symbol_graph.py`)
  - [x] Verify context integrity (`verify_context.py`)

## Checkpoint: Complete
- [x] All tests pass, build is verified, documentation is updated, context graphs are synchronized
