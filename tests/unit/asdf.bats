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

@test "asdf_plugin_present returns true for existing plugin" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/asdf.sh"
  
  # Mock asdf plugin list to return a test plugin
  asdf() {
    case "$1" in
      "plugin")
        case "$2" in
          "list")
            echo "nodejs"
            echo "golang"
            ;;
        esac
        ;;
    esac
  }
  
  run asdf_plugin_present "nodejs"
  assert_success "$status"
}

@test "asdf_plugin_present returns false for non-existing plugin" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/asdf.sh"
  
  # Mock asdf plugin list to return empty
  asdf() {
    case "$1" in
      "plugin")
        case "$2" in
          "list")
            echo ""
            ;;
        esac
        ;;
    esac
  }
  
  run asdf_plugin_present "nonexistent"
  assert_failure "$status"
}

@test "asdf_ensure_plugin adds new plugin" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/asdf.sh"
  
  # Mock asdf commands
  asdf() {
    case "$1" in
      "plugin")
        case "$2" in
          "list")
            echo "existing"
            ;;
          "add")
            echo "Added plugin $3"
            ;;
        esac
        ;;
    esac
  }
  
  run asdf_ensure_plugin "newplugin" "https://github.com/test/repo.git"
  assert_success "$status"
}

@test "asdf_ensure_plugin skips existing plugin" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/asdf.sh"
  
  # Mock asdf commands
  asdf() {
    case "$1" in
      "plugin")
        case "$2" in
          "list")
            echo "existing"
            ;;
        esac
        ;;
    esac
  }
  
  run asdf_ensure_plugin "existing" ""
  assert_success "$status"
  [[ "$output" =~ "already present" ]]
}
