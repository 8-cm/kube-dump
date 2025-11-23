#!/bin/bash
# Common test helper functions and setup

# Load bats libraries
load '../bats-support/load'
load '../bats-assert/load'
load '../bats-file/load'

# Test environment setup
export BATS_TEST_DIRNAME="${BATS_TEST_DIRNAME:-$(pwd)/test}"
export KUBE_DUMP_SCRIPT="${BATS_TEST_DIRNAME}/../kube-dump.sh"
export TEST_TEMP_DIR="${BATS_TEST_DIRNAME}/tmp"
export MOCK_DIR="${BATS_TEST_DIRNAME}/mocks"

# Add mocks to PATH
export PATH="${MOCK_DIR}:${PATH}"

# Common setup for all tests
common_setup() {
  # Create temp directory for test
  export BATS_TMPDIR="${TEST_TEMP_DIR}/bats-$$-${RANDOM}"
  mkdir -p "$BATS_TMPDIR"

  # Set predictable output directory
  export OUTPUT_DIR="${BATS_TMPDIR}/output"

  # Disable colors in output for easier testing
  export NO_COLOR=1

  # Mock kubectl/oc availability
  export KUBE_CLI="${MOCK_DIR}/kubectl"

  # Source the script functions (without running main)
  # We'll override main() to prevent auto-execution
  source "$KUBE_DUMP_SCRIPT" || return 1
}

# Common teardown for all tests
common_teardown() {
  # Clean up temp directory
  if [[ -d "$BATS_TMPDIR" ]]; then
    rm -rf "$BATS_TMPDIR"
  fi
}

# Helper to create mock kubectl/oc command
mock_kube_command() {
  local command_name="$1"
  local mock_script="$2"

  cat > "${MOCK_DIR}/${command_name}" <<EOF
#!/bin/bash
${mock_script}
EOF
  chmod +x "${MOCK_DIR}/${command_name}"
}

# Helper to create mock kubectl that succeeds
mock_kubectl_success() {
  mock_kube_command "kubectl" 'exit 0'
}

# Helper to create mock kubectl that fails
mock_kubectl_fail() {
  mock_kube_command "kubectl" 'echo "Error: command failed" >&2; exit 1'
}

# Helper to capture kubectl calls
setup_kubectl_spy() {
  local spy_file="$1"
  mock_kube_command "kubectl" "echo \"\$@\" >> \"${spy_file}\"; exit 0"
}

# Helper to mock kubectl with custom output
mock_kubectl_output() {
  local output="$1"
  mock_kube_command "kubectl" "echo '${output}'; exit 0"
}

# Helper to source kube-dump.sh without running main
source_script_functions() {
  # Create a wrapper that sources the script but prevents main execution
  (
    # Override main to do nothing
    main() { :; }
    source "$KUBE_DUMP_SCRIPT"
  )
}

# Helper to run kube-dump with args
run_kube_dump() {
  run bash "$KUBE_DUMP_SCRIPT" "$@"
}

# Helper to check if function exists
function_exists() {
  declare -f "$1" > /dev/null
  return $?
}

# Helper to create test pod manifest
create_test_pod_manifest() {
  cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
spec:
  containers:
  - name: test-container
    image: nginx
status:
  phase: Running
EOF
}

# Helper to create test node manifest
create_test_node_manifest() {
  cat <<EOF
apiVersion: v1
kind: Node
metadata:
  name: test-node
status:
  conditions:
  - type: Ready
    status: "True"
EOF
}
