# Implementation Plan: Session Persistence and Resumption

## Overview
Implement full session persistence, auto-titling, browsing, resumption, deletion, and CLI startup resumption for `ppc-code-ai-agent`. Sessions are stored as atomic, mode-`0600`, schema-version-1 JSON files in `~/.code-agent/sessions/` alongside a lightweight, rebuildable `index.json`. The design preserves zero CPAN dependencies, strict Perl 5.8.6 / Mac OS X 10.4 Tiger compatibility, 80-column terminal readability, and all existing session/compaction/stats invariants.

## Architecture Decisions

1. **Dedicated Storage Module (`src/session_store.pl`)**:
   - Place disk I/O, atomic writes, index management, retention pruning, and ID resolution in a new module `src/session_store.pl` loaded immediately before `src/session.pl` in `build.pl`.
   - Keeps `src/session.pl` focused on lifecycle, compaction, auto-titling, and slash command handlers (~400-550 lines per module).
   - Requires updating `@MODULES` in `build.pl` and `@manifest` in `t/build.t`.

2. **Storage Layout & Schema v1 (`~/.code-agent/sessions/`)**:
   - Base directory: `$ENV{CLAUDE_SESSIONS_DIR}` (override for tests/custom setups) or `"$ENV{HOME}/.code-agent/sessions"`. Created lazily with `0700` permissions on first write.
   - Individual session file `<id>.json` (`chmod 0600`, atomic `<file>.tmp.$$.<rand>` -> `rename`, UTF-8 encoded JSON via `MiniJSON::encode`):
     ```json
     {
       "version": 1,
       "id": "1128-a3f9",
       "title": "Fix Perl JSON UTF8 Bug",
       "cwd": "/path/to/project",
       "created_at": 1732750000,
       "updated_at": 1732750320,
       "provider": "anthropic",
       "model": "claude-sonnet-4-5-20250929",
       "messages": [...],
       "stats": {...}
     }
     ```
   - Lightweight `index.json` (`version: 1`, `sessions: [...]`) storing only metadata (`id`, `title`, `cwd`, `created_at`, `updated_at`, `message_count`, `user_turns`, `provider`, `model`), sorted descending by `updated_at`.
   - If `index.json` is missing or corrupt JSON, `rebuild_sessions_index()` scans `*.json` files in the directory, skips corrupt files, and rewrites `index.json`.
   - All session IDs are validated against `/^[A-Za-z0-9_-]+$/` before path construction to prevent path traversal.
   - Unwritable/nonexistent `$HOME` (e.g. `HOME="/nonexistent"` in tests) fails gracefully without dying or disrupting the REPL.

3. **Short Session IDs & Prefix Matching**:
   - Format: `MMDD-XXXX` (9 chars, e.g. `1128-a3f9` — local month/day + 4 lowercase hex chars), collision-checked against existing files and monotonic counter.
   - `resolve_session_id($query)` matches exact ID first (case-insensitive fallback), then unique prefix match. Returns structured error on not-found or ambiguous prefix.

4. **Auto-Save Lifecycle & Retention**:
   - Empty sessions (0 messages) are never saved.
   - Auto-save triggers: after every completed turn in `src/main.pl`, on `/compact`, on `/new` (via `archive_session`), before switching sessions (`/session <id>` or `/sessions`), and on clean exit (`exit` / EOF).
   - Retention: default 100 sessions (configurable via `CLAUDE_MAX_SESSIONS`). On save, oldest entries by `updated_at` beyond the limit are pruned from `index.json` and their `<id>.json` files unlinked.

