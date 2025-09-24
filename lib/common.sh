#!/usr/bin/env bash
set -euo pipefail

# Colors
_bold="$(printf '\033[1m')"; _green="$(printf '\033[32m')"
_yellow="$(printf '\033[33m')"; _red="$(printf '\033[31m')"; _reset="$(printf '\033[0m')"

log()  { printf "\n${_bold}${_green}▶ %s${_reset}\n" "$*"; }
warn() { printf "\n${_bold}${_yellow}⚠ %s${_reset}\n" "$*"; }
err()  { printf "\n${_bold}${_red}✖ %s${_reset}\n" "$*"; }
die()  { err "$*"; exit 1; }

exists()   { command -v "$1" >/dev/null 2>&1; }
require_cmd() { exists "$1" || die "Required command '$1' not found"; }

# --- Version information -----------------------------------------------------
get_version() { echo "0.0.4"; }
show_version() { echo "devbox version $(get_version)"; }

# --- Basic security validation -----------------------------------------------
validate_config_dir() {
  local dir="$1"
  [[ -n "$dir" ]] || die "Config directory cannot be empty"
  [[ "$dir" =~ ^[a-zA-Z0-9._/-]+$ ]] || die "Invalid config directory path"
  [[ "$dir" != *".."* ]] || die "Config directory cannot contain '..'"
}

validate_config_file() {
  local file="$1"
  [[ -f "$file" ]] || die "Config file not found: $file"
  [[ -r "$file" ]] || die "Config file not readable: $file"
  [[ -s "$file" ]] || die "Config file is empty: $file"
}

# --- Config directory resolution ---------------------------------------------
DEFAULT_CONFIG_DIR="${HOME}/.devbox"
CONFIG_DIR="${DEVBOX_CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"

# Allow an explicit --config <DIR> override from bin/devbox
set_config_dir() {
  validate_config_dir "$1"
  CONFIG_DIR="$1"
  export DEVBOX_CONFIG_DIR="$CONFIG_DIR"
}

ensure_dir()  { [[ -d "$1" ]] || mkdir -p "$1"; }
ensure_file() { [[ -f "$1" ]] || touch "$1"; }

append_if_missing() {
  local needle="$1" file="$2"
  grep -Fqx "$needle" "$file" 2>/dev/null || printf "%s\n" "$needle" >> "$file"
}

append_line() { printf "%s\n" "$1" >> "$2"; }

json_set_kv() {
  # $1=json-file $2=key $3=value
  local f="$1" k="$2" v="$3"
  require_cmd jq
  tmp="$(mktemp)"
  jq --arg k "$k" --arg v "$v" '.[$k]=$v' "$f" > "$tmp" && mv "$tmp" "$f"
}

json_read_k() {
  # $1=json-file $2=key
  require_cmd jq
  jq -r --arg k "$2" '.[$k] // empty' "$1"
}

json_keys() {
  # $1=json-file
  require_cmd jq
  jq -r 'keys[]' "$1"
}

# --- Shell files --------------------------------------------------------------
ZDOTDIR="${ZDOTDIR:-$HOME}"
ZPROFILE="$ZDOTDIR/.zprofile"
ZSHRC="$ZDOTDIR/.zshrc"
ensure_file "$ZPROFILE"
ensure_file "$ZSHRC"

# --- Homebrew mode ------------------------------------------------------------
export NONINTERACTIVE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"

# --- Config files (resolved per CONFIG_DIR) -----------------------------------
brew_formulae_file() { echo "$CONFIG_DIR/brew-formulae.txt"; }
brew_casks_file()    { echo "$CONFIG_DIR/brew-casks.txt"; }
asdf_tools_file()    { echo "$CONFIG_DIR/asdf-tools.json"; }

# Initialize config dir from defaults on first use
ensure_config() {
  ensure_dir "$CONFIG_DIR"
  [[ -f "$(brew_formulae_file)" ]] || cp "$ROOT_DIR/config.defaults/brew-formulae.txt" "$(brew_formulae_file)"
  [[ -f "$(brew_casks_file)"    ]] || cp "$ROOT_DIR/config.defaults/brew-casks.txt"    "$(brew_casks_file)"
  [[ -f "$(asdf_tools_file)"    ]] || cp "$ROOT_DIR/config.defaults/asdf-tools.json"    "$(asdf_tools_file)"
}
