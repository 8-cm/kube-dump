# kube-dump Test Suite

Comprehensive test suite for kube-dump.sh using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core).

## 📋 Test Coverage

The test suite includes **280+ test cases** covering:

- ✅ Utility functions (hash_input, format_message, validation)
- ✅ Pod operations (create, wait, cleanup, execute)
- ✅ Node operations (create, cleanup, node debugging)
- ✅ File operations (discovery, download, CRI operations)
- ✅ Kill switch functionality (monitoring, thresholds, cleanup)
- ✅ File monitoring sidecar (pod and node monitors)
- ✅ Integration tests (end-to-end workflows)

## 🚀 Quick Start

### Install Test Dependencies

**Note:** In CI/CD (GitHub Actions), dependencies are automatically installed. For local development:

```bash
cd test
git clone --depth 1 https://github.com/bats-core/bats-core.git
git clone --depth 1 https://github.com/bats-core/bats-support.git
git clone --depth 1 https://github.com/bats-core/bats-assert.git
git clone --depth 1 https://github.com/bats-core/bats-file.git
```

These directories are excluded from the repository via `.gitignore`.

### Run All Tests

```bash
./test/run_tests.sh
```

### Run Specific Test File

```bash
./test/bats-core/bin/bats test/test_utility_functions.bats
```

### Run Tests Matching Pattern

```bash
FILTER="hash_input" ./test/run_tests.sh
```

### Verbose Output

```bash
VERBOSE=1 ./test/run_tests.sh
```

## 📊 Coverage Analysis

Check test coverage:

```bash
./test/analyze_coverage.sh
```

This analyzes which functions are tested and provides a coverage percentage.

## 📁 Test Structure

```
test/
├── README.md                      # This file
├── run_tests.sh                   # Test runner
├── analyze_coverage.sh            # Coverage analyzer
├── bats-core/                     # Bats testing framework
├── bats-support/                  # Bats support library
├── bats-assert/                   # Assertion library
├── bats-file/                     # File assertion library
├── test_helper/
│   └── common.bash                # Common test helpers
├── mocks/
│   ├── kubectl                    # Mock kubectl command
│   └── oc -> kubectl              # Mock oc (symlink)
├── fixtures/                      # Test fixtures
├── tmp/                           # Temporary test files
└── Test files:
    ├── test_utility_functions.bats    # Utility function tests
    ├── test_pod_operations.bats       # Pod operation tests
    ├── test_node_operations.bats      # Node operation tests
    ├── test_file_operations.bats      # File operation tests
    ├── test_kill_switch.bats          # Kill switch tests
    ├── test_file_monitor.bats         # File monitor tests
    └── test_integration.bats          # Integration tests
```

## 🧪 Test Categories

### 1. Utility Functions (test_utility_functions.bats)

Tests for core utility functions:
- `hash_input()` - Hash generation with md5sum/md5/cksum fallback
- `format_message()` / `format_message_stderr()` - Output formatting
- `validate_threshold()` - Threshold validation (%, GB, MB, KB)
- `validate_placeholder()` - Placeholder character validation
- `detect_kube_cli()` - kubectl/oc detection
- `setup_output_directories()` - Directory structure creation
- `check_prerequisites()` - Dependency validation
- `convert_threshold_to_bytes()` - Threshold conversion
- `run_kube_cmd()` - Kubernetes command execution

### 2. Pod Operations (test_pod_operations.bats)

Tests for pod debugging:
- `get_pods_by_label()` - Pod selection by label
- `get_pod_node()` - Node retrieval for pod
- `get_pod_container()` - Container name extraction
- `create_single_debug_pod()` - Debug pod creation
- `wait_for_pod_ready()` - Pod readiness waiting
- `cleanup_debug_pods()` - Debug pod cleanup
- `execute_command_on_pod()` - Command execution
- `get_pod_namespace()` - Namespace detection
- `validate_pod_label()` - Label validation

### 3. Node Operations (test_node_operations.bats)

Tests for node debugging:
- `get_nodes_by_label()` - Node selection by label
- `create_single_node_debug_pod()` - Node debug pod creation
- `cleanup_node_debug_pods()` - Node debug pod cleanup
- `validate_node_label()` - Node label validation
- `get_node_status()` - Node status retrieval
- `detect_kubelet_threshold()` - Kubelet eviction threshold detection
- `build_node_debug_script()` - Node debug script generation
- `build_node_file_monitor_script()` - Node file monitor script

### 4. File Operations (test_file_operations.bats)

Tests for file discovery and download:
- `create_discovery_pod()` - Pod file discovery
- `create_node_discovery_pod()` - Node file discovery
- `get_files_from_discovery_pod()` - File list retrieval
- `download_file_from_pod()` - Pod file download
- `download_file_from_node()` - Node file download
- `handle_file_downloads()` - Full download workflow orchestration
- `cleanup_discovery_pods()` - Discovery pod cleanup
- `get_container_id_from_pod()` - CRI container ID extraction

### 5. Kill Switch (test_kill_switch.bats)

Tests for kill switch monitoring:
- `build_kill_switch_monitor_script()` - Monitor script generation
- `create_kill_switch_monitor()` - Monitor pod creation
- `cleanup_kill_switch_monitors()` - Monitor cleanup
- `parse_threshold()` - Threshold parsing
- `calculate_threshold_bytes()` - Byte conversion
- `check_disk_usage()` - Disk usage checking
- Integration tests for auto-detection and monitoring

### 6. File Monitoring Sidecar (test_file_monitor.bats)

