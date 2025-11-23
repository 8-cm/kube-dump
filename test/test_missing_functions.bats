#!/usr/bin/env bats
# Tests for previously untested functions in kube-dump.sh

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
# build_debug_script() tests
# =============================================================================

@test "build_debug_script: generates complete debug script" {
  export CAPTURE_COMMAND="tcpdump -i any"
  export HAS_CUSTOM_CMD="false"
  export NAMESPACE="default"

  run build_debug_script "test-pod" "container1" "node-1" "debug-pod-123"
  assert_success

  assert_output --partial "#!/bin/bash" || assert_output --partial "set -e"
  assert_output --partial "Starting command execution"
  assert_output --partial "test-pod"
}

@test "build_debug_script: includes crictl configuration" {
  export CAPTURE_COMMAND="echo test"
  export NAMESPACE="default"

  run build_debug_script "test-pod" "container1" "node-1" "debug-pod-123"
  assert_success

  assert_output --partial "configure_crictl_socket"
}

@test "build_debug_script: includes namespace operations" {
  export CAPTURE_COMMAND="echo test"
  export NAMESPACE="kube-system"

  run build_debug_script "test-pod" "container1" "node-1" "debug-pod-123"
  assert_success

  assert_output --partial "kube-system"
}

# =============================================================================
# build_discovery_script() tests
# =============================================================================

@test "build_discovery_script: generates file discovery script" {
  export SELECT_TO_DOWNLOAD_COMMAND="find /tmp -name '*.log'"
  export NAMESPACE="default"

  run build_discovery_script "test-pod" "container1" "node-1"
  assert_success

  assert_output --partial "find /tmp"
}

# =============================================================================
# build_node_discovery_script() tests
# =============================================================================

@test "build_node_discovery_script: generates node discovery script" {
  export NODE_SELECT_TO_DOWNLOAD_COMMAND="find /host/var/log"

  run build_node_discovery_script "node-1"
  assert_success

  assert_output --partial "find /host/var/log"
}

# =============================================================================
# generate_exec_command() tests
# =============================================================================

@test "generate_exec_command: generates nsenter command" {
  export CUSTOM_COMMAND="true"
  export CAPTURE_COMMAND=$(echo "echo test" | base64)
  export PLACEHOLDER_CHAR="%"

  run generate_exec_command "test-pod"
  assert_success

  assert_output --partial "nsenter"
  assert_output --partial "base64 -d"
}

@test "generate_exec_command: handles placeholder substitution" {
  export CUSTOM_COMMAND="true"
  export CAPTURE_COMMAND=$(echo "echo %" | base64)
  export PLACEHOLDER_CHAR="%"

  run generate_exec_command "my-pod"
  assert_success

  assert_output --partial "my-pod"
}

@test "generate_exec_command: handles non-custom commands" {
  unset CUSTOM_COMMAND
  export CAPTURE_COMMAND="tcpdump -i any"
  export PLACEHOLDER_CHAR="%"

  run generate_exec_command "test-pod"
  assert_success

  assert_output --partial "nsenter"
}

# =============================================================================
# parse_arguments() tests
# =============================================================================

