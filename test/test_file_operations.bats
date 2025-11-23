#!/usr/bin/env bats
# Tests for file operations (discovery and download) in kube-dump.sh

load test_helper/common

setup() {
  common_setup

  main() { :; }
  source "$KUBE_DUMP_SCRIPT"

  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR"
}

teardown() {
  common_teardown
}

# =============================================================================
# create_discovery_pod() tests
# =============================================================================

@test "create_discovery_pod: creates discovery pod for file selection" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp -name '*.log'"

  run create_discovery_pod "target-pod" "default" "container1" "node-1"
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_discovery_pod: uses same node as target pod" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /var/log"

  run create_discovery_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Should schedule on node-1
}

@test "create_discovery_pod: runs selection command" {
  export SELECT_TO_DOWNLOAD_COMMAND="ls -1 /tmp/*.pcap"

  run create_discovery_pod "target-pod" "default" "container1" "node-1"
  assert_success
}

@test "create_discovery_pod: handles pod creation failure" {
  export KUBECTL_MOCK_MODE="fail"
  export SELECT_TO_DOWNLOAD_COMMAND="find /"

  run create_discovery_pod "target-pod" "default" "container1" "node-1"
  assert_failure
}

# =============================================================================
# create_node_discovery_pod() tests
# =============================================================================

@test "create_node_discovery_pod: creates discovery pod on node" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /host/var/log"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_node_discovery_pod "node-1"
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_node_discovery_pod: mounts /host volume" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /host"

  run create_node_discovery_pod "node-1"
  assert_success

  # Pod should have /host mount
}

# =============================================================================
# get_files_from_discovery_pod() tests
# =============================================================================

@test "get_files_from_discovery_pod: retrieves file list" {
  export KUBECTL_MOCK_OUTPUT="/tmp/file1.log
/tmp/file2.log
/tmp/file3.log"

  run get_files_from_discovery_pod "discovery-pod" "default"
  assert_success
  assert_line --index 0 "/tmp/file1.log"
  assert_line --index 1 "/tmp/file2.log"
  assert_line --index 2 "/tmp/file3.log"
}

@test "get_files_from_discovery_pod: handles no files found" {
  export KUBECTL_MOCK_OUTPUT=""

  run get_files_from_discovery_pod "discovery-pod" "default"
  assert_success
  refute_output
}

@test "get_files_from_discovery_pod: handles pod not ready" {
  export KUBECTL_MOCK_MODE="fail"

  run get_files_from_discovery_pod "discovery-pod" "default"
  assert_failure
}

# =============================================================================
# download_file_from_pod() tests
# =============================================================================

@test "download_file_from_pod: downloads file successfully" {
  export KUBECTL_MOCK_OUTPUT="file contents"

  run download_file_from_pod "debug-pod" "default" "/tmp/test.log" "target-pod"
  assert_success
}

@test "download_file_from_pod: creates output directory structure" {
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "${OUTPUT_DIR}/files"

  run download_file_from_pod "debug-pod" "default" "/var/log/test.log" "target-pod"

  # Should create subdirectories
  assert_dir_exists "${OUTPUT_DIR}/files"
}

@test "download_file_from_pod: handles download failure" {
  export KUBECTL_MOCK_MODE="fail"

  run download_file_from_pod "debug-pod" "default" "/tmp/missing.log" "target-pod"
  assert_failure
}

@test "download_file_from_pod: sanitizes filename" {
  # Test that special characters are handled
  run download_file_from_pod "debug-pod" "default" "/tmp/file with spaces.log" "target-pod"

  # Should not fail due to spaces
}

@test "download_file_from_pod: avoids duplicate target names in filename" {
  # When target name is already in path, shouldn't duplicate it
  run download_file_from_pod "debug-pod" "default" "/tmp/target-pod.log" "target-pod"
  assert_success

  # Filename shouldn't be target-pod__target-pod.log
}

# =============================================================================
# download_file_from_node() tests
# =============================================================================

