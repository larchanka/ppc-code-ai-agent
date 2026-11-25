Code Agent for PowerPC Mac (Tiger / 10.4)
============================================

HOW TO INSTALL
---------------------------------
1. Copy this whole folder onto your PowerPC Mac (USB stick, file sharing, etc.)

2. Double-click "Install.command".

3. A Terminal window opens. Choose Anthropic (Claude) or Gemini (Google) --
   Gemini has a free tier that needs no credit card at all. Then follow the
   prompts for that provider's API key (the installer explains how to get one).

4. When it says "Setup complete!", open a NEW Terminal window and type:

       code

That's it. No compiling, no MacPorts, no Xcode required.

USING THE AGENT
-------------------------
Once started, you can chat with the agent or enter slash commands:
- /new     : Start a new conversation (clears history and resets context)
- /compact : Compact history by truncating older tool results for slow CPUs
- /models  : View and switch available AI models
- /ctx     : View or set max output tokens per response (default: 4k; e.g. /ctx 64k, /ctx 65536)
- /mcp     : Manage remote MCP servers and tools (/mcp list, add, remove, refresh)
- /claude  : Switch to Anthropic Claude
- /gemini  : Switch to Google Gemini
- /openai  : Switch to OpenAI endpoint (interactively prompts for URL if unset; alias: /local)
- /auto    : Enable autonomous mode (run tools without confirmation)
- /manual  : Enable manual mode (require confirmation before file/shell actions)
- /help    : Show available commands
- exit     : Exit the agent (or press Ctrl-D)

The agent can also autonomously delegate tasks to specialized sub-agents
("plan" for read-only exploration, "build" for implementation) with their
own isolated context to keep conversation history clean.

REMOTE MCP SUPPORT (MODEL CONTEXT PROTOCOL)
--------------------------------------------
The agent supports Model Context Protocol (MCP) servers over HTTP/JSON-RPC.
Servers can be configured via ~/.code-agent/mcp.json, ./mcp_servers.json,
or environment variables:
{
  "mcpServers": {
    "weather": {
      "url": "http://192.168.1.50:8000/mcp",
      "headers": { "Authorization": "Bearer token123" }
    }
  }
}
At runtime, manage servers via "/mcp":
- /mcp or /mcp list             : View connected servers and tools
- /mcp add <name> <url> [headers]: Connect and discover tools
- /mcp remove <name>            : Disconnect server and purge its tools
- /mcp refresh (or /mcp reload) : Re-query tools from all servers

In addition, the agent automatically discovers custom instructions from
"~/.agents/AGENTS.md" and "./AGENTS.md", as well as reusable skills from
"~/.agents/skills/<name>/SKILL.md" and "./.agents/skills/<name>/SKILL.md"
(indexed by YAML frontmatter and loaded on demand via read_file).

REQUIREMENTS
------------------------
- A PowerPC Mac running Mac OS X 10.4 (Tiger) -- tested on an iBook G4
  (PowerBook6,5). Other PowerPC Macs on Tiger should work too, since the
  bundled curl was built without CPU-specific optimizations, but this
  hasn't been tested on every model. If "Install.command" reports that
  curl doesn't run on your machine, see the full project (README.md,
  build/ folder) to build it from source instead.

- Either an Anthropic API key (usage is billed separately, pay-as-you-go, at
  console.anthropic.com -- this is NOT the same as a claude.ai subscription)
  or a Gemini API key (free tier, no credit card needed, at
  aistudio.google.com/apikey). The installer asks which one you want.

WHAT'S INSIDE
-------------------------
- curl            : prebuilt, TLS 1.2/1.3-capable curl for PowerPC/Tiger
- cacert.pem       : current CA certificate bundle
- code-agent.pl    : the agent itself (single Perl file, no dependencies)
- build.pl         : build script to reassemble code-agent.pl from src/
- src/             : 13 modular source files for the agent (including prompts.pl, mcp.pl)
- scripts/         : verification and CI scripts (e.g. check_minimum_version.pl)
- Install.command         : installer for PowerPC Mac OS X Tiger
- modern-install.command  : installer for modern macOS (Intel/ARM) and Linux

CONFIGURATION & ENVIRONMENT
-------------------------
Settings and API keys are stored in "$HOME/.code-agent/env" (permissions 0600):
- CLAUDE_PROVIDER   : Default provider ("gemini", "anthropic", or "openai")
- GEMINI_API_KEY    : Google Gemini API key
- ANTHROPIC_API_KEY : Anthropic Claude API key
- OPENAI_BASE_URL   : Local LAN endpoint (e.g. http://192.168.1.100:11434/v1)
- OPENAI_API_KEY    : Local endpoint key ("none")
- CLAUDE_MODEL      : Override model name
- CLAUDE_AUTO_MODE  : "1" for autonomous mode, "0" for manual confirmations
- CLAUDE_MAX_RETRIES: Max retry attempts on LLM API errors (default: 3)
- CLAUDE_RETRY_DELAY: Delay in seconds between API retries (default: 5)
- CLAUDE_AUTO_COMPACT: Enable automatic tool result compaction (default: 1)
- CLAUDE_COMPACT_THRESHOLD_CHARS: Chars threshold before auto-compaction (100000)
- CLAUDE_COMPACT_THRESHOLD_TURNS: User turns threshold before auto-compaction (10)
- CLAUDE_MCP_CONFIG : Path to MCP configuration JSON file
- CLAUDE_MCP_SERVERS: Inline JSON string of MCP server configurations

To view or edit: nano ~/.code-agent/env
To change keys: rm ~/.code-agent/env and run Install.command again.
Legacy ~/.code-agent-env and ~/.claude-agent-env files are automatically
migrated into ~/.code-agent/env during installation.

BUILDING FROM SOURCE
-------------------------
If modifying the agent source code in src/:
1. Run "perl build.pl" to assemble code-agent.pl.
2. Run "perl build.pl --check" to verify sync.
3. Run "perl scripts/check_minimum_version.pl --perl 5.008006 code-agent.pl src/*.pl"
   to verify strict Perl 5.8.6 syntax compatibility.
4. Run "prove -v t/*.t" to run tests.
Install.command also runs "perl build.pl" automatically when src/ is present.

More detail, and how to build everything from source, is in the full
project's README.md.
