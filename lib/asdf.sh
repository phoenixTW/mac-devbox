#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

asdf_init() {
  if ! exists asdf; then
    die "asdf not installed (brew should have installed it)."
  fi
  local asdf_prefix
  asdf_prefix="$(brew --prefix asdf)"
  # shellcheck disable=SC1090
  source "$asdf_prefix/libexec/asdf.sh"
  # Persist init for interactive shells
  grep -q 'asdf.sh' "$ZSHRC" 2>/dev/null || printf '\nsource "%s/libexec/asdf.sh"\n' "$asdf_prefix" >> "$ZSHRC"
  grep -q 'direnv hook zsh' "$ZSHRC" 2>/dev/null || printf '\neval "$(direnv hook zsh)"\n' >> "$ZSHRC"
}

asdf_plugin_present() { asdf plugin list | grep -Fxq "$1"; }

asdf_ensure_plugin() {
  local name="$1" repo="$2"
  if asdf_plugin_present "$name"; then
    log "asdf plugin already present: $name"
  else
    if [[ -n "$repo" ]]; then
      log "asdf plugin add $name ($repo)"
      asdf plugin add "$name" "$repo"
    else
      log "asdf plugin add $name"
      asdf plugin add "$name"
    fi
  fi
}

asdf_install_tool() {
  local name="$1" version="$2"

  case "$name" in
    nodejs)
      asdf_ensure_plugin "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"
      if [[ -x "$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring" ]]; then
        bash "$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring" || true
      fi
      ;;
    golang)
      asdf_ensure_plugin "golang" "https://github.com/asdf-community/asdf-golang.git"
      ;;
    *)
      asdf_ensure_plugin "$name" ""
      ;;
  esac

  if [[ "$version" == "latest" ]]; then
    version="$(asdf latest "$name")"
  fi

  if asdf list "$name" 2>/dev/null | sed 's/^[[:space:]]*//' | grep -Fxq "$version"; then
    log "asdf $name@$version already installed"
  else
    log "asdf install $name $version"
    asdf install "$name" "$version"
  fi

  # set global if not already
  if [[ "$(asdf current "$name" 2>/dev/null | awk '{print $2}')" != "$version" ]]; then
    asdf global "$name" "$version"
  fi

  asdf reshim
}

asdf_install_from_json() {
  local json="$1" name version
  [[ -f "$json" ]] || die "Missing config: $json"
  require_cmd jq
  while IFS= read -r name; do
    version="$(jq -r --arg k "$name" '.[$k]' "$json")"
    [[ -z "$version" || "$version" == "null" ]] && continue
    asdf_install_tool "$name" "$version"
  done < <(jq -r 'keys[]' "$json")
}

asdf_persist_tool() {
  local json="$1" name="$2" version="$3"
  [[ "$version" == "latest" ]] && version="$(asdf latest "$name")"
  json_set_kv "$json" "$name" "$version"
}
