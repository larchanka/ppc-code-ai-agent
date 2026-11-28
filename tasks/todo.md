# TODO: Session Persistence and Resumption

## Phase 1: Foundation
- [x] **Task 1**: Short Session IDs & Persistent Storage Module (`src/session_store.pl`, `src/header.pl`, `src/session.pl`, `build.pl`, `t/build.t`, `t/new_command.t`, `t/session_store.t`)
- [x] **Task 2**: Auto-Save Lifecycle Hooks & Quiet `call_api` Option (`src/transport.pl`, `src/session.pl`, `src/main.pl`, `t/session_persistence.t`)
- [x] **Checkpoint 1**: Build sync, Perl 5.8.6 check, and Phase 1 tests pass

## Phase 2: Auto-Titling & Session Commands
- [x] **Task 3**: Auto-Title Generation via LLM with Fallback (`src/session.pl`, `src/main.pl`, `t/new_command.t`, `t/session_title.t`)
- [x] **Task 4**: `/session <id>`, `/session delete <id>`, and Resume Summary (`src/ui.pl`, `src/session.pl`, `src/main.pl`, `t/session_commands.t`)
- [x] **Checkpoint 2**: Build sync and Phase 1-2 tests pass

## Phase 3: Interactive Menu, CLI Startup & Polish
- [x] **Task 5**: Interactive `/sessions` & `/sessions all` Menu (`src/session.pl`, `src/main.pl`, `t/sessions_menu.t`)
- [x] **Task 6**: CLI `--session <id>` Startup Flag & `Install.command` / `modern-install.command` Wrappers (`src/main.pl`, `Install.command`, `modern-install.command`, `t/session_cli.t`)
- [x] **Task 7**: Update `AGENTS.md`, refresh context/symbol graphs, and run full verification suite
- [x] **Checkpoint 3**: All tests (`prove -I. t/*.t`), Perl 5.8.6 check, `build.pl --check`, and `verify_context.py` pass
