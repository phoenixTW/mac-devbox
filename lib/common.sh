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
get_version() { echo "0.1.0"; }
show_version() { echo "devbox version $(get_version)"; }

# Version file path
version_file() { echo "$CONFIG_DIR/.version"; }

# Get current installed version (from version file or fallback to binary)
get_current_version() {
  local version_file_path
  version_file_path="$(version_file)"
  if [[ -f "$version_file_path" ]]; then
    cat "$version_file_path"
  else
    # Fallback to binary version for backward compatibility
    get_version
  fi
}

# Store version to file
store_version() {
  local version="$1"
  local version_file_path
  version_file_path="$(version_file)"
  echo "$version" > "$version_file_path"
}

# Get latest version from GitHub API
get_latest_version() {
  local repo="${REPO:-phoenixTW/mac-devbox}"
  local latest_tag
  
  # Check internet connectivity first
  if ! curl -fsSL --connect-timeout 5 "https://api.github.com" >/dev/null 2>&1; then
    return 1
  fi
  
  latest_tag=$(curl -fsSL --connect-timeout 10 "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | \
    grep '"tag_name"' | \
    sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' 2>/dev/null)
  
  if [[ -n "$latest_tag" ]]; then
    echo "$latest_tag"
    return 0
  else
    return 1
  fi
}

# Compare semantic versions (returns 0 if v1 >= v2, 1 otherwise)
compare_versions() {
  local v1="$1" v2="$2"
  
  # Remove 'v' prefix if present
  v1="${v1#v}"
  v2="${v2#v}"
  
  # Use sort -V for version comparison
  if [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -1)" == "$v2" ]]; then
    return 0  # v1 >= v2
  else
    return 1  # v1 < v2
  fi
}

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

# --- Update functionality -----------------------------------------------------
# Backup current installation
backup_installation() {
  local backup_dir="$1"
  local bin_dir="$HOME/.local/bin"
  local lib_dir="$HOME/.local/lib"
  
  mkdir -p "$backup_dir"
  
  # Backup binary
  if [[ -f "$bin_dir/devbox" ]]; then
    cp "$bin_dir/devbox" "$backup_dir/devbox"
  fi
  
  # Backup lib directory
  if [[ -d "$lib_dir" ]]; then
    cp -r "$lib_dir" "$backup_dir/"
  fi
  
  # Backup version file
  if [[ -f "$(version_file)" ]]; then
    cp "$(version_file)" "$backup_dir/.version"
  fi
}

# Restore from backup
restore_installation() {
  local backup_dir="$1"
  local bin_dir="$HOME/.local/bin"
  local lib_dir="$HOME/.local/lib"
  
  # Restore binary
  if [[ -f "$backup_dir/devbox" ]]; then
    cp "$backup_dir/devbox" "$bin_dir/devbox"
    chmod +x "$bin_dir/devbox"
  fi
  
  # Restore lib directory
  if [[ -d "$backup_dir/lib" ]]; then
    rm -rf "$lib_dir"
    cp -r "$backup_dir/lib" "$lib_dir"
  fi
  
  # Restore version file
  if [[ -f "$backup_dir/.version" ]]; then
    cp "$backup_dir/.version" "$(version_file)"
  fi
}

# Download and install latest version
update_installation() {
  local latest_version="$1"
  local temp_dir="$2"
  local repo="${REPO:-phoenixTW/mac-devbox}"
  local bin_dir="$HOME/.local/bin"
  local lib_dir="$HOME/.local/lib"
  
  # Download latest release
  log "Downloading devbox $latest_version..."
  if ! curl -fsSL "https://codeload.github.com/$repo/tar.gz/$latest_version" -o "$temp_dir/src.tar.gz"; then
    return 1
  fi
  
  # Extract archive
  if ! tar -xzf "$temp_dir/src.tar.gz" -C "$temp_dir"; then
    return 1
  fi
  
  # Find extracted directory
  local extracted_dir
  extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "*" | grep -v "^$temp_dir$" | head -1)
  if [[ -z "$extracted_dir" ]]; then
    return 1
  fi
  
  # Install new binary
  if [[ -f "$extracted_dir/bin/devbox" ]]; then
    cp "$extracted_dir/bin/devbox" "$bin_dir/devbox"
    chmod +x "$bin_dir/devbox"
  else
    return 1
  fi
  
  # Install new lib directory
  if [[ -d "$extracted_dir/lib" ]]; then
    rm -rf "$lib_dir"
    mkdir -p "$lib_dir"
    cp -r "$extracted_dir/lib"/* "$lib_dir/"
  else
    return 1
  fi
  
  # Update version file
  store_version "$latest_version"
  
  return 0
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