5. **Auto-Title Generation via LLM**:
   - Triggered once per session after the first completed turn (when `!$session->{title}` and `!$session->{title_attempted}`), controlled by `CLAUDE_SESSION_AUTO_TITLE` (default `1`; `0|false|no|off` disables).
   - Uses a quiet, single-attempt `call_api(..., { silent => 1, no_retry => 1 })` extension in `src/transport.pl` so title generation never renders the `* Thinking` live timer, never retries/stalls, and never clobbers `$LAST_API_ELAPSED`.
   - Prompt requests a short English title (max 25 chars, ASCII letters/digits/spaces only). Output is strictly sanitized (`[^A-Za-z0-9 ]` stripped, spaces collapsed, max 25 chars).
   - Clean fallback on failure/empty output: sanitized first user message (max 25 chars), or `"Session <id>"` if non-ASCII/empty.

6. **Interactive `/sessions` Menu & `/session` Commands**:
   - `/sessions` shows up to 15 most recent sessions for current `cwd` (sorted by `updated_at`); `/sessions all` shows up to 15 across all directories with `[dirname]` context.
   - Reuses `_read_menu_key()` and the TTY raw-mode / non-TTY numeric fallback pattern from `src/models_menu.pl`.
   - `/session <id>` saves current non-empty session, loads target session, **preserves the active `$PROVIDER` and `$MODEL`**, and prints a concise resume header (ID, title, date, message count) + last 1-2 user/assistant exchanges.
   - `/session delete <id>` deletes the session file and removes it from `index.json`; if deleting the active session, initializes a fresh empty session.

7. **CLI `--session <id>` Startup Flag & Wrappers**:
   - `parse_cli_args(\@ARGV)` in `src/main.pl` supports `--session <id>` and `--session=<id>`. Exits non-zero (1) if missing value, session not found, ambiguous, or corrupt.
   - Update `Install.command` wrapper (`$HOME/bin/code`) from `exec perl $AGENT_SCRIPT` to `exec perl "$AGENT_SCRIPT" "$@"` (`modern-install.command` already forwards `"$@"`).

## Dependency Graph

```
Task 1 (Storage, Schema v1, Short IDs, Index, Pruning)
   │
   ├── Task 2 (Auto-save lifecycle hooks + quiet call_api option)
   │      │
   │      ├── Task 3 (Auto-title generation via LLM + fallback)
   │      │
   │      └── Task 4 (/session <id>, /session delete <id>, resume summary)
   │             │
   │             ├── Task 5 (Interactive /sessions & /sessions all menu)
   │             │
   │             └── Task 6 (CLI --session <id> flag + Install.command wrapper)
   │                    │
   │                    └── Task 7 (Docs, Context/Graph sync, Full verification)
```

---

## Detailed Task Breakdown

### Phase 1: Foundation

#### Task 1: Short Session IDs & Persistent Storage Module (`src/session_store.pl`)
**Description:** Create `src/session_store.pl` implementing schema-version-1 JSON persistence, atomic `0600` writes, rebuildable `index.json`, retention pruning (default 100, `CLAUDE_MAX_SESSIONS`), cwd-filtered listing, and exact/prefix ID resolution. Register the module in `build.pl` and `t/build.t`, add `Cwd` import in `src/header.pl`, and update `generate_session_id()` / `init_session()` in `src/session.pl` to use short `MMDD-XXXX` IDs and track `updated_at`, `cwd`, `title`, and `title_attempted`.

**Acceptance criteria:**
- [ ] `generate_session_id()` produces unique 9-char `MMDD-XXXX` IDs (lowercase hex suffix) and `init_session()` initializes `updated_at`, `cwd`, `title => ''`, and `title_attempted => 0`.
- [ ] `save_session()` skips empty sessions (0 messages), writes `<id>.json` and `index.json` atomically with `0600` permissions (dir `0700`), handles UTF-8 content cleanly, fails gracefully on unwritable dirs, and prunes oldest sessions beyond `get_max_saved_sessions()` (default 100).
- [ ] `load_sessions_index()` automatically rebuilds `index.json` from `<id>.json` files if missing or corrupt; `resolve_session_id()` supports exact match, unique prefix match, and rejects invalid/path-traversal IDs and ambiguous prefixes.

