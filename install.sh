#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-phoenixTW/mac-devbox}"
REF="${REF:-main}"
CONFIG_DIR="${DEVBOX_CONFIG_DIR:-$HOME/.devbox}"
BIN_DIR="$HOME/.local/bin"

TMP="$(mktemp -d)"
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT

echo "Fetching $REPO@$REF…"
curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" -o "$TMP/src.tar.gz"
tar -xzf "$TMP/src.tar.gz" -C "$TMP"
cd "$TMP"/*

# Install devbox binary
mkdir -p "$BIN_DIR"
install -m 0755 bin/devbox "$BIN_DIR/devbox"

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
