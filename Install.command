#!/bin/bash
# Double-click this file in the Finder to install.
#
# This uses a prebuilt curl (TLS 1.2/1.3 capable, statically linked against
# OpenSSL 1.0.2u) so no compiling is needed on your Mac.

cd "$(dirname "$0")"
set -e

echo "=================================================="
echo " Code Agent for PowerPC Mac - Installer"
echo "=================================================="
echo ""

AGENT_DIR="$HOME/.code-agent"
TOOLCHAIN_DIR="$AGENT_DIR/toolchain"
BUILD_DIR="$AGENT_DIR/build"
BIN_DIR="$HOME/bin"

# Clean up legacy/old standalone directories if they exist
for old_dir in "$HOME/code-toolchain" "$HOME/code-build" "$HOME/claude-toolchain" "$HOME/claude-build"; do
  if [ -d "$old_dir" ]; then
    echo "Removing old $old_dir..."
    rm -rf "$old_dir"
  fi
done

mkdir -p "$AGENT_DIR"
chmod 700 "$AGENT_DIR"
mkdir -p "$TOOLCHAIN_DIR/bin"
mkdir -p "$BUILD_DIR/src"

echo "Installing curl (TLS 1.2/1.3 capable, prebuilt for PowerPC Tiger)..."
cp -f curl "$TOOLCHAIN_DIR/bin/curl"
chmod +x "$TOOLCHAIN_DIR/bin/curl"

if [ -f "build.pl" ] && [ -d "src" ]; then
  echo "Building code-agent.pl from src/..."
  perl build.pl
fi

echo "Installing the agent and CA certificate bundle..."
cp -f code-agent.pl "$BUILD_DIR/code-agent.pl"
cp -f cacert.pem "$BUILD_DIR/src/cacert.pem"

echo ""
echo "Checking that curl actually works on this Mac..."
if ! "$TOOLCHAIN_DIR/bin/curl" --version > /dev/null 2>&1; then
  echo ""
  echo "Error: the prebuilt curl did not run on this machine."
  echo "This binary was built and tested on an iBook G4 (Mac OS X 10.4.11 Tiger)."
  echo "It may not be compatible with your Mac's OS version or processor."
  echo ""
  echo "If you are on a modern Mac (Intel / Apple Silicon) or Linux, please run:"
  echo "  ./modern-install.command"
  echo ""
  echo "Otherwise, please build curl from source yourself -- see README.md"
  echo "(build/ directory) in the full project."
  echo ""
  printf "Press Enter to finish (this window may stay open; you can close it yourself): "
  read -r _
  exit 1
fi
echo "OK"
echo ""

# ------------------------------------------------------------------
# API key setup
# ------------------------------------------------------------------
CONFIG_DIR="$HOME/.code-agent"
ENV_FILE="$CONFIG_DIR/env"
CURL_BIN="$TOOLCHAIN_DIR/bin/curl"
CACERT="$BUILD_DIR/src/cacert.pem"
AGENT_SCRIPT="$BUILD_DIR/code-agent.pl"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$HOME/.code-agent-env" ]; then
    echo "Migrating legacy configuration from $HOME/.code-agent-env to $ENV_FILE..."
    mv "$HOME/.code-agent-env" "$ENV_FILE"
  elif [ -f "$HOME/.claude-agent-env" ]; then
    echo "Migrating legacy configuration from $HOME/.claude-agent-env to $ENV_FILE..."
    mv "$HOME/.claude-agent-env" "$ENV_FILE"
  fi
fi

if [ -f "$ENV_FILE" ]; then
  overwrite="n"
  echo "Using existing API key from $ENV_FILE (this is normal when upgrading)."
  echo "To set a different key, delete this file and run the installer again:"
  echo "  rm $ENV_FILE"
else
  overwrite="y"
fi

case "$overwrite" in
  y|Y)
    ENV_FILE="$CONFIG_DIR/env"
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
# code command
# ------------------------------------------------------------------
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/code" << WRAPEOF
#!/bin/bash
if [ -f "$HOME/.code-agent/env" ]; then
  source "$HOME/.code-agent/env"
fi
export CLAUDE_CURL=$CURL_BIN
export CLAUDE_CACERT=$CACERT
exec perl $AGENT_SCRIPT
WRAPEOF
chmod +x "$BIN_DIR/code"
echo "Created $BIN_DIR/code"

if ! grep -qF 'export PATH=$HOME/bin:$PATH' "$HOME/.bash_profile" 2>/dev/null; then
  echo "export PATH=\$HOME/bin:\$PATH" >> "$HOME/.bash_profile"
fi
echo ""

# ------------------------------------------------------------------
# connectivity check
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
  echo "Open a NEW Terminal window and just type: code"
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
