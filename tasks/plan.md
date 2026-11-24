# Architecture Plan: Stability, Performance & Ergonomics Improvements

## Objectives
Implement the approved improvements from the evaluation:
1. **Pure-Perl JSON Edge-Case Hardening**: Fix UTF-16 surrogate pair decoding (`\uXXXX\uXXXX`) in `src/json.pl` (`MiniJSON`), add comprehensive unit tests in `t/json.t` covering Unicode surrogate pairs, nested structures, line endings (`\r\n`, `\r`, `\n`), and control characters.
2. **Perl 5.8.6 Compatibility Enforcement in CI**: Update `.github/workflows/test.yml` to mechanically ensure compatibility with Perl 5.8.6 on every commit (using `Perl::MinimumVersion` or container-based 5.8.6 checks).
3. **Context & Token Budgeting for Slow CPUs**: Prevent unbounded context bloat and heavy pure-Perl JSON re-serialization on vintage PowerPC hardware by implementing tool output compaction for older turns in `src/session.pl` and `src/main.pl` (preserving strict `tool_use`/`tool_result` ID pairs).
4. **Interactive Local / OpenAI Server Configuration**: Upgrade `/openai` in `src/main.pl` so that if `OPENAI_BASE_URL` is unset, it interactively prompts the user for the server URL (e.g. `http://192.168.1.x:11434/v1`) and offers to persist it in `~/.code-agent/env`, matching the `/gemini` and `/claude` UX.

## Target Constraints
- 100% pure Perl 5.8.6 standard library only, zero CPAN runtime dependencies.
- Compatible with Mac OS X 10.4 Tiger (PowerPC G3/G4/G5).
- Maintain source-to-build sync (`perl build.pl`).
- All existing and new tests in `t/` must pass cleanly.
