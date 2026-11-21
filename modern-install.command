#!/bin/bash
# Double-click this file in the Finder or run via terminal:
#   ./modern-install.command
#
# Installer for modern macOS (Intel / Apple Silicon) and Linux systems.
# Uses the system-provided curl and certificates instead of the vintage PowerPC toolchain.

cd "$(dirname "$0")"
set -e

echo "=================================================="
echo " Code Agent for Modern macOS / Linux - Installer"
echo "=================================================="
echo ""

# ------------------------------------------------------------------
# Dependency checks
# ------------------------------------------------------------------
if ! command -v perl >/dev/null 2>&1; then
  echo "Error: 'perl' was not found in your PATH."
  echo "Please install Perl before running this installer."
  echo "  - macOS: brew install perl (or install Command Line Tools: xcode-select --install)"
  echo "  - Debian/Ubuntu: sudo apt-get install perl"
  echo "  - Fedora/RHEL: sudo dnf install perl"
  echo "  - Arch Linux: sudo pacman -S perl"
  echo ""
  printf "Press Enter to finish (this window may stay open; you can close it yourself): "
  read -r _
  exit 1
fi

CURL_BIN="$(command -v curl 2>/dev/null || true)"
if [ -z "$CURL_BIN" ] || [ ! -x "$CURL_BIN" ]; then
  echo "Error: 'curl' was not found in your PATH."
  echo "Please install curl before running this installer."
  echo "  - macOS: brew install curl"
  echo "  - Debian/Ubuntu: sudo apt-get install curl"
  echo "  - Fedora/RHEL: sudo dnf install curl"
  echo "  - Arch Linux: sudo pacman -S curl"
  echo ""
  printf "Press Enter to finish (this window may stay open; you can close it yourself): "
  read -r _
  exit 1
fi

echo "Found Perl: $(command -v perl)"
echo "Found curl: $CURL_BIN"
if ! "$CURL_BIN" --version > /dev/null 2>&1; then
  echo "Error: '$CURL_BIN' failed to execute."
  exit 1
fi
echo ""

BUILD_DIR="$HOME/code-build"
BIN_DIR="$HOME/bin"

mkdir -p "$BUILD_DIR/src"
mkdir -p "$BIN_DIR"

if [ -f "build.pl" ] && [ -d "src" ]; then
  echo "Building code-agent.pl from src/..."
  perl build.pl
fi

echo "Installing the agent and CA certificate bundle..."
cp -f code-agent.pl "$BUILD_DIR/code-agent.pl"
chmod +x "$BUILD_DIR/code-agent.pl"
cp -f cacert.pem "$BUILD_DIR/src/cacert.pem"

CACERT="$BUILD_DIR/src/cacert.pem"
AGENT_SCRIPT="$BUILD_DIR/code-agent.pl"

# ------------------------------------------------------------------
# API key setup
# ------------------------------------------------------------------
ENV_FILE="$HOME/.code-agent-env"
LEGACY_ENV_FILE="$HOME/.claude-agent-env"

if [ -f "$ENV_FILE" ]; then
  overwrite="n"
  echo "Using existing API key from $ENV_FILE (this is normal when upgrading)."
  echo "To set a different key, delete this file and run the installer again:"
  echo "  rm $ENV_FILE"
elif [ -f "$LEGACY_ENV_FILE" ]; then
  overwrite="n"
  ENV_FILE="$LEGACY_ENV_FILE"
  echo "Using existing API key from legacy $LEGACY_ENV_FILE (this is normal when upgrading)."
  echo "To set a different key, delete this file and run the installer again:"
  echo "  rm $LEGACY_ENV_FILE"
else
  overwrite="y"
fi