**Verification:**
- [ ] Build succeeds: `perl build.pl && perl build.pl --check`
- [ ] Perl 5.8.6 check passes: `perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl build.pl scripts/check_minimum_version.pl src/*.pl`
- [ ] Tests pass: `prove -I. t/build.t t/new_command.t t/session_store.t`

**Dependencies:** None

**Files likely touched:**
- `src/session_store.pl` (new)
- `src/header.pl`
- `src/session.pl`
- `build.pl`
- `t/build.t`
- `t/new_command.t`
- `t/session_store.t` (new)

**Estimated scope:** Medium (5 source/build files + 2 test files)

---

#### Task 2: Auto-Save Lifecycle Hooks & Quiet `call_api` Option
**Description:** Extend `call_api()` / `_call_api_once()` in `src/transport.pl` with an optional 5th hashref parameter (`{ silent => 1, no_retry => 1 }`) that disables the live thinking timer, retry loop, and `$LAST_API_ELAPSED` mutation. Wire automatic `save_session()` calls into `archive_session()` (covering `/new`), `handle_compact_command()`, completed turns in `src/main.pl`, and clean exit (`exit` / EOF) in `src/main.pl`.

**Acceptance criteria:**
- [ ] `call_api($url, $headers, $body, 'POST', { silent => 1, no_retry => 1 })` runs silently without printing `* Thinking` or retry output, does not retry on error, and preserves `$LAST_API_ELAPSED`; existing 3-arg and 4-arg callers behave identically.
- [ ] Non-empty sessions are automatically saved after every completed turn, on `/compact`, on `/new` (via `archive_session()`), and on clean REPL exit; empty sessions (0 messages) are never saved.
- [ ] `archive_session()` still returns `$session` (or `undef` when no session exists) so existing contracts remain intact.

**Verification:**
- [ ] Build succeeds: `perl build.pl && perl build.pl --check`
- [ ] Tests pass: `prove -I. t/call_api.t t/retry.t t/thinking_visuals.t t/new_command.t t/compact_context.t t/session_persistence.t`

**Dependencies:** Task 1

**Files likely touched:**
- `src/transport.pl`
- `src/session.pl`
- `src/main.pl`
- `t/session_persistence.t` (new)

**Estimated scope:** Small-Medium (3 source files + 1 test file)

---

### Checkpoint 1: Foundation
- [ ] `perl build.pl && perl build.pl --check` passes
- [ ] Perl 5.8.6 compatibility check passes
- [ ] `prove -I. t/build.t t/new_command.t t/call_api.t t/session_store.t t/session_persistence.t` all pass

---

### Phase 2: Auto-Titling & Session Commands

#### Task 3: Auto-Title Generation via LLM with Fallback
**Description:** Implement automatic English-only session title generation (max 25 chars, ASCII letters/digits/spaces only) triggered once after the first completed turn, controlled by `CLAUDE_SESSION_AUTO_TITLE` (default enabled). Uses quiet single-attempt `call_api` with `max_tokens => 32` and empty tools, sanitizes the model output, and falls back cleanly to a sanitized snippet of the first user prompt or `"Session <id>"` if the API call fails or produces empty output.

**Acceptance criteria:**
- [ ] `sanitize_session_title()` strips non-ASCII and special characters (keeping only `[A-Za-z0-9 ]`), collapses whitespace, and enforces a max length of 25 characters.
- [ ] `generate_session_title()` generates a title via the active provider after turn 1 (before saving), sets `$session->{title}` and `$session->{title_attempted} = 1`, and falls back cleanly on API/parse failure without throwing or printing errors.
- [ ] Setting `CLAUDE_SESSION_AUTO_TITLE=0` skips the title API call; `t/new_command.t` test 7 passes cleanly.

**Verification:**
- [ ] Build succeeds: `perl build.pl && perl build.pl --check`
- [ ] Tests pass: `prove -I. t/session_title.t t/new_command.t`

**Dependencies:** Task 2

**Files likely touched:**
- `src/session.pl`
- `src/main.pl`
- `t/new_command.t`
- `t/session_title.t` (new)

