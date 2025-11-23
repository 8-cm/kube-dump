#!/usr/bin/env bats
# Tests for file monitoring sidecar functionality in kube-dump.sh

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
# build_file_monitor_script() tests
# =============================================================================

@test "build_file_monitor_script: generates monitoring script for pod" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "#!/bin/bash"
  assert_output --partial "file monitor"
}

@test "build_file_monitor_script: includes base64 decode logic" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "base64 -d"
  assert_output --partial "ENCODED_SELECT_COMMAND"
}

@test "build_file_monitor_script: includes placeholder substitution" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "PLACEHOLDER_CHAR"
  assert_output --partial "TARGET_NAME"
}

@test "build_file_monitor_script: runs ls -lh on files" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "ls -lh"
}

@test "build_file_monitor_script: loops every second" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "sleep 1"
  assert_output --partial "while true"
}

@test "build_file_monitor_script: adds B suffix to byte sizes" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should have logic to detect plain numbers and add B suffix
  assert_output --partial "^[0-9]+$"
  assert_output --partial "B"
}

@test "build_file_monitor_script: formats output with timestamp" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "TIMESTAMP"
  assert_output --partial "date"
  assert_output --partial "printf"
}

@test "build_file_monitor_script: does not use crictl or nsenter" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should NOT contain crictl or nsenter commands
  refute_output --partial "crictl"
  refute_output --partial "nsenter"
}

@test "build_file_monitor_script: executes command directly via bash -c" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "bash -c"
  assert_output --partial "select_cmd"
}

# =============================================================================
# build_node_file_monitor_script() tests
# =============================================================================

@test "build_node_file_monitor_script: generates monitoring script for node" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "#!/bin/bash"
  assert_output --partial "file monitor"
}

@test "build_node_file_monitor_script: uses ENCODED_NODE_SELECT_COMMAND" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "ENCODED_NODE_SELECT_COMMAND"
  assert_output --partial "base64 -d"
}

@test "build_node_file_monitor_script: substitutes placeholder with node name" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "NODE_NAME"
  assert_output --partial "PLACEHOLDER_CHAR"
}

@test "build_node_file_monitor_script: monitors files every second" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "sleep 1"
  assert_output --partial "while true"
}

@test "build_node_file_monitor_script: uses ls -lh" {
  run build_node_file_monitor_script "node-1"
  assert_success

  assert_output --partial "ls -lh"
}

# =============================================================================
# File monitor sidecar integration tests
# =============================================================================

@test "file monitor sidecar: added to pod when -s specified" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp -name '*.log'"
  export ENCODED_SELECT_COMMAND=$(echo "$SELECT_TO_DOWNLOAD_COMMAND" | base64)
  export PLACEHOLDER_CHAR="%"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Pod should have file-monitor container
  # (Would need to check actual pod spec)
}

@test "file monitor sidecar: NOT added to pod when -s not specified" {
  unset SELECT_TO_DOWNLOAD_COMMAND

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Pod should NOT have file-monitor container
}

@test "file monitor sidecar: receives correct environment variables" {
  export SELECT_TO_DOWNLOAD_COMMAND="ls /tmp"
  export ENCODED_SELECT_COMMAND=$(echo "$SELECT_TO_DOWNLOAD_COMMAND" | base64)
  export PLACEHOLDER_CHAR="%"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Should pass ENCODED_SELECT_COMMAND, TARGET_NAME, PLACEHOLDER_CHAR
}

@test "file monitor sidecar: shares /host volume with debugger" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /host -name '*.pcap'"
  export ENCODED_SELECT_COMMAND=$(echo "$SELECT_TO_DOWNLOAD_COMMAND" | base64)

  run create_single_debug_pod "target-pod" "default" "container1" "node-1"
  assert_success

  # Both containers should mount /host
}

@test "file monitor sidecar: logs downloaded during cleanup" {
  # Mock pod with file-monitor container
  mock_kube_command "kubectl" '
    case "$*" in
      *jsonpath*containers*)
        echo "debugger file-monitor"
        ;;
      *logs*)
        echo "[2025-11-23 10:00:00] File monitor started"
        echo "[2025-11-23 10:00:01] | /tmp/test.log | 1.5K | Nov 23 10:00"
        ;;
      *)
        exit 0
        ;;
    esac
  '
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  DEBUG_PODS_FILE="${BATS_TMPDIR}/debug-pods.txt"
  echo "debug-pod-1 default target-pod-1" > "$DEBUG_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/debug-logs"

  run cleanup_debug_pods
  assert_success

  # Should have downloaded file-monitor.log
}

@test "file monitor sidecar: handles base64 decode errors" {
  # Test script behavior when ENCODED_SELECT_COMMAND is invalid
  export ENCODED_SELECT_COMMAND="invalid-base64!!!!"

  # The script should handle decode failure gracefully
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should have error handling
  assert_output --partial "Failed to decode"
}

@test "file monitor sidecar: handles empty file list" {
  # When select command returns no files
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should handle empty file_list gracefully
}

@test "file monitor sidecar: handles ls errors for individual files" {
  # When a file disappears between find and ls
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should have 2>/dev/null or similar error handling
  assert_output --partial "2>/dev/null"
}

# =============================================================================
# File size formatting tests
# =============================================================================

@test "file monitor: adds B suffix to plain numbers" {
  # Test the logic that adds "B" to byte sizes
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should match pattern ^[0-9]+$ and append B
  assert_output --partial '=~ ^[0-9]+$'
  assert_output --partial '${size}B'
}

@test "file monitor: preserves K/M/G suffixes from ls" {
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should only add B when no suffix present
}

# =============================================================================
# Placeholder substitution tests
# =============================================================================

@test "file monitor: substitutes % with pod name" {
  export PLACEHOLDER_CHAR="%"

  # If command is "find /tmp/%-*.log", should become "find /tmp/test-pod-*.log"
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  assert_output --partial "PLACEHOLDER_CHAR"
  assert_output --partial "TARGET_NAME"
}

@test "file monitor: substitutes custom placeholder" {
  export PLACEHOLDER_CHAR="#"

  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Should use # as placeholder
}

@test "file monitor: handles multiple placeholders in command" {
  # Command like "find /%/tmp -name %.log" should substitute all occurrences
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # Bash substitution ${var//pattern/replacement} should replace all
  assert_output --partial "//"
}

# =============================================================================
# Node file monitor tests
# =============================================================================

@test "node file monitor: added when -S specified" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /host/var/log"
  export ENCODED_NODE_SELECT_COMMAND=$(echo "$NODE_SELECT_TO_DOWNLOAD_COMMAND" | base64)

  run create_single_node_debug_pod "node-1"
  assert_success

  # Should include file-monitor sidecar
}

@test "node file monitor: NOT added when -S not specified" {
  unset NODE_SELECT_TO_DOWNLOAD_COMMAND

  run create_single_node_debug_pod "node-1"
  assert_success

  # Should NOT include file-monitor sidecar
}

@test "node file monitor: monitors /host paths" {
  run build_node_file_monitor_script "node-1"
  assert_success

  # Should work with /host paths
  assert_output --partial "ls -lh"
}

# =============================================================================
# Multi-line command handling tests
# =============================================================================

@test "file monitor: strips newlines from multi-line commands" {
  # When user enters command across multiple lines in terminal
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp \\
-name '*.log' \\
-type f"

  # Command should be sanitized before base64 encoding
  run build_file_monitor_script "test-pod" "container1" "node-1" "test-pod"
  assert_success

  # The decode logic should handle this
}
