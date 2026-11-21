# Implementation Plan: `/ctx` Context Window / Token Limit Command

Add the `/ctx` interactive slash command to inspect and adjust the model context/token limit during interactive sessions, default the limit to 8k (8,192 tokens), and ensure all provider API requests (Anthropic, Google Gemini, OpenAI-compatible) utilize this limit.

---

## Overview

The terminal agent currently defaults to a hardcoded 4,096 token limit (`$MAX_TOKENS = 4096;` in `src/header.pl`). Large codebases, extensive tool invocations, and modern model architectures require larger context generation budgets. This feature introduces:
1. **Configurable Default**: Update the default context/token limit from 4,096 to 8,192 tokens (8k), with startup environment variable overrides (`CLAUDE_MAX_TOKENS` and `CLAUDE_CONTEXT`).
2. **Interactive Slash Command (`/ctx`)**: Allow the user to inspect the current limit (`/ctx`) or update it on the fly using either raw numbers (e.g. `/ctx 65536`) or shorthand size notations (e.g. `/ctx 64k`, `/ctx 8k`, `/ctx 128k`).
3. **API Request Synchronization**: Ensure that all provider adapters (`Anthropic`, `Gemini`, `OpenAI-compatible`) pass the active context token limit in their respective API payloads (`max_tokens` or `maxOutputTokens`).
4. **Hermetic Testing & Context Integrity**: Pure Perl 5.8.6 unit tests in `t/ctx_command.t`, verification across all providers, and updated AST/symbol graphs.

---

## Architecture Decisions

### 1. State Management & Accessors (`src/header.pl` & `src/session.pl`)
- **Global Variable**: Change `my $MAX_TOKENS` to `our $MAX_TOKENS` in `src/header.pl` with a default of 8,192 tokens ($8 \times 1024$).
- **Environment Fallback**: At startup, check `$ENV{CLAUDE_MAX_TOKENS}` or `$ENV{CLAUDE_CONTEXT}` (parsing shorthand like `64k` or integer `65536`) before falling back to 8,192.
- **Accessors in `src/session.pl`**:
  - `get_max_tokens()`: Returns current `$MAX_TOKENS`.
  - `set_max_tokens($val)`: Sets `$MAX_TOKENS` and updates `$ENV{CLAUDE_MAX_TOKENS}`.
  - `parse_context_size($input)`: Parses strings like `'65536'`, `'8192'`, `'8k'`, `'64k'`, `'1m'`, validating positive integers. Returns `undef` on non-numeric or non-positive input.
  - `format_context_size($tokens)`: Returns formatted representation (e.g. `8192` -> `'8k'`, `65536` -> `'64k'`, `1048576` -> `'1m'`).
  - `handle_ctx_command($args, $out_fh)`: Handles `/ctx` command execution and user output.

### 2. Provider API Request Payloads (`src/providers.pl`)
- **Anthropic**: `max_tokens => $MAX_TOKENS` in `build_request_anthropic`.
- **Google Gemini**: `generationConfig => { maxOutputTokens => $MAX_TOKENS, ... }` in `build_request_gemini`.
- **OpenAI-Compatible**: `max_tokens => $MAX_TOKENS` in `build_request_openai`.
- **`build_request(...)`**: Supports optional `$max_tokens` argument override while defaulting to active `$MAX_TOKENS`.

### 3. REPL Loop & Help Integration (`src/main.pl` & `src/session.pl`)
- **REPL Matcher**: Match `m{^/(?:ctx|context)(?:\s+(.*))?$}` to support both `/ctx` and optional `/context` alias, with or without arguments.
- **Help Menu**: Add `/ctx` description to `show_help()` in `src/session.pl`.

### 4. Compatibility & Constraints
- **Perl 5.8.6 Standard Library**: No modern Perl features (no `//`, `say`, `state`, named captures).
- **Tiger / PowerPC Safe**: Zero external CPAN dependencies; raw STDIN decoding boundary preserved.

---

## Task List

### Phase 1: Foundation & State Management

## Task 1: Context Limit State & Helper Subroutines
**Description:** Implement context limit accessors, parsing, formatting, and the `/ctx` command handler in `src/header.pl` and `src/session.pl`. Update default `$MAX_TOKENS` to 8,192 (8k) and add `/ctx` to `show_help()`.

**Acceptance criteria:**
- [ ] `$MAX_TOKENS` defaults to 8,192 (or parsed from `CLAUDE_MAX_TOKENS` / `CLAUDE_CONTEXT` environment variables).
- [ ] `parse_context_size($str)` correctly parses raw integers (e.g. `65536`) and shorthand units (`8k`, `64k`, `1m`), returning integer tokens or `undef` on invalid input.
- [ ] `format_context_size($tokens)` returns human-readable representation (`8k`, `64k`, etc.).
- [ ] `get_max_tokens()` and `set_max_tokens($tokens)` manage `$MAX_TOKENS` state.
- [ ] `handle_ctx_command($args, $out_fh)`:
  - When called with no arguments or whitespace: prints current limit and usage syntax, returns current limit.
  - When called with valid argument (e.g. `65536` or `64k`): sets limit, prints confirmation, returns new limit.
  - When called with invalid argument: prints error message, preserves existing limit, returns `undef`.
- [ ] `show_help($out_fh)` includes `/ctx` command description.

**Verification:**
- [ ] `perl -c src/header.pl`
- [ ] `perl -c src/session.pl`

**Dependencies:** None

**Files likely touched:**
- `src/header.pl`
- `src/session.pl`