**Estimated scope:** Small (2 source files + 2 test files)

---

#### Task 4: `/session <id>`, `/session delete <id>`, and Resume Summary
**Description:** Implement session switching (`/session <id>`), session deletion (`/session delete <id>`), and resume summary formatting (header with ID, title, date, message count + last 1-2 user/assistant exchanges). Switching saves the current non-empty session first and keeps the currently active provider and model unchanged. Deleting the currently active session initializes a fresh empty session. Update `/help` and `/stats` header (showing title if present).

**Acceptance criteria:**
- [ ] `/session <id>` (exact or unique prefix) saves current non-empty session, loads target session into `$CURRENT_SESSION`, does NOT alter `$PROVIDER` or `$MODEL`, and prints resume header + last 1-2 user/assistant text exchanges.
- [ ] `/session delete <id>` deletes `<id>.json` and removes it from `index.json`; if deleting the active session, starts a fresh empty session.
- [ ] Invalid/missing/ambiguous IDs print clear error messages without altering the current session; `/help` documents `/sessions` and `/session`.

**Verification:**
- [ ] Build succeeds: `perl build.pl && perl build.pl --check`
- [ ] Tests pass: `prove -I. t/session_commands.t t/stats_command.t t/new_command.t`

**Dependencies:** Task 1, Task 2

**Files likely touched:**
- `src/ui.pl`
- `src/session.pl`
- `src/main.pl`
- `t/session_commands.t` (new)

**Estimated scope:** Medium (3 source files + 1 test file)

---

### Checkpoint 2: Core Features
- [x] `perl build.pl && perl build.pl --check` passes
- [x] `prove -I. t/session_store.t t/session_persistence.t t/session_title.t t/session_commands.t t/stats_command.t t/new_command.t` all pass
- [x] End-to-end save -> title -> switch -> resume -> delete flow verified

---

### Phase 3: Interactive Menu, CLI Startup & Polish

#### Task 5: Interactive `/sessions` Menu (TTY & Non-TTY)
**Description:** Implement `/sessions` (default: 15 most recent sessions for current `cwd`, sorted by `updated_at`) and `/sessions all` (15 most recent across all directories with short dir label). Reuse `_read_menu_key()` from `src/models_menu.pl` to provide an interactive arrow-key / digit-jump TTY menu with a non-TTY numbered prompt fallback, cleanly formatted for 80-column terminals. Selecting a session calls `switch_to_session()`.

**Acceptance criteria:**
- [x] `/sessions` filters to current `cwd` and shows up to 15 most recent sessions sorted by `updated_at` desc; `/sessions all` lists up to 15 across all directories with directory basename shown.
- [x] Interactive TTY mode supports Up/Down arrows, digit jump, Enter to resume, and Esc/Ctrl-C to cancel without switching; non-TTY mode supports numeric selection, ID/prefix input, or empty/q to cancel.
- [x] Empty list prints a helpful message (hinting `/sessions all` when filtered by `cwd`).

**Verification:**
- [x] Build succeeds: `perl build.pl && perl build.pl --check`
- [x] Tests pass: `prove -I. t/sessions_menu.t t/select_model_interactive.t`

**Dependencies:** Task 4

**Files likely touched:**
- `src/session.pl`
- `src/main.pl`
- `t/sessions_menu.t` (new)

**Estimated scope:** Small-Medium (2 source files + 1 test file)

---

#### Task 6: CLI `--session <id>` Startup Flag & Wrapper Scripts
**Description:** Add CLI argument parsing (`parse_cli_args(\@ARGV)`) in `src/main.pl` for `--session <id>` and `--session=<id>`. When passed, resolve and load the target session at startup (exiting with status 1 and a clear STDERR error if not found, ambiguous, or missing argument) and display the resume summary after `show_banner()`. Update `Install.command` so the generated `code` wrapper forwards `"$@"` (matching `modern-install.command`).

