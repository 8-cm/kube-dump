#!/usr/bin/env bats
# Tests for utility functions in kube-dump.sh

load test_helper/common

setup() {
  common_setup

  # Source the script to get function definitions
  # We need to prevent main() from executing
  main() { :; }
  source "$KUBE_DUMP_SCRIPT"
}

teardown() {
  common_teardown
}

# =============================================================================
# hash_input() tests
# =============================================================================

@test "hash_input: generates hash with md5sum" {
  # Mock md5sum to be available
  mock_kube_command "md5sum" 'echo "d41d8cd98f00b204e9800998ecf8427e  -"'

  run hash_input "test"
  assert_success
  assert_output --partial "d41d8cd98f00b204e9800998ecf8427e"
}

@test "hash_input: falls back to md5 when md5sum not available" {
  # Remove md5sum from PATH
  PATH="/bin:/usr/bin" run hash_input "test"
  # Should still succeed with md5 or cksum fallback
  assert_success
}

@test "hash_input: generates consistent hashes for same input" {
  run hash_input "test-input"
  local hash1="$output"

  run hash_input "test-input"
  local hash2="$output"

  assert_equal "$hash1" "$hash2"
}

@test "hash_input: generates different hashes for different input" {
  run hash_input "input1"
  local hash1="$output"

  run hash_input "input2"
  local hash2="$output"

  refute_equal "$hash1" "$hash2"
}

# =============================================================================
# format_message() and format_message_stderr() tests
# =============================================================================

@test "format_message: outputs to stdout" {
  run format_message "test message"
  assert_success
  assert_output --partial "test message"
}

@test "format_message_stderr: outputs to stderr" {
  # Capture stderr
  run bash -c "source '$KUBE_DUMP_SCRIPT'; format_message_stderr 'error message' 2>&1 >/dev/null"
  assert_success
  assert_output --partial "error message"
}

@test "format_message: handles empty input" {
  run format_message ""
  assert_success
}

@test "format_message: handles special characters" {
  run format_message "test \$VAR and 'quotes' and \"double quotes\""
  assert_success
  assert_output --partial "test"
}

# =============================================================================
# validate_threshold() tests
# =============================================================================

@test "validate_threshold: accepts valid percentage" {
  run validate_threshold "10%"
  assert_success
}

@test "validate_threshold: accepts valid size with GB" {
  run validate_threshold "5GB"
  assert_success
}

@test "validate_threshold: accepts valid size with MB" {
  run validate_threshold "500MB"
  assert_success
}

@test "validate_threshold: accepts valid size with KB" {
  run validate_threshold "1024KB"
  assert_success
}

@test "validate_threshold: rejects invalid format" {
  run validate_threshold "invalid"
  assert_failure
}

@test "validate_threshold: rejects percentage over 100" {
  run validate_threshold "150%"
  assert_failure
}

@test "validate_threshold: rejects negative values" {
  run validate_threshold "-5GB"
  assert_failure
}

@test "validate_threshold: rejects zero values" {
  run validate_threshold "0GB"
  assert_failure
}

# =============================================================================
# validate_placeholder() tests
# =============================================================================

@test "validate_placeholder: accepts single character" {
  run validate_placeholder "%"
  assert_success
}

@test "validate_placeholder: rejects multiple characters" {
  run validate_placeholder "%%"
  assert_failure
}

@test "validate_placeholder: rejects empty string" {
  run validate_placeholder ""
  assert_failure
}

@test "validate_placeholder: accepts alphanumeric characters" {
  run validate_placeholder "X"
  assert_success
}

@test "validate_placeholder: accepts special characters" {
  run validate_placeholder "#"
  assert_success
}

# =============================================================================
# detect_kube_cli() tests
# =============================================================================

@test "detect_kube_cli: finds kubectl when available" {
  export PATH="${MOCK_DIR}:${PATH}"

  run detect_kube_cli
  assert_success

  # Check that KUBE_CLI is set
  [[ "$KUBE_CLI" == *"kubectl"* ]]
}