@test "download_file_from_node: downloads file from node" {
  export KUBECTL_MOCK_OUTPUT="node file contents"

  run download_file_from_node "node-debug-pod" "default" "/host/var/log/kubelet.log" "node-1"
  assert_success
}

@test "download_file_from_node: creates output directory" {
  mkdir -p "${OUTPUT_DIR}/files"

  run download_file_from_node "node-debug-pod" "default" "/host/tmp/test.log" "node-1"

  assert_dir_exists "${OUTPUT_DIR}/files"
}

@test "download_file_from_node: handles large files" {
  # Mock large file output
  export KUBECTL_MOCK_OUTPUT=$(printf 'x%.0s' {1..10000})

  run download_file_from_node "node-debug-pod" "default" "/host/tmp/large.log" "node-1"
  assert_success
}

# =============================================================================
# handle_file_downloads() tests
# =============================================================================

@test "handle_file_downloads: orchestrates full download workflow" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp -name '*.log'"
  export KUBECTL_MOCK_OUTPUT="/tmp/file1.log
/tmp/file2.log"

  mkdir -p "${OUTPUT_DIR}/files"
  mkdir -p "${OUTPUT_DIR}/discovery-logs"

  run handle_file_downloads
  assert_success
}

@test "handle_file_downloads: creates discovery pods" {
  export SELECT_TO_DOWNLOAD_COMMAND="ls /tmp/*.pcap"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  # Mock pod list
  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default target-pod-1" > "$DEBUG_PODS_FILE"

  run handle_file_downloads

  # Should create discovery pod
  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "handle_file_downloads: downloads all discovered files" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /var/log"

  mkdir -p "${OUTPUT_DIR}/files"
  mkdir -p "${OUTPUT_DIR}/discovery-logs"

  run handle_file_downloads
  assert_success
}

@test "handle_file_downloads: cleans up discovery pods" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp"

  mkdir -p "${OUTPUT_DIR}/discovery-logs"

  run handle_file_downloads

  # Discovery pods should be cleaned up
}

@test "handle_file_downloads: handles no files discovered" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /nonexistent"
  export KUBECTL_MOCK_OUTPUT=""

  run handle_file_downloads
  assert_success
}

# =============================================================================
# cleanup_discovery_pods() tests
# =============================================================================

@test "cleanup_discovery_pods: deletes discovery pods" {
  DISCOVERY_PODS_FILE="${BATS_TMPDIR}/discovery-pods.txt"
  echo "discovery-pod-1 default" > "$DISCOVERY_PODS_FILE"
  echo "discovery-pod-2 default" >> "$DISCOVERY_PODS_FILE"

  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run cleanup_discovery_pods
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "delete"
}

@test "cleanup_discovery_pods: downloads logs before deletion" {
  DISCOVERY_PODS_FILE="${BATS_TMPDIR}/discovery-pods.txt"
  echo "discovery-pod-1 default" > "$DISCOVERY_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/discovery-logs"

  run cleanup_discovery_pods
  assert_success

  assert_dir_exists "${OUTPUT_DIR}/discovery-logs"
}

@test "cleanup_discovery_pods: handles empty list" {
  DISCOVERY_PODS_FILE="${BATS_TMPDIR}/discovery-pods.txt"
  touch "$DISCOVERY_PODS_FILE"

  run cleanup_discovery_pods
  assert_success
}

# =============================================================================
# get_container_id_from_pod() tests (CRI operations)
# =============================================================================

@test "get_container_id_from_pod: extracts container ID" {
  export KUBECTL_MOCK_OUTPUT="containerd://abc123def456"

  run get_container_id_from_pod "test-pod" "default" "container1"
  assert_success
  assert_output --partial "abc123"
}

@test "get_container_id_from_pod: handles crio runtime" {
  export KUBECTL_MOCK_OUTPUT="cri-o://xyz789abc"

  run get_container_id_from_pod "test-pod" "default" "container1"
  assert_success
}

@test "get_container_id_from_pod: handles docker runtime" {
  export KUBECTL_MOCK_OUTPUT="docker://123abc456def"

  run get_container_id_from_pod "test-pod" "default" "container1"
  assert_success
}
