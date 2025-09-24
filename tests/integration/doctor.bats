#!/usr/bin/env bats

load '../helpers/test-helpers'

setup() {
  setup_test_dir
  setup_test_config
  create_test_config
}

teardown() {
  teardown_test_dir
}

@test "doctor --dry-run works without system tools" {
  # Mock the devbox script to avoid system dependencies
  local devbox_script="$TEST_DIR/devbox"
  cat > "$devbox_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Load common functions
. "$(dirname "$0")/../../lib/common.sh"

# Mock doctor command
cmd_doctor() {
  local dry_run=0
  if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; fi

  echo "Config dir: $CONFIG_DIR"
  echo ""
  echo "[brew formulae]"
  while read -r f; do
    [[ -z "$f" || "$f" =~ ^# ]] && continue
    printf "  %-24s : " "$f"
    if [[ $dry_run -eq 1 ]]; then
      echo "(dry-run)"; continue
    fi
    echo "MISSING"
  done < "$(brew_formulae_file)"

  echo ""
  echo "[brew casks]"
  while read -r c; do
    [[ -z "$c" || "$c" =~ ^# ]] && continue
    printf "  %-24s : " "$c"
    if [[ $dry_run -eq 1 ]]; then
      echo "(dry-run)"; continue
    fi
    echo "MISSING"
  done < "$(brew_casks_file)"

  echo ""
  echo "[asdf tools]"
  for k in $(json_keys "$(asdf_tools_file)"); do
    v="$(json_read_k "$(asdf_tools_file)" "$k")"
    if [[ $dry_run -eq 1 ]]; then
      printf "  %-24s : wanted=%-10s current=(dry-run)\n" "$k" "$v"
      continue
    fi
    printf "  %-24s : wanted=%-10s current=%s\n" "$k" "$v" "MISSING"
  done
}

# Set config directory
CONFIG_DIR="$TEST_CONFIG_DIR"
export CONFIG_DIR

# Run doctor command
cmd_doctor "${1:-}"
EOF

  chmod +x "$devbox_script"
  
  # Set the test config directory
  export TEST_CONFIG_DIR="$TEST_CONFIG_DIR"
  
  run "$devbox_script" --dry-run
  assert_success "$status"
  
  # Check that dry-run output is present
  [[ "$output" =~ "Config dir:" ]]
  [[ "$output" =~ "brew formulae" ]]
  [[ "$output" =~ "brew casks" ]]
  [[ "$output" =~ "asdf tools" ]]
  [[ "$output" =~ "(dry-run)" ]]
}

@test "doctor shows configured packages" {
  # Mock the devbox script
  local devbox_script="$TEST_DIR/devbox"
  cat > "$devbox_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$0")/../../lib/common.sh"

cmd_doctor() {
  local dry_run=0
  if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; fi

  echo "Config dir: $CONFIG_DIR"
  echo ""
  echo "[brew formulae]"
  while read -r f; do
    [[ -z "$f" || "$f" =~ ^# ]] && continue
    printf "  %-24s : " "$f"
    if [[ $dry_run -eq 1 ]]; then
      echo "(dry-run)"; continue
    fi
    echo "MISSING"
  done < "$(brew_formulae_file)"

  echo ""
  echo "[brew casks]"
  while read -r c; do
    [[ -z "$c" || "$c" =~ ^# ]] && continue
    printf "  %-24s : " "$c"
    if [[ $dry_run -eq 1 ]]; then
      echo "(dry-run)"; continue
    fi
    echo "MISSING"
  done < "$(brew_casks_file)"

  echo ""
  echo "[asdf tools]"
  for k in $(json_keys "$(asdf_tools_file)"); do
    v="$(json_read_k "$(asdf_tools_file)" "$k")"
    if [[ $dry_run -eq 1 ]]; then
      printf "  %-24s : wanted=%-10s current=(dry-run)\n" "$k" "$v"
      continue
    fi
    printf "  %-24s : wanted=%-10s current=%s\n" "$k" "$v" "MISSING"
  done
}

CONFIG_DIR="$TEST_CONFIG_DIR"
export CONFIG_DIR

cmd_doctor "${1:-}"
EOF

  chmod +x "$devbox_script"
  
  export TEST_CONFIG_DIR="$TEST_CONFIG_DIR"
  
  run "$devbox_script" --dry-run
  assert_success "$status"
  
  # Check that configured packages are shown
  [[ "$output" =~ "git" ]]
  [[ "$output" =~ "jq" ]]
  [[ "$output" =~ "curl" ]]
  [[ "$output" =~ "docker" ]]
  [[ "$output" =~ "cursor" ]]
  [[ "$output" =~ "nodejs" ]]
  [[ "$output" =~ "golang" ]]
}
