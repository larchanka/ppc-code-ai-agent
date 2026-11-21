# Task List: `/ctx` Context Window / Token Limit Command

## Phase 1: Foundation & State Management
- [x] Task 1: Context Limit State & Helper Subroutines
  - [x] Declare `our $MAX_TOKENS` with default 8,192 (8k) in `src/header.pl`
  - [x] Support `CLAUDE_MAX_TOKENS` and `CLAUDE_CONTEXT` environment variables in `src/header.pl`
  - [x] Implement `parse_context_size($input)` in `src/header.pl` supporting numbers (`65536`) and shorthand units (`8k`, `64k`, `1m`)
  - [x] Implement `format_context_size($tokens)` in `src/header.pl`
  - [x] Implement `get_max_tokens()` and `set_max_tokens($tokens)` accessors in `src/session.pl`
  - [x] Implement `handle_ctx_command($args, $out_fh)` in `src/session.pl`
  - [x] Add `/ctx` description to `show_help()` in `src/session.pl`
  - [x] Verify syntax: `perl -c src/header.pl` and `perl -c src/session.pl`

- [x] Task 2: Provider API Request Integration & REPL Dispatch
  - [x] Ensure `build_request` and provider builders in `src/providers.pl` respect `$MAX_TOKENS`
  - [x] Add `/ctx` slash command dispatch in `src/main.pl`
  - [x] Reassemble standalone artifact: `perl build.pl`
  - [x] Verify build synchronization: `perl build.pl --check`
  - [x] Verify syntax of compiled artifact: `perl -c code-agent.pl`

## Checkpoint: Foundation & Core Implementation
- [x] Build artifact synchronized: `perl build.pl --check` exits with 0
- [x] Standalone script compiles cleanly: `perl -c code-agent.pl`
- [x] Existing test suite passes with zero regressions: `prove t/*.t`

## Phase 2: Testing & Verification
- [x] Task 3: Comprehensive Automated Unit Test Suite (`t/ctx_command.t`)
  - [x] Write unit tests for default limit (8,192 / 8k) and environment variable overrides
  - [x] Write unit tests for `parse_context_size` (integers, shorthand units, invalid inputs)
  - [x] Write unit tests for `format_context_size`
  - [x] Write unit tests for `get_max_tokens` and `set_max_tokens`
  - [x] Write unit tests for `handle_ctx_command` (query mode, integer set, shorthand set, error handling)
  - [x] Write unit tests for API payload construction across Anthropic, Gemini, and OpenAI
  - [x] Write unit tests for `/ctx` presence in `show_help`
  - [x] Run `prove -v t/ctx_command.t`
  - [x] Run full test suite: `prove t/*.t`

## Checkpoint: Test Suite Passed
- [x] `prove -v t/ctx_command.t` passes cleanly
- [x] All tests pass: `prove t/*.t`

## Phase 3: Documentation & Context Maintenance
- [x] Task 4: Documentation & Post-Change Context & Symbol Graph Maintenance
  - [x] Update `README.md` with `/ctx` command details, default value (8k), and examples
  - [x] Update `README.txt` with `/ctx` command in command summary
  - [x] Run AST scanner (`ast_scanner.py`)
  - [x] Update dependency graph (`dependency_graph.py`)
  - [x] Update symbol graph & signatures (`symbol_graph.py`)
  - [x] Verify context integrity (`verify_context.py`)

## Checkpoint: Complete
- [x] All tests pass, build is verified, documentation is updated, context graphs are synchronized