Tests for file monitoring feature:
- `build_file_monitor_script()` - Pod file monitor script
- `build_node_file_monitor_script()` - Node file monitor script
- Base64 decoding and command execution
- Placeholder substitution
- File size formatting (B suffix)
- Multi-line command handling
- Sidecar integration with debug pods
- Log downloading during cleanup

### 7. Integration Tests (test_integration.bats)

End-to-end workflow tests:
- Pod debugging with label selector
- Node debugging with label selector
- File download workflows
- Mixed mode (pods + nodes)
- Kill switch with absolute/relative thresholds
- Verbose mode
- Custom images and placeholders
- Error handling and validation
- Argument parsing
- Output directory structure
- Namespace handling
- CRI runtime detection

## 🎯 Mock System

### Mock kubectl Command

The test suite includes a sophisticated mock kubectl command that:
- Simulates different kubectl operations (get, apply, delete, exec, logs)
- Returns appropriate mock data for pod and node queries
- Supports spy mode to track all kubectl calls
- Configurable behavior via environment variables:
  - `KUBECTL_MOCK_MODE` - success, fail, timeout, custom
  - `KUBECTL_MOCK_OUTPUT` - Custom output
  - `KUBECTL_MOCK_EXIT_CODE` - Custom exit code
  - `KUBECTL_SPY_FILE` - Log all calls to file

### Mock Modes

```bash
# Success mode (default)
KUBECTL_MOCK_MODE="success" bats test/test_pod_operations.bats

# Failure mode
KUBECTL_MOCK_MODE="fail" bats test/test_pod_operations.bats

# Custom output
KUBECTL_MOCK_OUTPUT="custom data" bats test/...

# Spy mode - track all calls
KUBECTL_SPY_FILE="/tmp/spy.log" bats test/...
```

## 📝 Writing New Tests

### Test Template

```bash
#!/usr/bin/env bats

load test_helper/common

setup() {
  common_setup

  # Source script
  main() { :; }
  source "$KUBE_DUMP_SCRIPT"

  # Setup environment
  export KUBE_CLI="${MOCK_DIR}/kubectl"
  export OUTPUT_DIR="${BATS_TMPDIR}/output"
  mkdir -p "$OUTPUT_DIR"
}

teardown() {
  common_teardown
}

@test "my test: description" {
  run my_function "arg1" "arg2"
  assert_success
  assert_output "expected output"
}
```

### Available Assertions

From bats-assert:
- `assert_success` / `assert_failure`
- `assert_output` / `refute_output`
- `assert_line` / `refute_line`
- `assert_equal` / `refute_equal`

From bats-file:
- `assert_file_exists` / `assert_dir_exists`
- `assert_file_contains`

### Helper Functions

From common.bash:
- `mock_kubectl_success` - Create successful kubectl mock
- `mock_kubectl_fail` - Create failing kubectl mock
- `setup_kubectl_spy` - Track kubectl calls
- `mock_kubectl_output` - Return custom output

## 🐛 Debugging Tests

### Run Single Test

```bash
bats --filter "hash_input: generates hash" test/test_utility_functions.bats
```

### Verbose Output

```bash
bats --verbose-run test/test_pod_operations.bats
```

### Debug with Print Statements

```bash
@test "debug example" {
  echo "DEBUG: Variable value: $SOME_VAR" >&3
  run my_function
  echo "DEBUG: Output: $output" >&3
  assert_success
}
```

## 🎬 CI/CD Integration

### GitHub Actions

This repository includes automated testing via GitHub Actions. See `.github/workflows/tests.yml` for the complete workflow.

**The test suite runs automatically on:**
- Push to `master` or `main` branches
- Pull requests to `master` or `main` branches
- Manual workflow dispatch

**Features:**
- ✅ Automatic dependency installation
- ✅ Parallel test execution
- ✅ Coverage analysis and reporting
- ✅ Test artifacts for debugging
- ✅ PR comments with test results

### Workflow File

See [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) for the complete configuration.

## 📈 Coverage Goals

- ✅ **Target: 100% function coverage**
- ✅ All utility functions tested
- ✅ All pod operations tested
- ✅ All node operations tested
- ✅ All file operations tested
- ✅ All kill switch functions tested
- ✅ All file monitor functions tested
- ✅ Integration workflows tested

## 🔧 Troubleshooting

### Tests Fail on macOS

Some tests may behave differently on macOS vs Linux due to:
- Different `ls` output format
- Different `md5sum` vs `md5` commands
- Path differences

The test suite handles these with fallbacks.

### Mock kubectl Not Found

Ensure mocks directory is in PATH:
```bash
export PATH="${PWD}/test/mocks:${PATH}"
```

### Permission Denied

Make scripts executable:
```bash
chmod +x test/run_tests.sh test/analyze_coverage.sh test/mocks/kubectl
```

## 📚 Resources

- [Bats Core Documentation](https://bats-core.readthedocs.io/)
- [Bats-support Library](https://github.com/bats-core/bats-support)
- [Bats-assert Library](https://github.com/bats-core/bats-assert)
- [Bats-file Library](https://github.com/bats-core/bats-file)

## 🤝 Contributing

To add new tests:

1. Identify untested functions: `./test/analyze_coverage.sh`
2. Create test cases in appropriate `.bats` file
3. Run tests: `./test/run_tests.sh`
4. Verify coverage: `./test/analyze_coverage.sh`
5. Submit PR with test additions

## 📄 License

Same as kube-dump.sh project.
