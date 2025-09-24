#!/usr/bin/env bash
# Test helper functions for devbox tests

# Load the main script functions
load_main_script() {
  local script_path="$1"
  # shellcheck source=/dev/null
  source "$script_path"
}

# Create a temporary directory for tests
setup_test_dir() {
  TEST_DIR=$(mktemp -d)
  export TEST_DIR
}

# Clean up test directory
teardown_test_dir() {
  [[ -n "${TEST_DIR:-}" ]] && rm -rf "$TEST_DIR"
}

# Create a test config directory
setup_test_config() {
  local config_dir="${TEST_DIR}/test-config"
  mkdir -p "$config_dir"
  export TEST_CONFIG_DIR="$config_dir"
}

# Create test config files
create_test_config() {
  local config_dir="${TEST_CONFIG_DIR:-$TEST_DIR/test-config}"
  mkdir -p "$config_dir"
  
  # Create test brew formulae file
  cat > "$config_dir/brew-formulae.txt" << EOF
git
jq
# Test comment
curl
EOF

  # Create test brew casks file
  cat > "$config_dir/brew-casks.txt" << EOF
docker
# Test comment
cursor
EOF

  # Create test asdf tools file
  cat > "$config_dir/asdf-tools.json" << EOF
{
  "nodejs": "latest",
  "golang": "1.22.5"
}
EOF
}

# Mock functions for testing
mock_brew() {
  brew() {
    case "$1" in
      "list")
        if [[ "$2" == "--formula" ]]; then
          echo "git jq curl"
        elif [[ "$2" == "--cask" ]]; then
          echo "docker cursor"
        fi
        ;;
      "info")
        if [[ "$2" == "--formula" ]]; then
          [[ "$3" == "git" || "$3" == "jq" || "$3" == "curl" ]] && return 0
        elif [[ "$2" == "--cask" ]]; then
          [[ "$3" == "docker" || "$3" == "cursor" ]] && return 0
        fi
        return 1
        ;;
    esac
  }
}

mock_asdf() {
  asdf() {
    case "$1" in
      "list")
        if [[ "$2" == "nodejs" ]]; then
          echo "  20.10.0"
        elif [[ "$2" == "golang" ]]; then
          echo "  1.22.5"
        fi
        ;;
      "current")
        if [[ "$2" == "nodejs" ]]; then
          echo "nodejs 20.10.0"
        elif [[ "$2" == "golang" ]]; then
          echo "golang 1.22.5"
        fi
        ;;
      "latest")
        if [[ "$2" == "nodejs" ]]; then
          echo "20.10.0"
        elif [[ "$2" == "golang" ]]; then
          echo "1.22.5"
        fi
        ;;
    esac
  }
}

# Assertion functions
assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]] || {
    echo "FAIL: File $file does not exist"
    return 1
  }
}

assert_file_not_exists() {
  local file="$1"
  [[ ! -f "$file" ]] || {
    echo "FAIL: File $file should not exist"
    return 1
  }
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  grep -q "$pattern" "$file" || {
    echo "FAIL: File $file does not contain '$pattern'"
    return 1
  }
}

assert_file_not_contains() {
  local file="$1"
  local pattern="$2"
  ! grep -q "$pattern" "$file" || {
    echo "FAIL: File $file should not contain '$pattern'"
    return 1
  }
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  [[ "$expected" == "$actual" ]] || {
    echo "FAIL: Expected '$expected', got '$actual'"
    return 1
  }
}

assert_not_equals() {
  local expected="$1"
  local actual="$2"
  [[ "$expected" != "$actual" ]] || {
    echo "FAIL: Expected not '$expected', got '$actual'"
    return 1
  }
}

assert_success() {
  local exit_code="$1"
  [[ "$exit_code" -eq 0 ]] || {
    echo "FAIL: Command failed with exit code $exit_code"
    return 1
  }
}

assert_failure() {
  local exit_code="$1"
  [[ "$exit_code" -ne 0 ]] || {
    echo "FAIL: Command should have failed but succeeded"
    return 1
  }
}
