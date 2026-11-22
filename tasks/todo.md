# Task Breakdown: Markdown Preview for Agent Responses

- [x] 1. Build system & styling constants (`src/header.pl`, `build.pl`, `t/build.t`)
- [x] 2. Markdown renderer module (`src/markdown.pl`) — inline formatting, headers, code blocks, lists, blockquotes, horizontal rules, tables, `NO_COLOR` fallback, and standalone CLI mode
- [x] 3. UI & Main REPL integration (`src/ui.pl` ANSI-aware `slow_print`, `src/main.pl` calling `render_markdown`, `perl build.pl` to rebuild `code-agent.pl`)
- [x] 4. Comprehensive unit and integration tests in `t/markdown.t`, refactoring quality gates (CRAP < 10, clone-check, mutation verification), and full test suite verification (`prove -l t/*.t`)
- [x] 5. Update codebase context & symbol graphs as required by `AGENTS.md` section 5 (`ast_scanner.py`, `dependency_graph.py`, `symbol_graph.py`, `verify_context.py`, and context docs)
