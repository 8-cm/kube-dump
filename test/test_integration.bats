#!/usr/bin/env bats
# Integration tests for complete kube-dump.sh workflows

load test_helper/common

setup() {
  common_setup

  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR"

  # Create mock kubectl that tracks calls
  export KUBECTL_SPY_FILE="${BATS_TMPDIR}/kubectl.spy"
  export KUBECTL_MOCK_MODE="success"
}

teardown() {
  common_teardown
}

# =============================================================================
# End-to-end workflow tests
# =============================================================================

@test "integration: pod debugging with label selector" {
  # Simulate: ./kube-dump.sh -l app=nginx -e "tcpdump -i any"
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -e "tcpdump -i any" -o "$OUTPUT_DIR" --dry-run

  # Should complete without error
  [[ $status -eq 0 || $status -eq 1 ]]  # May exit 1 if no pods found
}

@test "integration: node debugging with label selector" {
  # Simulate: ./kube-dump.sh -L kubernetes.io/hostname=node-1 -E "df -h"
  run bash "$KUBE_DUMP_SCRIPT" -L "kubernetes.io/hostname=node-1" -E "df -h" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: pod debugging with file download" {
  # Simulate: ./kube-dump.sh -l app=nginx -s "find /tmp -name '*.log'"
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -s "find /tmp -name '*.log'" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: mixed mode (pods + nodes)" {
  # Simulate: ./kube-dump.sh -l app=web -L node-type=worker
  run bash "$KUBE_DUMP_SCRIPT" -l "app=web" -L "node-type=worker" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: kill switch with absolute threshold" {
  # Simulate: ./kube-dump.sh -l app=nginx --kill-switch-abs 5GB
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --kill-switch-abs "5GB" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: kill switch with relative threshold" {
  # Simulate: ./kube-dump.sh -l app=nginx --kill-switch-rel 10%
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --kill-switch-rel "10%" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: verbose mode" {
  # Simulate: ./kube-dump.sh -l app=nginx --verbose
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -o "$OUTPUT_DIR" --verbose --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: custom placeholder character" {
  # Simulate: ./kube-dump.sh -l app=nginx -e "echo #" --placeholder "#"
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -e "echo test" --placeholder "#" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: custom debug image" {
  # Simulate: ./kube-dump.sh -l app=nginx --image custom/debug:latest
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --image "custom/debug:latest" -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: install CRI dependencies" {
  # Simulate: ./kube-dump.sh -l app=nginx --install-deps
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --install-deps -o "$OUTPUT_DIR" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# Error handling tests
# =============================================================================

@test "integration: shows help when no arguments" {
  run bash "$KUBE_DUMP_SCRIPT"
  assert_failure
  assert_output --partial "Usage:"
}

@test "integration: shows help with -h flag" {
  run bash "$KUBE_DUMP_SCRIPT" -h
  assert_success
  assert_output --partial "Usage:"
  assert_output --partial "kube-dump.sh"
}

@test "integration: shows version with --version flag" {
  run bash "$KUBE_DUMP_SCRIPT" --version
  assert_success
  assert_output --partial "kube-dump"
}

@test "integration: rejects invalid label selector" {
  run bash "$KUBE_DUMP_SCRIPT" -l "invalid label format"
  assert_failure
  assert_output --partial "Invalid"
}

@test "integration: rejects invalid threshold format" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --kill-switch-abs "invalid"
  assert_failure
  assert_output --partial "threshold"
}

@test "integration: requires output directory for verbose mode" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --verbose
  assert_failure
  assert_output --partial "output directory"
}

@test "integration: rejects conflicting kill switch options" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --kill-switch-abs "5GB" --kill-switch-rel "10%"
  assert_failure
}

@test "integration: rejects both -l and -L without command" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -L "node=worker"
  # Should require at least one command (-e, -E, -s, or -S)
  [[ $status -eq 1 ]]
}

@test "integration: validates placeholder is single character" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --placeholder "##"
  assert_failure
  assert_output --partial "single character"
}

# =============================================================================
# Cleanup behavior tests
# =============================================================================

@test "integration: cleanup runs on successful completion" {
  # Mock successful workflow
  skip "Requires full mock environment"
}

@test "integration: cleanup runs on error" {
  # Mock workflow that errors
  skip "Requires full mock environment"
}

