# Test Coverage Report

Complete test suite coverage analysis for kube-dump.sh.

---

<!-- TEST-COVERAGE-START -->
## 🧪 Test Suite Status

**Overall Coverage:** ✅ 100% (51/51 functions)
**Test Cases:** 280+ tests across 8 test files
**Framework:** [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core)
**Last Updated:** Automated
**CI/CD:** [GitHub Actions Workflow](../.github/workflows/tests.yml)

### Coverage Summary

| Metric | Value |
|--------|-------|
| **Total Functions** | 51 |
| **Tested Functions** | 51 |
| **Untested Functions** | 0 |
| **Coverage Percentage** | 100.0% |
| **Test Files** | 8 |
| **Test Cases** | 280+ |

### Test Suite Breakdown

| Test File | Functions Tested | Test Cases | Description |
|-----------|-----------------|------------|-------------|
| `test_utility_functions.bats` | 10 | 30+ | Utility and validation functions |
| `test_pod_operations.bats` | 9 | 35+ | Pod debugging operations |
| `test_node_operations.bats` | 8 | 30+ | Node debugging operations |
| `test_file_operations.bats` | 8 | 30+ | File discovery and download |
| `test_kill_switch.bats` | 7 | 35+ | Kill switch monitoring |
| `test_file_monitor.bats` | 2 | 40+ | File monitoring sidecar |
| `test_missing_functions.bats` | 33 | 70+ | All remaining functions |
| `test_integration.bats` | - | 40+ | End-to-end workflows |

---

## 📊 Detailed Function Coverage

### Utility Functions (10/10 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `hash_input` | ✅ | test_utility_functions.bats | Hash generation with fallback |
| `format_message` | ✅ | test_utility_functions.bats | Output formatting |
| `format_message_stderr` | ✅ | test_utility_functions.bats | Error output formatting |
| `detect_kube_cli` | ✅ | test_utility_functions.bats | kubectl/oc detection |
| `setup_output_directories` | ✅ | test_utility_functions.bats | Directory structure creation |
| `run_kube_cmd` | ✅ | test_utility_functions.bats | Kubernetes command execution |
| `usage` | ✅ | test_missing_functions.bats | Help text display |
| `initialize_variables` | ✅ | test_missing_functions.bats | Variable initialization |
| `validate_all_requirements` | ✅ | test_missing_functions.bats | Prerequisite checking |
| `show_configuration` | ✅ | test_missing_functions.bats | Configuration display |

### Pod Operations (9/9 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `find_pods_by_label` | ✅ | test_missing_functions.bats | Pod selection by label |
| `select_target_pods` | ✅ | test_missing_functions.bats | Target pod selection |
| `create_single_debug_pod` | ✅ | test_pod_operations.bats | Debug pod creation |
| `create_debug_pods_for_targets` | ✅ | test_missing_functions.bats | Multi-pod debug creation |
| `wait_for_debug_pods_ready` | ✅ | test_missing_functions.bats | Pod readiness waiting |
| `cleanup_debug_pods` | ✅ | test_pod_operations.bats | Debug pod cleanup |
| `prepare_target_pods` | ✅ | test_missing_functions.bats | Pod preparation |
| `build_debug_script` | ✅ | test_missing_functions.bats | Pod debug script generation |
| `generate_exec_command` | ✅ | test_missing_functions.bats | Execution command generation |

### Node Operations (8/8 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `select_target_nodes` | ✅ | test_missing_functions.bats | Node selection |
| `create_single_node_debug_pod` | ✅ | test_node_operations.bats | Node debug pod creation |
| `create_node_debug_pods` | ✅ | test_missing_functions.bats | Multi-node debug creation |
| `build_node_debug_script` | ✅ | test_node_operations.bats | Node debug script generation |
| `detect_kubelet_eviction_threshold` | ✅ | test_missing_functions.bats | Kubelet threshold detection |
| `build_node_file_monitor_script` | ✅ | test_node_operations.bats | Node file monitor script |
| `configure_crictl_socket` | ✅ | test_missing_functions.bats | CRI socket configuration |
| `get_effective_cri_socket` | ✅ | test_missing_functions.bats | CRI socket detection |

### File Operations (8/8 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `create_discovery_pod` | ✅ | test_file_operations.bats | File discovery pod creation |
| `create_node_discovery_pod` | ✅ | test_file_operations.bats | Node discovery pod creation |
| `build_discovery_script` | ✅ | test_missing_functions.bats | Discovery script generation |
| `build_node_discovery_script` | ✅ | test_missing_functions.bats | Node discovery script generation |
| `create_file_discovery_pods` | ✅ | test_missing_functions.bats | Multi-file discovery creation |
| `wait_for_discovery_pods_ready` | ✅ | test_missing_functions.bats | Discovery pod readiness |
| `cleanup_discovery_pods` | ✅ | test_file_operations.bats | Discovery pod cleanup |
| `handle_file_downloads` | ✅ | test_file_operations.bats | File download orchestration |

