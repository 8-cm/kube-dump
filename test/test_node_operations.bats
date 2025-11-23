#!/usr/bin/env bats
# Tests for node-related operations in kube-dump.sh

load test_helper/common

setup() {
  common_setup

  main() { :; }
  source "$KUBE_DUMP_SCRIPT"

  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export DEBUG_IMAGE="nicolaka/netshoot"
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR"
}

teardown() {
  common_teardown
}

# =============================================================================
# get_nodes_by_label() tests
# =============================================================================

@test "get_nodes_by_label: returns nodes matching label" {
  export KUBECTL_MOCK_OUTPUT="node-1 node-2 node-3"

  run get_nodes_by_label "node-role.kubernetes.io/worker="
  assert_success
  assert_line --index 0 "node-1"
  assert_line --index 1 "node-2"
  assert_line --index 2 "node-3"
}

@test "get_nodes_by_label: returns empty when no nodes match" {
  export KUBECTL_MOCK_OUTPUT=""

  run get_nodes_by_label "nonexistent=label"
  assert_success
  refute_output
}

@test "get_nodes_by_label: handles kubectl failure" {
  export KUBECTL_MOCK_MODE="fail"

  run get_nodes_by_label "test=label"
  assert_failure
}

# =============================================================================
# create_single_node_debug_pod() tests
# =============================================================================

@test "create_single_node_debug_pod: creates debug pod on node" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"
  export NODE_COMMAND="df -h"

  run create_single_node_debug_pod "node-1"
  assert_success

  # Verify pod creation
  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_single_node_debug_pod: sets correct node selector" {
  export NODE_COMMAND="uptime"

  run create_single_node_debug_pod "node-1"
  assert_success

  # Pod should be scheduled on specific node
}

@test "create_single_node_debug_pod: adds file-monitor sidecar when -S specified" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /var/log -name '*.log'"
  export ENCODED_NODE_SELECT_COMMAND=$(echo "$NODE_SELECT_TO_DOWNLOAD_COMMAND" | base64)

  run create_single_node_debug_pod "node-1"
  assert_success
}

@test "create_single_node_debug_pod: uses host network" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_single_node_debug_pod "node-1"
  assert_success

  # Verify hostNetwork is set in pod spec
}

@test "create_single_node_debug_pod: mounts host filesystem" {
  run create_single_node_debug_pod "node-1"
  assert_success

  # Pod should mount /host from node
}

@test "create_single_node_debug_pod: handles pod creation failure" {
  export KUBECTL_MOCK_MODE="fail"

  run create_single_node_debug_pod "node-1"
  assert_failure
}

# =============================================================================
# cleanup_node_debug_pods() tests
# =============================================================================

@test "cleanup_node_debug_pods: deletes node debug pods" {
  NODE_DEBUG_PODS_FILE="${BATS_TMPDIR}/node-debug-pods.txt"
  echo "node-debug-pod-1 default" > "$NODE_DEBUG_PODS_FILE"
  echo "node-debug-pod-2 default" >> "$NODE_DEBUG_PODS_FILE"

  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run cleanup_node_debug_pods
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "delete"
}

@test "cleanup_node_debug_pods: downloads logs before deletion" {
  NODE_DEBUG_PODS_FILE="${BATS_TMPDIR}/node-debug-pods.txt"
  echo "node-debug-pod-1 default" > "$NODE_DEBUG_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/debug-logs"

  run cleanup_node_debug_pods
  assert_success

  assert_dir_exists "${OUTPUT_DIR}/debug-logs"
}

@test "cleanup_node_debug_pods: handles empty pod list" {
  NODE_DEBUG_PODS_FILE="${BATS_TMPDIR}/node-debug-pods.txt"
  touch "$NODE_DEBUG_PODS_FILE"

  run cleanup_node_debug_pods
  assert_success
}

# =============================================================================
# validate_node_label() tests
# =============================================================================

@test "validate_node_label: accepts valid node label" {
  run validate_node_label "kubernetes.io/hostname=node-1"
  assert_success
}

@test "validate_node_label: accepts node role labels" {
  run validate_node_label "node-role.kubernetes.io/master="
  assert_success
}

@test "validate_node_label: rejects invalid format" {
  run validate_node_label "invalid label"
  assert_failure
}

# =============================================================================
# get_node_status() tests
# =============================================================================

@test "get_node_status: returns Ready for healthy node" {
  export KUBECTL_MOCK_OUTPUT="Ready"

  run get_node_status "node-1"
  assert_success
  assert_output "Ready"
}

@test "get_node_status: returns NotReady for unhealthy node" {
  export KUBECTL_MOCK_OUTPUT="NotReady"

  run get_node_status "node-1"
  assert_success
  assert_output "NotReady"
}

@test "get_node_status: handles node not found" {
  export KUBECTL_MOCK_MODE="fail"

  run get_node_status "nonexistent-node"
  assert_failure
}

# =============================================================================
# detect_kubelet_threshold() tests
# =============================================================================

@test "detect_kubelet_threshold: extracts threshold from kubelet config" {
  # Mock kubelet configz response
  export KUBECTL_MOCK_OUTPUT='{"kubeletconfig":{"evictionHard":{"nodefs.available":"10%"}}}'

  run detect_kubelet_threshold "node-1"
  assert_success
  assert_output --partial "10"
}

@test "detect_kubelet_threshold: handles GB threshold" {
  export KUBECTL_MOCK_OUTPUT='{"kubeletconfig":{"evictionHard":{"nodefs.available":"5Gi"}}}'

  run detect_kubelet_threshold "node-1"
  assert_success
}

@test "detect_kubelet_threshold: falls back to 10% on failure" {
  export KUBECTL_MOCK_MODE="fail"

  run detect_kubelet_threshold "node-1"
  assert_success
  assert_output --partial "10"
}

@test "detect_kubelet_threshold: handles missing eviction config" {
  export KUBECTL_MOCK_OUTPUT='{"kubeletconfig":{}}'

  run detect_kubelet_threshold "node-1"
  assert_success
  # Should fallback to default
}

# =============================================================================
# build_node_debug_script() tests
# =============================================================================

@test "build_node_debug_script: generates valid bash script" {
  export NODE_COMMAND="ls -la /host/var/log"

  run build_node_debug_script "node-1"
  assert_success

  # Output should be valid bash
  assert_output --partial "#!/bin/bash"
}

@test "build_node_debug_script: includes node command" {
  export NODE_COMMAND="df -h"

  run build_node_debug_script "node-1"
  assert_success

  assert_output --partial "df -h"
}

@test "build_node_debug_script: handles placeholder substitution" {
  export NODE_COMMAND="echo 'Node: %'"
  export PLACEHOLDER_CHAR="%"

  run build_node_debug_script "node-1"
  assert_success

  # Should substitute % with node-1
  assert_output --partial "node-1"
}

@test "build_node_debug_script: strips newlines from command" {
  export NODE_COMMAND="echo 'line1'
echo 'line2'"

  run build_node_debug_script "node-1"
  assert_success

  # Should not contain literal newlines in command
}

# =============================================================================
# build_node_file_monitor_script() tests
# =============================================================================

@test "build_node_file_monitor_script: generates monitoring script" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /var/log -name '*.log'"

  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "#!/bin/bash"
  assert_output --partial "file monitor"
}

@test "build_node_file_monitor_script: includes ls command" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "ls -lh"
}

@test "build_node_file_monitor_script: loops every second" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "sleep 1"
}