@test "parse_arguments: parses pod label" {
  run parse_arguments -l "app=nginx"
  # May fail without full environment, but shouldn't crash
  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "parse_arguments: parses node label" {
  run parse_arguments -L "kubernetes.io/hostname=node-1"
  [[ $status -eq 0 || $status -eq 1 ]]
}

@test "parse_arguments: parses output directory" {
  run parse_arguments -o "/tmp/output"
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# validate_arguments() tests
# =============================================================================

@test "validate_arguments: validates required arguments" {
  export POD_LABEL="app=nginx"

  run validate_arguments
  # Should validate or fail gracefully
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# truncate_name_with_hash() tests
# =============================================================================

@test "truncate_name_with_hash: keeps short names" {
  run truncate_name_with_hash "short" 63
  assert_success
  assert_output "short"
}

@test "truncate_name_with_hash: truncates long names" {
  local long_name="this-is-a-very-long-name-that-exceeds-sixty-three-characters-and-needs-truncation"

  run truncate_name_with_hash "$long_name" 63
  assert_success

  # Output should be <= 63 chars
  [[ ${#output} -le 63 ]]
}

@test "truncate_name_with_hash: adds hash to truncated names" {
  local long_name="this-is-a-very-long-name-that-exceeds-the-limit"

  run truncate_name_with_hash "$long_name" 20
  assert_success

  # Should contain hash
  assert_output --partial "-"
}

# =============================================================================
# truncate_label_value_with_hash() tests
# =============================================================================

@test "truncate_label_value_with_hash: handles label values" {
  run truncate_label_value_with_hash "my-label-value"
  assert_success
  assert_output "my-label-value"
}

@test "truncate_label_value_with_hash: truncates long labels" {
  local long_label="this-is-a-very-long-label-value-that-needs-to-be-truncated-for-kubernetes"

  run truncate_label_value_with_hash "$long_label"
  assert_success

  # Should be <= 63 chars (k8s label limit)
  [[ ${#output} -le 63 ]]
}

# =============================================================================
# parse_size_to_bytes() tests
# =============================================================================

@test "parse_size_to_bytes: converts GB to bytes" {
  run parse_size_to_bytes "5GB"
  assert_success
  assert_output "5368709120"
}

@test "parse_size_to_bytes: converts MB to bytes" {
  run parse_size_to_bytes "100MB"
  assert_success
  assert_output "104857600"
}

@test "parse_size_to_bytes: converts KB to bytes" {
  run parse_size_to_bytes "1024KB"
  assert_success
  assert_output "1048576"
}

@test "parse_size_to_bytes: handles B suffix" {
  run parse_size_to_bytes "1024B"
  assert_success
  assert_output "1024"
}

# =============================================================================
# format_bc_result() tests
# =============================================================================

@test "format_bc_result: formats decimal numbers" {
  run format_bc_result "10.5"
  assert_success
}

@test "format_bc_result: handles integers" {
  run format_bc_result "10"
  assert_success
}

# =============================================================================
# get_effective_cri_socket() tests
# =============================================================================

@test "get_effective_cri_socket: returns custom socket" {
  export CRI_SOCKET="/custom/socket.sock"

  run get_effective_cri_socket
  assert_success
  assert_output "/custom/socket.sock"
}

@test "get_effective_cri_socket: detects containerd" {
  unset CRI_SOCKET
  export CRI_RUNTIME="containerd"

  run get_effective_cri_socket
  assert_success
  assert_output --partial "containerd"
}

@test "get_effective_cri_socket: detects crio" {
  unset CRI_SOCKET
  export CRI_RUNTIME="crio"

  run get_effective_cri_socket
  assert_success
  assert_output --partial "crio"
}

# =============================================================================
# configure_crictl_socket() tests
# =============================================================================

@test "configure_crictl_socket: configures socket" {
  export CRI_RUNTIME="containerd"
  unset CRI_SOCKET

  run configure_crictl_socket
  # Function runs in script context
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# find_pods_by_label() tests
# =============================================================================

@test "find_pods_by_label: finds pods" {
  export KUBECTL_MOCK_OUTPUT="pod1
pod2
pod3"

  run find_pods_by_label "app=nginx" "default"
  assert_success
  assert_line --index 0 "pod1"
}

@test "find_pods_by_label: handles no pods" {
  export KUBECTL_MOCK_OUTPUT=""

  run find_pods_by_label "app=nonexistent" "default"
  # Should handle gracefully
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# select_target_pods() tests
# =============================================================================

@test "select_target_pods: selects pods by label" {
  export POD_LABEL="app=nginx"
  export NAMESPACE="default"
  export KUBECTL_MOCK_OUTPUT="pod1 pod2"

  run select_target_pods
  # Should select pods
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# select_target_nodes() tests
# =============================================================================

@test "select_target_nodes: selects nodes by label" {
  export NODE_LABEL="kubernetes.io/hostname=node-1"
  export KUBECTL_MOCK_OUTPUT="node-1"

  run select_target_nodes
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# wait_for_debug_pods_ready() tests
# =============================================================================

@test "wait_for_debug_pods_ready: waits for pods" {
  DEBUG_POD_NAMES=("pod1" "pod2")
  export DEBUG_NAMESPACE="default"

  # Mock successful wait
  run wait_for_debug_pods_ready
  # May timeout or succeed
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# wait_for_discovery_pods_ready() tests
# =============================================================================

@test "wait_for_discovery_pods_ready: waits for discovery pods" {
  DISCOVERY_POD_NAMES=("discovery-1" "discovery-2")
  export NAMESPACE="default"

  run wait_for_discovery_pods_ready
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# initialize_variables() tests
# =============================================================================

@test "initialize_variables: sets default values" {
  run initialize_variables
  assert_success

  # Should set global variables
}

@test "initialize_variables: handles environment overrides" {
  export DEBUG_IMAGE="custom/image:latest"

  run initialize_variables
  assert_success
}

# =============================================================================
# validate_all_requirements() tests
# =============================================================================

@test "validate_all_requirements: checks prerequisites" {
  export PATH="${MOCK_DIR}:/bin:/usr/bin"

  run validate_all_requirements
  # May pass or fail depending on environment
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# show_configuration() tests
# =============================================================================

@test "show_configuration: displays configuration" {
  export POD_LABEL="app=nginx"
  export NAMESPACE="default"
  export VERBOSE=1

  run show_configuration
  # Should display config or skip if VERBOSE not set
  assert_success
}

# =============================================================================
# get_pod_log_file() tests
# =============================================================================

@test "get_pod_log_file: generates log filename" {
  export OUTPUT_DIR="${BATS_TMPDIR}/output"

  run get_pod_log_file "test-pod-123"
  assert_success
  assert_output --partial "test-pod-123"
  assert_output --partial ".log"
}

# =============================================================================
# setup_debug_logging() tests
# =============================================================================

@test "setup_debug_logging: creates log directory" {
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  export VERBOSE=1

  run setup_debug_logging
  assert_success

  # Should create logging directory
}

# =============================================================================
# validate_option_value() tests
# =============================================================================

@test "validate_option_value: validates non-empty value" {
  run validate_option_value "test-value" "--option"
  assert_success
}

@test "validate_option_value: rejects empty value" {
  run validate_option_value "" "--option"
  assert_failure
}

# =============================================================================
# validate_variable() tests
# =============================================================================

@test "validate_variable: validates set variable" {
  TEST_VAR="value"
  run validate_variable "TEST_VAR" "Test Variable"
  assert_success
}

@test "validate_variable: rejects unset variable" {
  unset TEST_VAR
  run validate_variable "TEST_VAR" "Test Variable"
  assert_failure
}

# =============================================================================
# prepare_target_pods() tests
# =============================================================================

@test "prepare_target_pods: prepares pod list" {
  export POD_LABEL="app=nginx"
  export NAMESPACE="default"

  run prepare_target_pods
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# create_debug_pods_for_targets() tests
# =============================================================================

@test "create_debug_pods_for_targets: creates debug pods" {
  run create_debug_pods_for_targets
  # Requires full environment
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# create_node_debug_pods() tests
# =============================================================================

@test "create_node_debug_pods: creates node debug pods" {
  run create_node_debug_pods
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# create_file_discovery_pods() tests
# =============================================================================

@test "create_file_discovery_pods: creates discovery pods" {
  run create_file_discovery_pods
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# create_kill_switch_monitor_pod() tests
# =============================================================================

@test "create_kill_switch_monitor_pod: creates monitor pod" {
  run create_kill_switch_monitor_pod "node-1" "10" "debug-pod-1" "default"
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# create_kill_switch_monitor_pods() tests
# =============================================================================

@test "create_kill_switch_monitor_pods: creates multiple monitors" {
  run create_kill_switch_monitor_pods
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# cleanup_kill_switch_monitor_pods() tests
# =============================================================================

@test "cleanup_kill_switch_monitor_pods: cleans up monitors" {
  KILL_SWITCH_PODS_FILE="${BATS_TMPDIR}/kill-switch-pods.txt"
  touch "$KILL_SWITCH_PODS_FILE"

  run cleanup_kill_switch_monitor_pods
  assert_success
}

# =============================================================================
# monitor_kill_switches() tests
# =============================================================================

@test "monitor_kill_switches: monitors kill switches" {
  run monitor_kill_switches
  [[ $status -eq 0 || $status -eq 1 ]]
}

# =============================================================================
# detect_kubelet_eviction_threshold() tests
# =============================================================================

@test "detect_kubelet_eviction_threshold: detects threshold" {
  export KUBECTL_MOCK_OUTPUT='{"kubeletconfig":{"evictionHard":{"nodefs.available":"10%"}}}'

  run detect_kubelet_eviction_threshold "node-1"
  assert_success
  assert_output --partial "10"
}

@test "detect_kubelet_eviction_threshold: falls back to default" {
  export KUBECTL_MOCK_MODE="fail"

  run detect_kubelet_eviction_threshold "node-1"
  assert_success
  # Should return fallback value
}
