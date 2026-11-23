# Dependencies & Ecosystem

This document inventories internal module relationships, system toolchains, bundled binaries, and external network APIs.

---

## Internal Dependency Graph

- **Application Entrypoint**:
  - [`code-agent.pl`](../code-agent.pl): Standalone agent. Invokes `curl` via shell/exec for HTTPS operations.
- **Installer Entrypoint**:
  - [`Install.command`](../Install.command): Copies and provisions `code-agent.pl`, `curl`, and `cacert.pem` into `$HOME/code-toolchain` and `$HOME/code-build` for PowerPC Tiger.
  - [`modern-install.command`](../modern-install.command): Provisions `code-agent.pl` and `cacert.pem` using host curl and perl on modern macOS and Linux.
- **Generated Wrapper**:
  - `$HOME/bin/code` and `$HOME/bin/code-agent`: Sourced shell wrappers pointing to `$HOME/.code-agent-env`, curl, and `$HOME/code-build/code-agent.pl`.
- **Environment Configuration**:
  - `$HOME/.code-agent-env`: Persistent credentials and preferences file (`0600` permissions), with fallback to legacy `~/.claude-agent-env`. Sourced by wrapper scripts and parsed by `src/header.pl`.
  - `$HOME/.code-agent-mcp.json` / `mcp_servers.json`: Persistent MCP server configuration file discovered by `src/mcp.pl` (or configured via `CLAUDE_MCP_CONFIG` / `CLAUDE_MCP_SERVERS`).

---

## Third-Party Libraries & Bundled Assets

| Asset / Library | Type | Purpose | Key Usage Files |
| :--- | :--- | :--- | :--- |
| [`curl`](../curl) | Prebuilt PPC Darwin binary | TLS 1.2/1.3-capable HTTPS transport (statically linked against OpenSSL 1.0.2u) | [`Install.command`](../Install.command), [`code-agent.pl`](../code-agent.pl) |
| [`cacert.pem`](../cacert.pem) | CA Cert Bundle | Mozilla root certificates for verifying TLS certificates | [`Install.command`](../Install.command), [`code-agent.pl`](../code-agent.pl) |
| `Encode` | Perl Core Module | Character set conversion (UTF-8) with fallback handling (`FB_DEFAULT`) | [`code-agent.pl`](../code-agent.pl) |
| `stty` | Mac OS X System Utility | Terminal line discipline configuration (raw mode, echo toggling) | [`code-agent.pl`](../code-agent.pl), [`Install.command`](../Install.command) |

---

## External Services & Network APIs

| Endpoint | Protocol | Provider | Purpose |
| :--- | :--- | :--- | :--- |
| `https://api.anthropic.com/v1/messages` | HTTPS (TLS 1.2/1.3) | Anthropic | Claude 3.5 Sonnet / Claude Sonnet 4.5 LLM chat completions and tool calls |
| `https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent` | HTTPS (TLS 1.2/1.3) | Google | Gemini models (`gemini-3.5-flash-lite`, etc.) chat and tool use |
| `http://{LAN_HOST}:{PORT}/v1/chat/completions` | HTTP/HTTPS | Local / Self-Hosted | OpenAI-compatible local LLM endpoints (Ollama, llama.cpp, LM Studio) |
| `http://{HOST}:{PORT}/...` | HTTP/HTTPS (JSON-RPC 2.0) | Remote MCP Servers | Model Context Protocol dynamic tool discovery (`tools/list`) and execution (`tools/call`) |
