# Markdown Preview for Agent Responses (Mac OS X 10.4 Tiger / G4 Terminal)

## Goal Description
Add a pure-Perl 5.8.6 Markdown renderer tailored for Mac OS X 10.4 Tiger's `Terminal.app` (`xterm-color`) on PowerPC G4 hardware. Agent responses will be formatted with Tiger-safe ANSI styling and clean ASCII typography while remaining 100% self-contained with zero CPAN dependencies.

The renderer lives in a dedicated modular source file `src/markdown.pl` compiled into `code-agent.pl` by `build.pl`, and can also be executed standalone from the command line (`perl src/markdown.pl [file.md]`) to preview any Markdown file or pipe on a vintage Mac.

## Design Specification

| Markdown Element | Syntax | Tiger Terminal Rendering |
| :--- | :--- | :--- |
| **Headers (`H1`–`H6`)** | `# Title`, `## Section`, `### Sub` | **Bold + Magenta** (`\e[1;35m`). `H1` adds underline (`\e[1;4;35m`); `H2` is `\e[1;35m`; `H3+` includes a `###` prefix in bold magenta |
| **Bold** | `**text**` or `__text__` | **Bold** (`\e[1m`) |
| **Emphasis / Underline** | `*text*` or `_text_` | **Underline** (`\e[4m`), respecting word boundaries for `_text_` so `snake_case` identifiers are untouched |
| **Inline Code** | `` `code` `` | **Blue** (`\e[34m`), protected from inline emphasis/link parsing |
| **Fenced Code Blocks** | ```` ```lang ... ``` ```` | **Blue** (`\e[34m`) with an ASCII left gutter (`  \| `) and optional `  +--[ lang ]` header badge |
| **Unordered Lists** | `- item`, `* item`, `+ item` | Indented ASCII bullets by nesting depth: `  * ` (level 0), `    - ` (level 1), `      + ` (level 2+) |
| **Ordered Lists** | `1. item`, `2. item` | Indented aligned numbers (`  1. `, `  2. `) |
| **Task Lists** | `- [ ] todo`, `- [x] done` | ASCII checkboxes `  [ ] ` and `  [x] ` (with `[x]` highlighted in cyan `\e[36m`) |
| **Tables** | Pipe tables `\| a \| b \|` | Aligned ASCII box tables (`+----+----+`, `\| a  \| b  \|`) with column alignment (`:---`, `:---:`, `---:`) and **Bold + Magenta** header cells |
| **Blockquotes** | `> quote` | Indented vertical bar `  \| ` in yellow (`$COLOR_DIM`) with nested `>>` support |
| **Horizontal Rules** | `---`, `***`, `___` | 60-column ASCII rule `  ------------------------------------------------------------` in `$COLOR_DIM` |
| **Links** | `[label](url)` | Underlined `label` (`\e[4m`) followed by `(url)` in cyan (`\e[36m`) |

## Implementation Phases

1. **Build System & Styling Constants (`src/header.pl`, `build.pl`, `t/build.t`)**
   - Add `$STYLE_BOLD`, `$STYLE_UNDERLINE`, `$COLOR_HEADER`, `$COLOR_CODE` to `src/header.pl` with `NO_COLOR` / non-TTY reset.
   - Register `src/markdown.pl` in `build.pl` before `src/ui.pl` and update `t/build.t`.
2. **Markdown Renderer Module (`src/markdown.pl`)**
   - Implement `render_markdown($text)` and `format_inline_markdown($text)` along with focused pure helpers (`_render_markdown_table`, `_split_table_row`, `_visible_width`, `_align_cell`, `_format_block_line`).
   - Add standalone CLI preview runner (`if (!caller && $0 =~ /markdown\.pl$/)`).
3. **UI & Main REPL Integration (`src/ui.pl`, `src/main.pl`)**
   - Make `slow_print` ANSI-escape-aware so SGR sequences print immediately with zero delay.
   - Route assistant text blocks in `src/main.pl` through `render_markdown()`.
4. **Testing & Refactoring Gates (`t/markdown.t`)**
   - Execute TDD Red-Green-Refactor cycles across all Markdown elements, `NO_COLOR` degradation, standalone CLI mode, and ANSI-aware `slow_print`.
   - Enforce CRAP < 10, zero duplication >= 0.8, and mutation killing.
5. **Context & Symbol Graph Update**
   - Refresh AST manifest, dependency graph, symbol graph, `context/signatures.md`, `AGENTS.md`, and `context/*.md`.
