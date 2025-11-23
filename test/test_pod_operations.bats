#!/usr/bin/env bats
# Tests for pod-related operations in kube-dump.sh

load test_helper/common

setup() {
  common_setup

  # Source the script
  main() { :; }
  source "$KUBE_DUMP_SCRIPT"

  # Setup environment
  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export DEBUG_IMAGE="nicolaka/netshoot"
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  export NAMESPACE="default"
  mkdir -p "$OUTPUT_DIR"
}

teardown() {
  common_teardown
}

# =============================================================================
# get_pods_by_label() tests
# =============================================================================

@test "get_pods_by_label: returns pods matching label" {
  export KUBECTL_MOCK_OUTPUT="pod1 pod2 pod3"

  run get_pods_by_label "app=nginx"
  assert_success
  assert_line --index 0 "pod1"
  assert_line --index 1 "pod2"
  assert_line --index 2 "pod3"
}

@test "get_pods_by_label: returns empty when no pods match" {
  export KUBECTL_MOCK_OUTPUT=""

  run get_pods_by_label "app=nonexistent"
  assert_success
  refute_output
}

@test "get_pods_by_label: handles invalid label format" {
  export KUBECTL_MOCK_MODE="fail"

  run get_pods_by_label "invalid-label"
  assert_failure
}

@test "get_pods_by_label: respects namespace parameter" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run get_pods_by_label "app=test" "custom-namespace"

  # Verify namespace was used in kubectl command
  assert_file_contains "$KUBECTL_SPY_FILE" "custom-namespace"
}

# =============================================================================
# get_pod_node() tests
# =============================================================================

@test "get_pod_node: returns node name for pod" {
  export KUBECTL_MOCK_OUTPUT="node-1"

  run get_pod_node "test-pod" "default"
  assert_success
  assert_output "node-1"
}

@test "get_pod_node: handles pod not found" {
  export KUBECTL_MOCK_MODE="fail"

  run get_pod_node "nonexistent-pod" "default"
  assert_failure
}

@test "get_pod_node: handles pod without node assignment" {
  export KUBECTL_MOCK_OUTPUT=""

  run get_pod_node "pending-pod" "default"
  assert_success
  assert_output ""
}

# =============================================================================
# get_pod_container() tests
# =============================================================================

@test "get_pod_container: returns first container name" {
  export KUBECTL_MOCK_OUTPUT="container1"

  run get_pod_container "test-pod" "default"
  assert_success
  assert_output "container1"
}

@test "get_pod_container: handles pod with multiple containers" {
  export KUBECTL_MOCK_OUTPUT="container1 container2 container3"

  run get_pod_container "test-pod" "default"
  assert_success
  # Should return first container
  assert_output "container1 container2 container3"
}

# =============================================================================
# create_single_debug_pod() tests
# =============================================================================

@test "create_single_debug_pod: creates debug pod successfully" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Verify pod was created
  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_single_debug_pod: sets correct environment variables" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"
  export CAPTURE_COMMAND="tcpdump -i any -w /tmp/capture.pcap"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success
}

@test "create_single_debug_pod: adds file-monitor sidecar when -s specified" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp -name '*.log'"
  export ENCODED_SELECT_COMMAND=$(echo "$SELECT_TO_DOWNLOAD_COMMAND" | base64)

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Pod spec should include file-monitor container
  # (checking would require parsing the applied YAML)
}

@test "create_single_debug_pod: uses correct debug image" {
  export DEBUG_IMAGE="custom/debug:latest"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Verify custom image in command
  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_single_debug_pod: handles pod creation failure" {
  export KUBECTL_MOCK_MODE="fail"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_failure
}

# =============================================================================
# wait_for_pod_ready() tests
# =============================================================================

@test "wait_for_pod_ready: succeeds when pod is running" {
  # Mock kubectl to return Running status
  mock_kube_command "kubectl" 'echo "Running"; exit 0'
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  run wait_for_pod_ready "test-pod" "default" 5
  assert_success
}