case "$overwrite" in
  y|Y)
    ENV_FILE="$HOME/.code-agent-env"
    echo ""
    echo "Which AI should this agent talk to?"
    echo "  1) Anthropic (Claude) - most capable, pay-as-you-go billing, needs a credit card"
    echo "  2) Gemini (Google) - free tier, no credit card needed, plenty for casual chatting"
    echo ""
    printf "Enter 1 or 2 (default: 2): "
    read -r PROVIDER_CHOICE
    echo ""

    case "$PROVIDER_CHOICE" in
      1)
        PROVIDER="anthropic"
        echo "You need an Anthropic API key. If you don't have one yet:"
        echo "  1. Open https://console.anthropic.com/ (NOT the same site as claude.ai)"
        echo "  2. Create an account / sign in"
        echo "  3. Go to 'API Keys' in the left menu and create a new key"
        echo "  4. Add a small amount of credit under 'Billing' (pay-as-you-go)"
        echo ""
        echo "Note: this is NOT the password you use to log in to claude.ai."
        echo "The API key is a long string starting with 'sk-ant-api03-'."
        echo ""
        ;;
      *)
        PROVIDER="gemini"
        echo "You need a Gemini API key (free, no credit card required). If you don't have one yet:"
        echo "  1. Open https://aistudio.google.com/apikey"
        echo "  2. Sign in with any Google account"
        echo "  3. Click 'Create API key' and choose (or create) a Google Cloud project"
        echo "  4. No billing/credit card setup is needed for the free tier"
        echo ""
        echo "The API key usually starts with 'AIzaSy', though Google sometimes issues other formats too."
        echo ""
        ;;
    esac

    printf "Paste your API key and press Enter (it will not be shown): "
    stty -echo 2>/dev/null || true
    read -r API_KEY
    stty echo 2>/dev/null || true
    echo ""

    API_KEY=$(echo "$API_KEY" | sed 's/^[ \t]*//;s/[ \t]*$//')

    if [ -z "$API_KEY" ]; then
      echo "Error: nothing was entered. Please run this installer again."
      printf "Press Enter to finish (this window may stay open; you can close it yourself): "
      read -r _
      exit 1
    fi

    case "$API_KEY" in
      \<*|*\>)
        echo "Error: found '<' or '>' in the input."
        echo "Did you accidentally paste the placeholder brackets from an example?"
        echo "Paste just the key value, without the angle brackets, and run this again."
        printf "Press Enter to finish (this window may stay open; you can close it yourself): "
        read -r _
        exit 1
        ;;
    esac

    if [ "$PROVIDER" = "anthropic" ]; then
      case "$API_KEY" in
        sk-ant-api*) ;;
        *)
          echo "Warning: this doesn't start with 'sk-ant-api'."
          echo "Did you paste your claude.ai password or something else by mistake?"
          echo "Continuing anyway, but the connectivity check below may fail."
          ;;
      esac

      key_len=$(echo -n "$API_KEY" | wc -c | tr -d ' ')
      if [ "$key_len" -lt 50 ]; then
        echo "Warning: the key is only ${key_len} characters. Was it cut off during copy?"
      fi

      {
        printf 'export CLAUDE_PROVIDER=anthropic\n'
        printf 'export ANTHROPIC_API_KEY=%s\n' "$API_KEY"
      } > "$ENV_FILE"
    else
      {
        printf 'export CLAUDE_PROVIDER=gemini\n'
        printf 'export GEMINI_API_KEY=%s\n' "$API_KEY"
      } > "$ENV_FILE"
    fi
    chmod 600 "$ENV_FILE"
    echo "Saved to $ENV_FILE (readable only by your account)"
    ;;
  *)
    echo "Keeping the existing key."
    ;;
esac
echo ""

# ------------------------------------------------------------------
# Deploy CLI wrappers
# ------------------------------------------------------------------
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/code-agent" << WRAPEOF
#!/bin/bash
if [ -f "\$HOME/.code-agent-env" ]; then
  source "\$HOME/.code-agent-env"
elif [ -f "\$HOME/.claude-agent-env" ]; then
  source "\$HOME/.claude-agent-env"
fi
export CLAUDE_CURL="$CURL_BIN"
export CLAUDE_CACERT="$CACERT"
exec perl "$AGENT_SCRIPT" "\$@"
WRAPEOF
chmod +x "$BIN_DIR/code-agent"
echo "Created $BIN_DIR/code-agent"