@test "detect_kube_cli: finds oc when kubectl not available" {
  # Remove kubectl from mocks temporarily
  mv test/mocks/kubectl test/mocks/kubectl.bak
  export PATH="${MOCK_DIR}:${PATH}"

  run detect_kube_cli
  assert_success

  # Restore kubectl
  mv test/mocks/kubectl.bak test/mocks/kubectl

  [[ "$KUBE_CLI" == *"oc"* ]]
}

@test "detect_kube_cli: fails when neither kubectl nor oc available" {
  # Remove both from PATH
  mv test/mocks/kubectl test/mocks/kubectl.bak
  mv test/mocks/oc test/mocks/oc.bak

  export PATH="/nonexistent:${PATH}"

  run detect_kube_cli
  assert_failure

  # Restore
  mv test/mocks/kubectl.bak test/mocks/kubectl
  mv test/mocks/oc.bak test/mocks/oc
}

# =============================================================================
# setup_output_directories() tests
# =============================================================================

@test "setup_output_directories: creates all subdirectories" {
  OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR"

  run setup_output_directories
  assert_success

  # Check all subdirectories exist
  assert_dir_exists "${OUTPUT_DIR}/files"
  assert_dir_exists "${OUTPUT_DIR}/discovery-logs"
  assert_dir_exists "${OUTPUT_DIR}/debug-logs"
  assert_dir_exists "${OUTPUT_DIR}/killswitch-logs"
  assert_dir_exists "${OUTPUT_DIR}/process-logs"
}

@test "setup_output_directories: handles existing directories" {
  OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR/files"

  run setup_output_directories
  assert_success

  assert_dir_exists "${OUTPUT_DIR}/files"
}

@test "setup_output_directories: fails when OUTPUT_DIR not set" {
  unset OUTPUT_DIR

  run setup_output_directories
  assert_failure
}

# =============================================================================
# check_prerequisites() tests
# =============================================================================

@test "check_prerequisites: succeeds with all tools available" {
  export PATH="${MOCK_DIR}:/bin:/usr/bin"

  # Create mock for base64, grep, etc.
  for cmd in base64 grep sed cut tr awk date cat; do
    mock_kube_command "$cmd" "exit 0"
  done

  run check_prerequisites
  assert_success
}

@test "check_prerequisites: fails when kubectl/oc missing" {
  # Remove kubectl/oc from PATH
  export PATH="/bin:/usr/bin"

  run check_prerequisites
  assert_failure
  assert_output --partial "kubectl"
}

@test "check_prerequisites: fails when base64 missing" {
  export PATH="/tmp/empty:${PATH}"

  # Mock all except base64
  for cmd in grep sed cut tr; do
    mock_kube_command "$cmd" "exit 0"
  done

  run check_prerequisites
  assert_failure
}

# =============================================================================
# convert_threshold_to_bytes() tests (if function exists)
# =============================================================================

@test "convert_threshold_to_bytes: converts GB to bytes" {
  run convert_threshold_to_bytes "1GB"
  assert_success
  assert_output "1073741824"
}

@test "convert_threshold_to_bytes: converts MB to bytes" {
  run convert_threshold_to_bytes "1MB"
  assert_success
  assert_output "1048576"
}

@test "convert_threshold_to_bytes: converts KB to bytes" {
  run convert_threshold_to_bytes "1KB"
  assert_success
  assert_output "1024"
}

@test "convert_threshold_to_bytes: handles decimal values" {
  run convert_threshold_to_bytes "1.5GB"
  assert_success
}

# =============================================================================
# run_kube_cmd() tests
# =============================================================================

@test "run_kube_cmd: executes kubectl command successfully" {
  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run run_kube_cmd "test-operation" "get" get pods
  assert_success

  # Check command was logged
  assert_file_exist "$KUBECTL_SPY_FILE"
}

@test "run_kube_cmd: handles command failures" {
  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export KUBECTL_MOCK_MODE="fail"

  run run_kube_cmd "test-operation" "get" get pods
  assert_failure
}

@test "run_kube_cmd: logs to process log when VERBOSE enabled" {
  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export VERBOSE=1
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "${OUTPUT_DIR}/process-logs"

  run run_kube_cmd "test-op" "get" get pods

  # Check log file was created
  assert_file_exist "${OUTPUT_DIR}/process-logs"/*.log
}
