#!/usr/bin/env bats

load 'helpers/test-helpers'

setup() {
  setup_test_dir
  setup_test_config
  create_test_config
}

teardown() {
  teardown_test_dir
}

@test "get_version returns version string" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run get_version
  assert_success "$status"
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "show_version displays version information" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run show_version
  assert_success "$status"
  [[ "$output" =~ "devbox version" ]]
}

@test "validate_config_dir accepts valid directory" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run validate_config_dir "/tmp/test"
  assert_success "$status"
}

@test "validate_config_dir rejects empty directory" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run validate_config_dir ""
  assert_failure "$status"
  [[ "$output" =~ "cannot be empty" ]]
}

@test "validate_config_dir rejects invalid characters" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run validate_config_dir "/tmp/test;rm -rf /"
  assert_failure "$status"
  [[ "$output" =~ "Invalid config directory path" ]]
}

@test "validate_config_dir rejects parent directory references" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run validate_config_dir "/tmp/../etc"
  assert_failure "$status"
  [[ "$output" =~ "cannot contain" ]]
}

@test "validate_config_file accepts valid file" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local test_file="$TEST_DIR/test.txt"
  echo "test content" > "$test_file"
  
  run validate_config_file "$test_file"
  assert_success "$status"
}

@test "validate_config_file rejects non-existent file" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  run validate_config_file "/nonexistent/file"
  assert_failure "$status"
  [[ "$output" =~ "not found" ]]
}

@test "validate_config_file rejects empty file" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local test_file="$TEST_DIR/empty.txt"
  touch "$test_file"
  
  run validate_config_file "$test_file"
  assert_failure "$status"
  [[ "$output" =~ "is empty" ]]
}

@test "json_set_kv updates key-value pair" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local json_file="$TEST_DIR/test.json"
  echo '{"key1": "value1"}' > "$json_file"
  
  json_set_kv "$json_file" "key2" "value2"
  
  run jq -r '.key2' "$json_file"
  assert_success "$status"
  assert_equals "value2" "$output"
}

@test "json_read_k reads key value" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local json_file="$TEST_DIR/test.json"
  echo '{"key1": "value1", "key2": "value2"}' > "$json_file"
  
  run json_read_k "$json_file" "key1"
  assert_success "$status"
  assert_equals "value1" "$output"
}

@test "json_keys returns all keys" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local json_file="$TEST_DIR/test.json"
  echo '{"key1": "value1", "key2": "value2"}' > "$json_file"
  
  run json_keys "$json_file"
  assert_success "$status"
  [[ "$output" =~ "key1" ]]
  [[ "$output" =~ "key2" ]]
}

@test "append_if_missing adds new line" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local test_file="$TEST_DIR/test.txt"
  echo "existing" > "$test_file"
  
  append_if_missing "new" "$test_file"
  
  run cat "$test_file"
  assert_success "$status"
  [[ "$output" =~ "existing" ]]
  [[ "$output" =~ "new" ]]
}

@test "append_if_missing does not add duplicate" {
  load_main_script "$BATS_TEST_DIRNAME/../../lib/common.sh"
  
  local test_file="$TEST_DIR/test.txt"
  echo "existing" > "$test_file"
  
  append_if_missing "existing" "$test_file"
  
  run cat "$test_file"
  assert_success "$status"
  local line_count=$(echo "$output" | wc -l)
  assert_equals "1" "$line_count"
}