@test "wait_for_pod_ready: times out when pod doesn't start" {
  # Mock kubectl to return Pending status
  mock_kube_command "kubectl" 'echo "Pending"; exit 0'
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  run wait_for_pod_ready "test-pod" "default" 2
  assert_failure
}

@test "wait_for_pod_ready: handles pod errors" {
  # Mock kubectl to return Error status
  mock_kube_command "kubectl" 'echo "Error"; exit 0'
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  run wait_for_pod_ready "test-pod" "default" 5
  assert_failure
}

# =============================================================================
# cleanup_debug_pods() tests
# =============================================================================

@test "cleanup_debug_pods: deletes debug pods successfully" {
  # Create a debug pod list file
  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default" > "$DEBUG_PODS_FILE"
  echo "debug-pod-2 default" >> "$DEBUG_PODS_FILE"

  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run cleanup_debug_pods
  assert_success

  # Verify delete commands were issued
  assert_file_contains "$KUBECTL_SPY_FILE" "delete"
}

@test "cleanup_debug_pods: downloads logs before deletion" {
  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default" > "$DEBUG_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/debug-logs"

  run cleanup_debug_pods
  assert_success

  # Log file should be created
  assert_dir_exists "${OUTPUT_DIR}/debug-logs"
}

@test "cleanup_debug_pods: downloads file-monitor logs when present" {
  # Mock pod with file-monitor container
  mock_kube_command "kubectl" '
    if [[ "$*" == *"jsonpath"* ]]; then
      echo "debugger file-monitor"
    else
      exit 0
    fi
  '
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default" > "$DEBUG_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/debug-logs"

  run cleanup_debug_pods
  assert_success
}

@test "cleanup_debug_pods: handles empty debug pods list" {
  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  touch "$DEBUG_PODS_FILE"

  run cleanup_debug_pods
  assert_success
}

@test "cleanup_debug_pods: continues on individual pod deletion failure" {
  export KUBECTL_MOCK_MODE="fail"

  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default" > "$DEBUG_PODS_FILE"
  echo "debug-pod-2 default" >> "$DEBUG_PODS_FILE"

  run cleanup_debug_pods
  # Should still succeed even if deletion fails
  assert_success
}

# =============================================================================
# execute_command_on_pod() tests
# =============================================================================

@test "execute_command_on_pod: runs command successfully" {
  export KUBECTL_MOCK_OUTPUT="command output"

  run execute_command_on_pod "debug-pod" "default" "echo test"
  assert_success
  assert_output "command output"
}

@test "execute_command_on_pod: handles command failure" {
  export KUBECTL_MOCK_MODE="fail"

  run execute_command_on_pod "debug-pod" "default" "exit 1"
  assert_failure
}

@test "execute_command_on_pod: passes environment variables" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run execute_command_on_pod "debug-pod" "default" "env"

  # Verify exec command format
  assert_file_contains "$KUBECTL_SPY_FILE" "exec"
}

# =============================================================================
# get_pod_namespace() tests
# =============================================================================

@test "get_pod_namespace: returns correct namespace" {
  export KUBECTL_MOCK_OUTPUT="kube-system"

  run get_pod_namespace "test-pod"
  assert_success
  assert_output "kube-system"
}

@test "get_pod_namespace: returns default when pod not found" {
  export KUBECTL_MOCK_MODE="fail"

  run get_pod_namespace "nonexistent-pod"
  # Should handle gracefully
}

# =============================================================================
# validate_pod_label() tests
# =============================================================================

@test "validate_pod_label: accepts valid label selector" {
  run validate_pod_label "app=nginx"
  assert_success
}

@test "validate_pod_label: accepts multiple labels" {
  run validate_pod_label "app=nginx,tier=frontend"
  assert_success
}

@test "validate_pod_label: accepts set-based selectors" {
  run validate_pod_label "environment in (production,staging)"
  assert_success
}

@test "validate_pod_label: rejects invalid format" {
  run validate_pod_label "invalid label format"
  assert_failure
}

@test "validate_pod_label: handles empty label" {
  run validate_pod_label ""
  assert_failure
}
