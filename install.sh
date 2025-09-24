#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-phoenixTW/mac-devbox}"

# Debug mode (hidden from users)
DEBUG="${DEVBOX_DEBUG:-0}"

# Function to detect REF from various sources
detect_ref() {
  local detected_ref=""
  
  # Method 1: Try to detect from HTTP_REFERER if available
  if [[ -n "${HTTP_REFERER:-}" ]]; then
    detected_ref=$(echo "$HTTP_REFERER" | grep -oE 'refs/tags/[^/]+' | sed 's|refs/tags/||' 2>/dev/null || true)
    [[ "$DEBUG" == "1" ]] && echo "DEBUG: Detected REF from HTTP_REFERER: $detected_ref" >&2
  fi
  
  # Method 2: Try to read from local lib/common.sh if available
  if [[ -z "$detected_ref" && -f "lib/common.sh" ]]; then
    detected_ref=$(grep 'get_version()' lib/common.sh | sed 's/.*echo "\([^"]*\)".*/\1/' 2>/dev/null || true)
    [[ "$DEBUG" == "1" ]] && echo "DEBUG: Detected REF from lib/common.sh: $detected_ref" >&2
  fi
  
  # Method 3: Fallback to latest release from GitHub API (simple approach without jq)
  if [[ -z "$detected_ref" ]]; then
    detected_ref=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' || echo "main")
    [[ "$DEBUG" == "1" ]] && echo "DEBUG: Detected REF from GitHub API: $detected_ref" >&2
  fi
  
  # Final fallback
  echo "${detected_ref:-main}"
}

# If we're running from a commit SHA (detected by checking if we're in a git repo with a commit SHA)
if [[ -n "${GITHUB_SHA:-}" ]]; then
  REF="${REF:-$GITHUB_SHA}"
  [[ "$DEBUG" == "1" ]] && echo "DEBUG: Using GITHUB_SHA as REF: $REF" >&2
else
  REF="${REF:-$(detect_ref)}"
fi
CONFIG_DIR="${DEVBOX_CONFIG_DIR:-$HOME/.devbox}"
BIN_DIR="$HOME/.local/bin"

TMP="$(mktemp -d)"
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT

echo "Fetching $REPO@$REF..."
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" -o "$TMP/src.tar.gz"
tar -xzf "$TMP/src.tar.gz" -C "$TMP"
# Find the extracted directory (should be the only one)
EXTRACTED_DIR=$(find "$TMP" -maxdepth 1 -type d -name "*" | grep -v "^$TMP$" | head -1)
if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "❌ Failed to find extracted directory"
  exit 1
fi
cd "$EXTRACTED_DIR"

# Install devbox binary and lib files
mkdir -p "$BIN_DIR"
install -m 0755 bin/devbox "$BIN_DIR/devbox"

# Install lib directory (required by devbox binary)
LIB_DIR="$BIN_DIR/../lib"
mkdir -p "$LIB_DIR"
cp -r lib/* "$LIB_DIR/"

# Ensure ~/.local/bin on PATH
if ! grep -q "\$HOME/.local/bin" "$HOME/.zprofile" 2>/dev/null; then
  {
    echo ''
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
  } >> "$HOME/.zprofile"
fi

# Initialize ~/.devbox with defaults if missing
mkdir -p "$CONFIG_DIR"
[[ -f "$CONFIG_DIR/brew-formulae.txt" ]] || cp config.defaults/brew-formulae.txt "$CONFIG_DIR/brew-formulae.txt"
[[ -f "$CONFIG_DIR/brew-casks.txt"    ]] || cp config.defaults/brew-casks.txt    "$CONFIG_DIR/brew-casks.txt"
[[ -f "$CONFIG_DIR/asdf-tools.json"    ]] || cp config.defaults/asdf-tools.json    "$CONFIG_DIR/asdf-tools.json"

# Install completions
ZSH_COMP_DIR="${ZSH_COMP_DIR:-$HOME/.zsh/completions}"
BASH_COMP_DIR="${BASH_COMP_DIR:-$HOME/.bash_completion.d}"
mkdir -p "$ZSH_COMP_DIR" "$BASH_COMP_DIR"
install -m 0644 completions/devbox.zsh  "$ZSH_COMP_DIR/_devbox"
install -m 0644 completions/devbox.bash "$BASH_COMP_DIR/devbox"

# Enable zsh completion if not enabled
ZSHRC="$HOME/.zshrc"
if ! grep -q '# >>> devbox completions' "$ZSHRC" 2>/dev/null; then
  {
    echo ''
    echo '# >>> devbox completions'
    echo "fpath=(\"\$HOME/.zsh/completions\" \$fpath)"
    echo 'autoload -Uz compinit'
    echo "[[ -n \"\$ZDOTDIR\" ]] && compinit -d \"\$ZDOTDIR/.zcompdump\" || compinit"
    echo '# <<< devbox completions'
  } >> "$ZSHRC"
fi

echo ""
echo "Installed devbox to $BIN_DIR/devbox and initialized config at $CONFIG_DIR"
echo "Tab completion installed for zsh (~/.zsh/completions) and bash (~/.bash_completion.d)."
echo "Open a new terminal (or run: source ~/.zprofile && source ~/.zshrc) then execute:"
echo "  devbox bootstrap"