**Acceptance criteria:**
- [x] `perl code-agent.pl --session <id>` (and `--session=<id>`) loads the matching session (exact or prefix) at startup and prints the resume summary after the banner.
- [x] Unknown, ambiguous, or missing `--session` argument prints an error to STDERR and exits with non-zero status (1).
- [x] `Install.command` wrapper uses `exec perl "$AGENT_SCRIPT" "$@"` and passes `bash -n`; `modern-install.command` also forwards `"$@"`.

**Verification:**
- [x] Build succeeds: `perl build.pl && perl build.pl --check`
- [x] Shell syntax passes: `bash -n Install.command && bash -n modern-install.command`
- [x] Tests pass: `prove -I. t/session_cli.t t/build.t`

**Dependencies:** Task 4

**Files likely touched:**
- `src/main.pl`
- `Install.command`
- `t/session_cli.t` (new)

**Estimated scope:** Small (2 source/installer files + 1 test file)

---

#### Task 7: Documentation, Context/Graph Sync & Full Verification
**Description:** Update `AGENTS.md` to document `src/session_store.pl` and new session environment variables (`CLAUDE_SESSIONS_DIR`, `CLAUDE_MAX_SESSIONS`, `CLAUDE_SESSION_AUTO_TITLE`), refresh AST/dependency/symbol graphs and `context/signatures.md`, and run the complete verification suite.

**Acceptance criteria:**
- [x] `AGENTS.md` reflects the 15-module layout and session persistence configuration variables.
- [x] Context and symbol graph scripts succeed and `verify_context.py --root .` passes.
- [x] Full test suite (`prove -I. t/*.t`), Perl 5.8.6 version check, `perl -c code-agent.pl`, and `perl build.pl --check` all pass with zero failures.

**Verification:**
- [x] `perl build.pl && perl build.pl --check && perl -c code-agent.pl`
- [x] `perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl build.pl scripts/check_minimum_version.pl src/*.pl`
- [x] `prove -I. t/*.t`
- [x] `python3 ~/.gemini/config/skills/codebase-context-generator/scripts/verify_context.py --root .`

**Dependencies:** Tasks 1-6

**Files likely touched:**
- `AGENTS.md`
- `context/signatures.md`
- `.context_cache/*`

**Estimated scope:** Small

---

### Checkpoint 3: Complete
- [x] All acceptance criteria across Tasks 1-7 met
- [x] Full test suite and Perl 5.8.6 compatibility checks green
- [x] Ready for code review

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Auto-title API call breaks existing tests that count API requests (e.g. `t/new_command.t` test 7) | High | Add `CLAUDE_SESSION_AUTO_TITLE=0` env var support, pass it in `t/new_command.t` test 7, and make title calls quiet/non-retrying. |
| `HOME="/nonexistent"` in existing subprocess tests causes `save_session()` to die | High | Wrap directory creation and atomic file writes cleanly; return `0` without dying when storage is unwritable. |
| Perl 5.8.6 syntax regressions (e.g. `//`, `state`, modern regex features) | High | Run `scripts/check_minimum_version.pl --perl 5.008006` at every checkpoint. |
| Path traversal via malicious `/session ../../foo` or `/session delete ../index` | Med | Strictly validate session IDs against `/^[A-Za-z0-9_-]+$/` before any file operation. |
| Corrupt `index.json` or partial write on power loss / crash | Med | Use atomic temp-file + `rename` writes (`0600`) and automatic `rebuild_sessions_index()` recovery. |
| Adding `src/session_store.pl` breaks `t/build.t` hardcoded `@manifest` | Med | Update `@manifest` in `t/build.t` alongside `build.pl` in Task 1. |
| Non-ASCII / special chars or verbose prose from LLM in title response | Low | Enforce strict `sanitize_session_title()` keeping only `[A-Za-z0-9 ]`, max 25 chars, with deterministic fallback. |

## Open Questions
None — all design decisions have been confirmed by the user.