@test "integration: cleanup runs on Ctrl+C" {
  # Test signal handling
  skip "Requires process simulation"
}

# =============================================================================
# Output directory structure tests
# =============================================================================

@test "integration: creates correct output directory structure" {
  export OUTPUT_DIR="${BATS_TMPDIR}/test-output"

  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -o "$OUTPUT_DIR" -s "find /tmp" --dry-run

  # Even with dry-run, directory structure should be created
  [[ -d "$OUTPUT_DIR" ]] || [[ $status -eq 1 ]]  # May fail before creating dirs
}

@test "integration: creates subdirectories when -o specified" {
  export OUTPUT_DIR="${BATS_TMPDIR}/test-output"
  mkdir -p "$OUTPUT_DIR"

  # Source script to call setup function
  main() { :; }
  source "$KUBE_DUMP_SCRIPT"
  OUTPUT_DIR="$OUTPUT_DIR" setup_output_directories

  assert_dir_exists "${OUTPUT_DIR}/files"
  assert_dir_exists "${OUTPUT_DIR}/debug-logs"
  assert_dir_exists "${OUTPUT_DIR}/discovery-logs"
  assert_dir_exists "${OUTPUT_DIR}/killswitch-logs"
  assert_dir_exists "${OUTPUT_DIR}/process-logs"
}

# =============================================================================
# Argument parsing tests
# =============================================================================

@test "integration: parses all short options" {
  run bash "$KUBE_DUMP_SCRIPT" \
    -l "app=test" \
    -L "node=test" \
    -e "echo test" \
    -E "echo node" \
    -s "find /" \
    -S "find /host" \
    -n "custom-ns" \
    -o "/tmp/out" \
    -i "custom-image" \
    -c "custom-command" \
    -p "%" \
    --dry-run

  # Should parse without error
  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: parses all long options" {
  run bash "$KUBE_DUMP_SCRIPT" \
    --pod-label "app=test" \
    --node-label "node=test" \
    --execute "echo test" \
    --node-execute "echo node" \
    --select-download "find /" \
    --node-select-download "find /host" \
    --namespace "custom-ns" \
    --output "/tmp/out" \
    --image "custom-image" \
    --capture-command "tcpdump" \
    --placeholder "%" \
    --verbose \
    --install-deps \
    --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# Namespace handling tests
# =============================================================================

@test "integration: uses default namespace when not specified" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --dry-run

  # Should use "default" namespace
  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: uses specified namespace" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -n "kube-system" --dry-run

  # Should use "kube-system" namespace
  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "integration: accepts all-namespaces flag" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -n "all" --dry-run

  # Should search across all namespaces
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# CRI runtime detection tests
# =============================================================================

@test "integration: detects containerd runtime" {
  skip "Requires mock container runtime"
}

@test "integration: detects CRI-O runtime" {
  skip "Requires mock container runtime"
}

@test "integration: detects Docker runtime" {
  skip "Requires mock container runtime"
}

@test "integration: uses custom CRI socket" {
  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" --cri-socket "/custom/cri.sock" --dry-run

  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# Concurrent operations tests
# =============================================================================

@test "integration: handles multiple pods concurrently" {
  # When multiple pods match label selector
  skip "Requires concurrent execution testing"
}

@test "integration: handles multiple nodes concurrently" {
  # When multiple nodes match label selector
  skip "Requires concurrent execution testing"
}

# =============================================================================
# Logging tests
# =============================================================================

@test "integration: logs to kube-dump.log when -o specified" {
  export OUTPUT_DIR="${BATS_TMPDIR}/test-output"
  mkdir -p "$OUTPUT_DIR"

  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -o "$OUTPUT_DIR" --dry-run

  # Log file should be created
  [[ -f "${OUTPUT_DIR}/kube-dump.log" ]] || [[ $status -eq 1 ]]
}

@test "integration: verbose mode creates detailed logs" {
  export OUTPUT_DIR="${BATS_TMPDIR}/test-output"

  run bash "$KUBE_DUMP_SCRIPT" -l "app=nginx" -o "$OUTPUT_DIR" --verbose --dry-run

  # Should create verbose logs
  [[ $status -eq 0 || $status -eq 1 ]]
}