**Estimated scope:** Small (2 files)

---

## Task 2: Provider API Request Integration & REPL Dispatch
**Description:** Integrate context token limit into `build_request` across all providers in `src/providers.pl` and wire the `/ctx` slash command into the REPL loop in `src/main.pl`. Reassemble `code-agent.pl` using `build.pl`.

**Acceptance criteria:**
- [ ] `build_request` and provider builders (`build_request_anthropic`, `build_request_gemini`, `build_request_openai`) respect active `$MAX_TOKENS` or optional parameter override.
- [ ] `src/main.pl` recognizes `/ctx` (and `/context`), dispatching to `handle_ctx_command($1)`.
- [ ] `perl build.pl` regenerates `code-agent.pl` cleanly.
- [ ] `perl build.pl --check` succeeds with exit code 0.
- [ ] `perl -c code-agent.pl` compiles cleanly.

**Verification:**
- [ ] `perl build.pl`
- [ ] `perl build.pl --check`
- [ ] `perl -c code-agent.pl`
- [ ] `prove t/*.t` (all existing tests continue to pass)

**Dependencies:** Task 1

**Files likely touched:**
- `src/providers.pl`
- `src/main.pl`
- `code-agent.pl`

**Estimated scope:** Small (2 source files + built artifact)

---

### Checkpoint: Foundation & Core Implementation
- [ ] `perl build.pl --check` exits with 0.
- [ ] `perl -c code-agent.pl` exits with 0.
- [ ] All existing regression tests pass: `prove t/*.t`.

---

### Phase 2: Testing & Verification

## Task 3: Comprehensive Automated Unit Test Suite (`t/ctx_command.t`)
**Description:** Create dedicated test file `t/ctx_command.t` testing all edge cases for context limit configuration, parsing, formatting, slash command output, and API request payload construction for Anthropic, Gemini, and OpenAI.

**Acceptance criteria:**
- [ ] Tests verify default context is 8,192 tokens (8k).
- [ ] Tests verify `CLAUDE_MAX_TOKENS` and `CLAUDE_CONTEXT` environment variable overrides at startup.
- [ ] Tests verify `parse_context_size` for integers (`65536`, `8192`), shorthand (`8k`, `64k`, `64K`, `128k`, `1m`), and invalid values (`0`, `-10`, `abc`, empty, undef).
- [ ] Tests verify `format_context_size` for standard multipliers (`8k`, `64k`, `1m`) and arbitrary values (`8000`).
- [ ] Tests verify `handle_ctx_command`:
  - Query mode (no args) prints current limit and usage.
  - Set mode with integer (e.g. `65536`) updates limit and prints confirmation.
  - Set mode with shorthand (e.g. `64k`) updates limit to 65,536 and prints confirmation.
  - Error mode with invalid input prints error and preserves limit.
- [ ] Tests verify `build_request` constructs correct `max_tokens` (Anthropic / OpenAI) and `maxOutputTokens` (Gemini) matching the updated context limit.
- [ ] Tests verify help output in `show_help()` includes `/ctx`.

**Verification:**
- [ ] `prove -v t/ctx_command.t`
- [ ] `prove t/*.t`

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `t/ctx_command.t`

**Estimated scope:** Small (1 test file)

---

### Checkpoint: Test Suite Passed
- [ ] `prove -v t/ctx_command.t` passes 100%.
- [ ] `prove t/*.t` passes with zero regressions across all test suites.

---

### Phase 3: Documentation & Context Maintenance

## Task 4: Documentation & Post-Change Context & Symbol Graph Maintenance
**Description:** Update user-facing documentation (`README.md`, `README.txt`), rescan AST symbols, and update the repository context and dependency graphs according to project guidelines.

**Acceptance criteria:**
- [ ] `README.md` documents `/ctx` slash command, default 8k, and usage examples (`/ctx 65536`, `/ctx 64k`).
- [ ] `README.txt` documents `/ctx` in the command list.
- [ ] AST scanner (`ast_scanner.py`) executes and updates `.context_cache/ast_manifest.json`.
- [ ] Dependency graph (`dependency_graph.py`) updates internal dependency maps.
- [ ] Symbol graph (`symbol_graph.py`) updates `context/signatures.md` with new subroutines.
- [ ] Context integrity check (`verify_context.py`) passes without errors.

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
- `context/modules.md`

**Estimated scope:** Small (2 doc files + context artifacts)

---

### Checkpoint: Complete
- [ ] All unit and regression tests pass (`prove t/*.t`).
- [ ] Standalone build artifact `code-agent.pl` in sync (`perl build.pl --check`).
- [ ] Context documentation and symbol graphs verified.

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Provider API rejects token limits exceeding model maximums (e.g. older models with 4k output cap) | Medium | Document supported bounds in `/help` and allow user to immediately scale down via `/ctx` without restarting session. |
| User inputs non-numeric shorthand (e.g. `64kb` or floating points) | Low | `parse_context_size` handles whitespace, case-insensitivity (`64k` / `64K`), and rejects malformed inputs with helpful syntax guidance without corrupting active limit. |
| Inadvertent drift between modular sources in `src/` and compiled `code-agent.pl` | High | Strict enforcement of `perl build.pl` and automated `perl build.pl --check` verification. |

---

## Open Questions
- None. Requirements are clear: default to 8k (8,192 tokens), allow `/ctx` to set arbitrary tokens (e.g. `/ctx 65536` or `/ctx 64k`), and propagate to all provider API calls.
