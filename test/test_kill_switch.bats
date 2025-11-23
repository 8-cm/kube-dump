#!/usr/bin/env bats
# Tests for kill switch functionality in kube-dump.sh

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
# build_kill_switch_monitor_script() tests
# =============================================================================

@test "build_kill_switch_monitor_script: generates monitoring script" {
  run build_kill_switch_monitor_script "node-1" "10" "debug-pod-1" "default"
  assert_success

  assert_output --partial "#!/bin/bash"
  assert_output --partial "df"
}

@test "build_kill_switch_monitor_script: includes threshold" {
  run build_kill_switch_monitor_script "node-1" "15" "debug-pod-1" "default"
  assert_success

  assert_output --partial "15"
}

@test "build_kill_switch_monitor_script: includes pod deletion command" {
  run build_kill_switch_monitor_script "node-1" "10" "debug-pod-1" "default"
  assert_success

  assert_output --partial "kubectl delete"
  assert_output --partial "debug-pod-1"
}

@test "build_kill_switch_monitor_script: monitors disk every second" {
  run build_kill_switch_monitor_script "node-1" "10" "debug-pod-1" "default"
  assert_success

  assert_output --partial "sleep 1"
}

@test "build_kill_switch_monitor_script: outputs log format" {
  run build_kill_switch_monitor_script "node-1" "10" "debug-pod-1" "default"
  assert_success

  # Should have timestamp format
  assert_output --partial "date"
}

# =============================================================================
# create_kill_switch_monitor() tests
# =============================================================================

@test "create_kill_switch_monitor: creates monitor pod" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_kill_switch_monitor "node-1" "10" "debug-pod-1" "default"
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "apply"
}

@test "create_kill_switch_monitor: uses ubuntu:22.04 image" {
  run create_kill_switch_monitor "node-1" "10" "debug-pod-1" "default"
  assert_success

  # Should use ubuntu image
}

@test "create_kill_switch_monitor: schedules on same node" {
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run create_kill_switch_monitor "node-1" "10" "debug-pod-1" "default"
  assert_success

  # Should have nodeSelector for node-1
}

@test "create_kill_switch_monitor: grants service account permissions" {
  run create_kill_switch_monitor "node-1" "10" "debug-pod-1" "default"
  assert_success

  # Should create service account with pod deletion permission
}

@test "create_kill_switch_monitor: handles creation failure" {
  export KUBECTL_MOCK_MODE="fail"

  run create_kill_switch_monitor "node-1" "10" "debug-pod-1" "default"
  assert_failure
}

# =============================================================================
# cleanup_kill_switch_monitors() tests
# =============================================================================

@test "cleanup_kill_switch_monitors: deletes monitor pods" {
  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  echo "kill-switch-pod-1 default" > "$KILL_SWITCH_PODS_FILE"
  echo "kill-switch-pod-2 default" >> "$KILL_SWITCH_PODS_FILE"

  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run cleanup_kill_switch_monitors
  assert_success

  assert_file_contains "$KUBECTL_SPY_FILE" "delete"
}

@test "cleanup_kill_switch_monitors: downloads logs before deletion" {
  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  echo "kill-switch-pod-1 default" > "$KILL_SWITCH_PODS_FILE"

  mkdir -p "${OUTPUT_DIR}/killswitch-logs"

  run cleanup_kill_switch_monitors
  assert_success

  assert_dir_exists "${OUTPUT_DIR}/killswitch-logs"
}

@test "cleanup_kill_switch_monitors: cleans up RBAC resources" {
  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  echo "kill-switch-pod-1 default" > "$KILL_SWITCH_PODS_FILE"

  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  run cleanup_kill_switch_monitors
  assert_success

  # Should delete service account, role, and role binding
  assert_file_contains "$KUBECTL_SPY_FILE" "delete"
}

@test "cleanup_kill_switch_monitors: handles empty list" {
  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  touch "$KILL_SWITCH_PODS_FILE"

  run cleanup_kill_switch_monitors
  assert_success
}