### Kill Switch Functions (7/7 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `build_kill_switch_monitor_script` | ✅ | test_kill_switch.bats | Monitor script generation |
| `create_kill_switch_monitor_pod` | ✅ | test_missing_functions.bats | Monitor pod creation |
| `create_kill_switch_monitor_pods` | ✅ | test_missing_functions.bats | Multi-monitor creation |
| `cleanup_kill_switch_monitor_pods` | ✅ | test_missing_functions.bats | Monitor cleanup |
| `monitor_kill_switches` | ✅ | test_missing_functions.bats | Kill switch monitoring |
| `parse_size_to_bytes` | ✅ | test_missing_functions.bats | Size parsing |
| `format_bc_result` | ✅ | test_missing_functions.bats | BC result formatting |

### File Monitoring (2/2 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `build_file_monitor_script` | ✅ | test_file_monitor.bats | Pod file monitor script |
| `build_node_file_monitor_script` | ✅ | test_file_monitor.bats | Node file monitor script |

### Validation & Helpers (7/7 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `parse_arguments` | ✅ | test_missing_functions.bats | Argument parsing |
| `validate_arguments` | ✅ | test_missing_functions.bats | Argument validation |
| `validate_option_value` | ✅ | test_missing_functions.bats | Option value validation |
| `validate_variable` | ✅ | test_missing_functions.bats | Variable validation |
| `truncate_name_with_hash` | ✅ | test_missing_functions.bats | Name truncation |
| `truncate_label_value_with_hash` | ✅ | test_missing_functions.bats | Label value truncation |
| `get_pod_log_file` | ✅ | test_missing_functions.bats | Log file path generation |

### Main & Setup (2/2 - 100%)

| Function | Status | Test File | Description |
|----------|--------|-----------|-------------|
| `main` | ✅ | test_integration.bats | Main entry point |
| `setup_debug_logging` | ✅ | test_missing_functions.bats | Debug logging setup |

---

## 🎯 Test Infrastructure

### Bats Framework

The test suite uses [Bats](https://github.com/bats-core/bats-core) - Bash Automated Testing System, with the following libraries:

- **bats-core** - Core testing framework
- **bats-support** - Additional helper functions
- **bats-assert** - Assertion library for clearer test expectations
- **bats-file** - File system assertions

### Mock System

A sophisticated mock kubectl system provides:

- Configurable behavior modes (success, fail, timeout, custom)
- Spy mode to track all kubectl calls
- Realistic output for pod and node queries
- Support for multiple simultaneous operations

### Test Helpers

Common test helpers (`test/test_helper/common.bash`) provide:

- Isolated test environments with automatic cleanup
- Mock kubectl/oc command setup
- Temporary directory management
- Consistent setup and teardown procedures

---

## 🚀 Running Tests

### Locally

```bash
# Install dependencies (one-time)
cd test
git clone --depth 1 https://github.com/bats-core/bats-core.git
git clone --depth 1 https://github.com/bats-core/bats-support.git
git clone --depth 1 https://github.com/bats-core/bats-assert.git
git clone --depth 1 https://github.com/bats-core/bats-file.git

# Run all tests
./test/run_tests.sh

# Run specific test file
./test/bats-core/bin/bats test/test_pod_operations.bats

# Run with filter
FILTER="hash_input" ./test/run_tests.sh

# Check coverage
./test/analyze_coverage.sh
```

### CI/CD (GitHub Actions)

Tests run automatically on:
- Push to `master` or `main` branches
- Pull requests to `master` or `main` branches
- Manual workflow dispatch

See [`.github/workflows/tests.yml`](../.github/workflows/tests.yml) for the complete workflow configuration.

---

## 📈 Coverage History

| Date | Coverage | Functions | Test Cases | Notes |
|------|----------|-----------|------------|-------|
| 2025-11-23 | 100.0% | 51/51 | 280+ | Initial test suite with full coverage |

---

## 🛠️ Adding New Tests

When adding new functions to kube-dump.sh:

1. **Identify the function category** (utility, pod ops, node ops, etc.)
2. **Add tests to appropriate file** (or create new file if needed)
3. **Follow naming convention**: `@test "function_name: test description"`
4. **Use assertions**: `assert_success`, `assert_output`, etc.
5. **Run coverage analysis**: `./test/analyze_coverage.sh`

### Test Template

```bash
@test "my_function: does something specific" {
  # Setup
  export SOME_VAR="value"

  # Execute
  run my_function "arg1" "arg2"

  # Assert
  assert_success
  assert_output "expected output"
}
```

---

## 📚 Related Documentation

- [Test Suite README](../test/README.md) - Detailed test documentation
- [GitHub Actions Workflow](../.github/workflows/tests.yml) - CI/CD configuration
- [Bats Documentation](https://bats-core.readthedocs.io/) - Framework reference

---

*This coverage report is automatically updated by the [Test Suite workflow](../.github/workflows/tests.yml)*

<!-- TEST-COVERAGE-END -->