INSTALL_CODE_ALIAS="y"
if command -v code >/dev/null 2>&1; then
  EXISTING_CODE="$(command -v code)"
  if [ "$EXISTING_CODE" != "$BIN_DIR/code" ] && ! grep -q "code-agent" "$EXISTING_CODE" 2>/dev/null; then
    echo ""
    echo "Notice: An existing 'code' command was detected at:"
    echo "  $EXISTING_CODE"
    echo "This usually belongs to Visual Studio Code."
    echo "To avoid overriding your editor, we installed '$BIN_DIR/code-agent'."
    echo "You can launch the agent using: code-agent"
    INSTALL_CODE_ALIAS="n"
  fi
fi

if [ "$INSTALL_CODE_ALIAS" = "y" ]; then
  ln -sf "$BIN_DIR/code-agent" "$BIN_DIR/code"
  echo "Created alias $BIN_DIR/code -> $BIN_DIR/code-agent"
fi

# ------------------------------------------------------------------
# PATH configuration
# ------------------------------------------------------------------
PATH_LINE='export PATH="$HOME/bin:$PATH"'
add_path_to_rc() {
  local rc_file="$1"
  local should_create="$2"
  if [ -f "$rc_file" ] || [ "$should_create" = "create" ]; then
    if ! grep -qF 'export PATH=$HOME/bin:$PATH' "$rc_file" 2>/dev/null && \
       ! grep -qF 'export PATH="$HOME/bin:$PATH"' "$rc_file" 2>/dev/null; then
      echo "$PATH_LINE" >> "$rc_file"
      echo "Added $BIN_DIR to $rc_file"
    fi
  fi
}

CURRENT_SHELL="$(basename "${SHELL:-bash}")"
if [ "$CURRENT_SHELL" = "zsh" ] || [ -f "$HOME/.zshrc" ]; then
  add_path_to_rc "$HOME/.zshrc" "create"
fi

if [ "$CURRENT_SHELL" = "bash" ] || [ -f "$HOME/.bashrc" ] || [ -f "$HOME/.bash_profile" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    add_path_to_rc "$HOME/.bash_profile" "create"
  else
    add_path_to_rc "$HOME/.bashrc" "create"
  fi
fi

if [ -f "$HOME/.profile" ]; then
  add_path_to_rc "$HOME/.profile" "keep"
fi
echo ""

# ------------------------------------------------------------------
# Connectivity check
# ------------------------------------------------------------------
echo "Checking API connectivity..."
source "$ENV_FILE"
CLAUDE_PROVIDER="${CLAUDE_PROVIDER:-anthropic}"
RESPONSE_FILE="/tmp/claude-install-check-$$.json"

if [ "$CLAUDE_PROVIDER" = "gemini" ]; then
  MODEL="${CLAUDE_MODEL:-gemini-3.5-flash-lite}"
  # If thinkingConfig is omitted, Gemini 3.x defaults to "HIGH" (deep thinking)
  # which can delay even a basic connectivity check by dozens of seconds, so explicitly set LOW.
  HTTP_CODE=$("$CURL_BIN" -s --cacert "$CACERT" \
    "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent" \
    -H "x-goog-api-key: $GEMINI_API_KEY" \
    -H "content-type: application/json" \
    -d '{"contents":[{"role":"user","parts":[{"text":"hi"}]}],"generationConfig":{"maxOutputTokens":10,"thinkingConfig":{"thinkingLevel":"LOW"}}}' \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}")
else
  HTTP_CODE=$("$CURL_BIN" -s --cacert "$CACERT" \
    https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}' \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}")
fi

echo ""
if [ "$HTTP_CODE" = "200" ]; then
  echo "=================================================="
  echo " Setup complete!"
  echo "=================================================="
  echo ""
  if [ -e "$BIN_DIR/code" ] && [ "$INSTALL_CODE_ALIAS" = "y" ]; then
    echo "Open a NEW Terminal window and type: code (or code-agent)"
  else
    echo "Open a NEW Terminal window and type: code-agent"
  fi
else
  echo "API error (HTTP $HTTP_CODE)."
  if [ "$CLAUDE_PROVIDER" = "gemini" ]; then
    echo "Check that your Gemini API key is correct."
  else
    echo "Check that your key is correct and that you have credit charged in the Console."
  fi
  echo "--- Server response ---"
  cat "$RESPONSE_FILE"
  echo ""
fi
rm -f "$RESPONSE_FILE"

echo ""
printf "Press Enter to finish (this window may stay open; you can close it yourself): "
read -r _