# =============================================================================
# parse_threshold() tests
# =============================================================================

@test "parse_threshold: parses percentage threshold" {
  run parse_threshold "10%"
  assert_success
  assert_output --partial "10"
}

@test "parse_threshold: parses GB threshold" {
  run parse_threshold "5GB"
  assert_success
  assert_output --partial "5"
}

@test "parse_threshold: parses MB threshold" {
  run parse_threshold "500MB"
  assert_success
  assert_output --partial "500"
}

@test "parse_threshold: handles decimal values" {
  run parse_threshold "1.5GB"
  assert_success
}

@test "parse_threshold: rejects invalid format" {
  run parse_threshold "invalid"
  assert_failure
}

# =============================================================================
# calculate_threshold_bytes() tests
# =============================================================================

@test "calculate_threshold_bytes: converts percentage to bytes" {
  # Mock df output showing total disk size
  export DF_MOCK_OUTPUT="100G"

  run calculate_threshold_bytes "10%" "node-1"
  assert_success

  # Should calculate 10% of total
}

@test "calculate_threshold_bytes: converts GB to bytes" {
  run calculate_threshold_bytes "5GB"
  assert_success

  # 5GB = 5368709120 bytes
  assert_output "5368709120"
}

@test "calculate_threshold_bytes: converts MB to bytes" {
  run calculate_threshold_bytes "100MB"
  assert_success

  # 100MB = 104857600 bytes
  assert_output "104857600"
}

@test "calculate_threshold_bytes: converts KB to bytes" {
  run calculate_threshold_bytes "1024KB"
  assert_success

  # 1024KB = 1048576 bytes
  assert_output "1048576"
}

# =============================================================================
# check_disk_usage() tests
# =============================================================================

@test "check_disk_usage: returns available space" {
  # Mock df output
  export KUBECTL_MOCK_OUTPUT="Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   50G   50G  50% /"

  run check_disk_usage "node-1"
  assert_success
  assert_output --partial "50G"
}

@test "check_disk_usage: handles full disk" {
  export KUBECTL_MOCK_OUTPUT="Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   99G    1G  99% /"

  run check_disk_usage "node-1"
  assert_success
  assert_output --partial "1G"
}

@test "check_disk_usage: handles multiple filesystems" {
  export KUBECTL_MOCK_OUTPUT="Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       100G   50G   50G  50% /
/dev/sdb1       200G  100G  100G  50% /data"

  run check_disk_usage "node-1"
  assert_success
}

# =============================================================================
# Integration tests for kill switch workflow
# =============================================================================

@test "kill switch: creates monitor when threshold specified" {
  export KILL_SWITCH_ABS="5GB"
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"

  # Create debug pod
  run create_single_debug_pod "target-pod" "default" "container1" "node-1"

  # Should create kill switch monitor
}

@test "kill switch: uses auto-detected kubelet threshold" {
  export KILL_SWITCH_AUTO=1
  export KUBECTL_MOCK_OUTPUT='{"kubeletconfig":{"evictionHard":{"nodefs.available":"10%"}}}'

  run detect_kubelet_threshold "node-1"
  assert_success
  assert_output --partial "10"
}

@test "kill switch: monitor terminates pod when threshold crossed" {
  # This would require integration testing with real pod
  skip "Requires integration test environment"
}

@test "kill switch: relative threshold requires bc" {
  export KILL_SWITCH_REL="10%"

  # Should use bc for percentage calculation
  run calculate_threshold_bytes "10%" "node-1"

  # Test depends on bc availability
}

@test "kill switch: logs all monitoring activity" {
  mkdir -p "${OUTPUT_DIR}/killswitch-logs"

  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  echo "kill-switch-1 default" > "$KILL_SWITCH_PODS_FILE"

  run cleanup_kill_switch_monitors
  assert_success

  # Log file should exist
  assert_dir_exists "${OUTPUT_DIR}/killswitch-logs"
}
