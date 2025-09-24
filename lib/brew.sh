#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

install_homebrew() {
  if ! exists brew; then
    log "Installing Homebrew to user directory (no sudo required)…"
    
    # Install Homebrew to user directory
    local homebrew_dir="$HOME/.homebrew"
    mkdir -p "$homebrew_dir"
    
    # Download and extract Homebrew
    curl -fsSL https://github.com/Homebrew/brew/tarball/main | tar xz --strip-components 1 -C "$homebrew_dir"
    
    # Set up environment
    eval "$("$homebrew_dir/bin/brew" shellenv)"
    
    # Ensure brew for login shells
    if ! grep -q 'brew shellenv' "$ZPROFILE" 2>/dev/null; then
      printf '\n%s\n' "eval \"\$(\"$homebrew_dir/bin/brew\" shellenv)\"" >> "$ZPROFILE"
    fi
    
    # Initialize Homebrew
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh" 2>/dev/null || true
  else
    # If brew already exists, ensure it's in PATH
    if [[ -x "$HOME/.homebrew/bin/brew" ]]; then
      eval "$("$HOME/.homebrew/bin/brew" shellenv)"
    elif [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
}

brew_update() {
  log "Updating Homebrew and taps…"
  brew update
}

brew_is_formula() {
  # Heuristic: brew info --formula returns 0 if exists
  brew info --formula "$1" >/dev/null 2>&1
}

brew_is_cask() {
  brew info --cask "$1" >/dev/null 2>&1
}

brew_installed_formula() { brew list --formula --versions | awk '{print $1}' | grep -Fxq "$1"; }
brew_installed_cask()    { brew list --cask    --versions | awk '{print $1}' | grep -Fxq "$1"; }

brew_install_formula() {
  local name="$1"
  if brew_installed_formula "$name"; then
    log "brew formula already installed: $name"
  else
    log "brew install $name"
    brew install "$name"
  fi
}

brew_install_cask() {
  local name="$1"
  if brew_installed_cask "$name"; then
    log "brew cask already installed: $name"
  else
    log "brew install --cask $name"
    brew install --cask "$name"
  fi
}

brew_install_from_list() {
  local file="$1" mode="$2" line
  [[ -f "$file" ]] || die "Missing list: $file"
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ "$mode" == "formula" ]]; then
      brew_install_formula "$line"
    else
      brew_install_cask "$line"
    fi
  done < "$file"
}

brew_append_config() {
  local list_file="$1" item="$2"
  grep -Fxq "$item" "$list_file" 2>/dev/null || append_line "$item" "$list_file"
}
