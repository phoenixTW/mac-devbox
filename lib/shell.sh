#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

install_xcode_cli() {
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Installing Xcode Command Line Tools (may show GUI)…"
    xcode-select --install || true
  fi
}

ensure_zsh_default() {
  if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
    warn "Switching default shell to zsh (may ask for password)…"
    chsh -s /bin/zsh || warn "Could not change shell automatically."
  fi
}

install_oh_my_zsh() {
  local ZSH_DIR="$HOME/.oh-my-zsh"
  export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
  if [[ ! -d "$ZSH_DIR" ]]; then
    log "Installing oh-my-zsh (unattended)…"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    log "oh-my-zsh already installed."
  fi

  if ! grep -q '# >>> managed by devbox' "$ZSHRC" 2>/dev/null; then
    log "Configuring oh-my-zsh (agnoster + plugins)…"
    {
      echo ''
      echo '# >>> managed by devbox'
      echo "export ZSH=\"$ZSH_DIR\""
      echo 'ZSH_THEME="agnoster"'
      echo 'plugins=(git asdf direnv)'
      echo "source \$ZSH/oh-my-zsh.sh"
      echo '# <<< managed by devbox'
    } >> "$ZSHRC"
  fi
}

first_launch_apps() {
  open -gj "$HOME/Applications/Docker.app" 2>/dev/null || true
  if [[ -d "$HOME/Applications/FortiClient.app" ]]; then
    open -gj "$HOME/Applications/FortiClient.app" || true
  elif [[ -d "$HOME/Applications/FortiClientVPN.app" ]]; then
    open -gj "$HOME/Applications/FortiClientVPN.app" || true
  fi
}
