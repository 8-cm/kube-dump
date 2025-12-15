# Kube-Dump Architecture & Function Call Flow

Complete technical architecture documentation for kube-dump, including function call hierarchy, execution flow, and component interactions.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Complete Function Call Hierarchy](#complete-function-call-hierarchy)
3. [Main Execution Flow](#main-execution-flow)
4. [Function Categories](#function-categories)
5. [Execution Modes](#execution-modes)
6. [Component Interactions](#component-interactions)

---

## Architecture Overview

kube-dump is a Kubernetes debugging tool that creates temporary debug pods to execute commands and collect files from running pods and nodes. The architecture is built on a modular function-based design with clear separation of concerns.

**Core Principles:**
- **Modular Design**: Each function has a single responsibility
- **Function Composition**: Higher-level functions orchestrate lower-level utilities
- **Error Handling**: Comprehensive validation at each level
- **Resource Management**: Proper cleanup and lifecycle management

---

## Complete Function Call Hierarchy

```
┌─────────────────────────────────────────────────────────────────────┐
│                            MAIN ENTRY POINT                         │
│                          main() function                            │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────┐       ┌──────────┐       ┌─────────┐
   │ INIT    │       │ VALIDATE │       │ SETUP   │
   └────┬────┘       └────┬─────┘       └────┬────┘
        │                 │                   │
        ├─initialize_     ├─validate_        ├─setup_
        │ variables()     │ arguments()       │ output_
        │                 │                  │ directories()
        ├─detect_        ├─validate_        │
        │ kube_cli()      │ all_            ├─setup_
        │                 │ requirements()   │ debug_
        └─parse_         │                  │ logging()
          arguments()     ├─validate_        │
                          │ variable()       └─show_
                          │                   configuration()
                          └─validate_
                            option_value()

        ┌──────────────────────────────────────────────────────┐
        │        MAIN EXECUTION: Determine Mode                │
        │   (pod / node / discovery)                           │
        └──────────────────┬───────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┬────────────────┐
        │                  │                  │                │
        ▼                  ▼                  ▼                ▼
   ┌─────────┐        ┌──────────┐      ┌─────────┐      ┌──────────┐
   │POD MODE │        │NODE MODE │      │DISCOVERY│      │KILL SWITCH
   └────┬────┘        └────┬─────┘      │  MODE   │      │MONITORING
        │                  │             └────┬────┘      └────┬─────┘
        │                  │                   │               │
        ├─select_         ├─select_           ├─create_       ├─detect_
        │ target_pods()   │ target_nodes()    │ file_          │ kubelet_
        │                 │                   │ discovery_     │ eviction_
        ├─prepare_       ├─create_           │ pods()         │ threshold()
        │ target_        │ node_              │                │
        │ pods()          │ debug_pods()      ├─wait_for_     ├─get_
        │                 │                   │ discovery_     │ effective_
        └─create_        └─build_            │ pods_ready()   │ cri_socket()
          debug_pods_      node_              │                │
          for_targets()    debug_script()     └─handle_        ├─create_
                           │                   file_downloads()│ kill_
                           └─wait_for_                         │ switch_
                             debug_pods_                       │ monitor_
                             ready()                           │ pods()
                                                               │
                                                               └─monitor_
                                                                 kill_
                                                                 switches()

        ┌──────────────────────────────────────────────────────────┐
        │                   CLEANUP PHASE                          │
        └──────────────────┬───────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌────────────────────┐
   │cleanup_debug_   │ │cleanup_discovery_│ │cleanup_kill_switch_│
   │pods()           │ │pods()            │ │monitor_pods()      │
   └─────────────────┘ └──────────────────┘ └────────────────────┘
```

---

## Main Execution Flow

### Phase 1: Initialization & Setup (Pre-Execution)
```
initialize_variables() ──→ Sets defaults for labels, modes, timeouts
detect_kube_cli()      ──→ Detects kubectl or oc
parse_arguments()      ──→ Parses CLI arguments
validate_arguments()   ──→ Validates argument syntax & semantics
validate_all_requirements() ──→ Checks prerequisites
setup_output_directories() ──→ Creates log/output directories
setup_debug_logging()  ──→ Configures logging if -v specified
show_configuration()   ──→ Displays summary and waits for confirmation
```

### Phase 2: Mode-Specific Execution
#### POD Debugging Mode
```
find_pods_by_label()              ──→ Query pods by label
select_target_pods()              ──→ Interactive pod selection
prepare_target_pods()             ──→ Validate pods are running
create_debug_pods_for_targets()   ──→ Create debug pod for each target
  ├─ generate_command_container() ──→ Build container spec
  ├─ generate_file_monitor_container() ──→ Build monitor spec (if file ops)
  └─ create_single_debug_pod()    ──→ Create individual pod via kubectl
wait_for_debug_pods_ready()       ──→ Wait for all pods to be ready
```

#### NODE Debugging Mode
```
select_target_nodes()         ──→ Interactive node selection
create_node_debug_pods()      ──→ Create debug pod for each node
  ├─ detect_cri_socket_from_node() ──→ Detect container runtime
  ├─ build_node_debug_script()     ──→ Build node-level debug script
  └─ create_single_node_debug_pod() ──→ Create individual node debug pod
wait_for_debug_pods_ready()   ──→ Wait for all pods to be ready
```

#### File Discovery Mode
```
create_file_discovery_pods()      ──→ Create discovery pods
  ├─ build_file_monitor_script()  ──→ Build file discovery script
  ├─ create_single_debug_pod()    ──→ Create discovery pod
  └─ build_discovery_script()     ──→ Generate discovery command
wait_for_discovery_pods_ready()   ──→ Wait for pods to complete
handle_file_downloads()           ──→ Copy files to local system
  └─ get_pod_log_file()           ──→ Get file from pod
cleanup_discovery_pods()          ──→ Remove discovery pods
```

### Phase 3: Kill Switch Monitoring (Optional)
```
detect_kubelet_eviction_threshold() ──→ Read eviction thresholds
create_kill_switch_monitor_pods()   ──→ Create monitor pod
  └─ build_kill_switch_monitor_script() ──→ Build monitoring script
monitor_kill_switches()              ──→ Poll disk usage & cleanup if needed
cleanup_kill_switch_monitor_pods()   ──→ Remove monitor pods
```

### Phase 4: Cleanup
```
cleanup_debug_pods()            ──→ Remove all debug pods
cleanup_discovery_pods()        ──→ Remove discovery pods
cleanup_kill_switch_monitor_pods() ──→ Remove monitor pods
```

---

## Function Categories

### Core Orchestration Functions
- **main()** - Main entry point, orchestrates execution flow
- **show_configuration()** - Display summary and wait for confirmation

### Initialization & Configuration
- **initialize_variables()** - Set default values and variables
- **detect_kube_cli()** - Detect kubectl or oc
- **parse_arguments()** - Parse command-line arguments
- **setup_output_directories()** - Create output and log directories
- **setup_debug_logging()** - Configure debug logging

### Validation Functions
- **validate_arguments()** - Validate argument combinations
- **validate_all_requirements()** - Verify all prerequisites
- **validate_option_value()** - Validate specific option values
- **validate_variable()** - Validate variable values

### Target Selection Functions
- **find_pods_by_label()** - Query pods by label selector
- **select_target_pods()** - Interactive pod selection
- **prepare_target_pods()** - Verify pods are running
- **select_target_nodes()** - Interactive node selection

### Debug Pod Creation Functions
- **create_debug_pods_for_targets()** - Create debug pods for pod targets
- **create_single_debug_pod()** - Create individual debug pod
- **create_node_debug_pods()** - Create debug pods for node targets
- **create_single_node_debug_pod()** - Create individual node debug pod
- **create_discovery_pod()** - Create file discovery pod
- **create_file_discovery_pods()** - Create multiple discovery pods

### Pod Building/Generation Functions
- **generate_command_container()** - Generate container spec for command execution
- **generate_file_monitor_container()** - Generate container spec for file monitoring
- **generate_exec_command()** - Generate kubectl exec command
- **build_debug_script()** - Build debug script for debug pod
- **build_node_debug_script()** - Build debug script for node debug pod
- **build_discovery_script()** - Build discovery script
- **build_file_monitor_script()** - Build file monitoring script
- **build_node_discovery_script()** - Build node discovery script
- **build_node_file_monitor_script()** - Build node file monitoring script
- **build_single_discovery_script()** - Build single pod discovery script
- **build_single_node_discovery_script()** - Build single node discovery script

### Kubernetes Interaction Functions
- **run_kube_cmd()** - Execute kubectl/oc command with error handling
- **wait_for_debug_pods_ready()** - Poll pod status until ready
- **wait_for_discovery_pods_ready()** - Poll discovery pods until ready
- **detect_cri_socket_from_node()** - Detect container runtime socket
- **get_effective_cri_socket()** - Get CRI socket path
- **configure_crictl_socket()** - Configure crictl socket

### Kill Switch Functions
- **detect_kubelet_eviction_threshold()** - Read kubelet eviction thresholds
- **create_kill_switch_monitor_pods()** - Create monitoring pods
- **create_kill_switch_monitor_pod()** - Create single monitor pod
- **monitor_kill_switches()** - Monitor disk usage and cleanup
- **cleanup_kill_switch_monitor_pods()** - Remove monitor pods

### File Operations Functions
- **create_file_discovery_pods()** - Create discovery pods for files
- **handle_file_downloads()** - Download files from pods
- **get_pod_log_file()** - Retrieve individual file from pod

### Cleanup Functions
- **cleanup_debug_pods()** - Remove debug pods
- **cleanup_discovery_pods()** - Remove discovery pods
- **cleanup_kill_switch_monitor_pods()** - Remove monitor pods

### Utility Functions
- **format_message()** - Format console output
- **format_message_stderr()** - Format error output
- **get_pod_log_file()** - Get pod log file path
- **truncate_name_with_hash()** - Truncate long names with hash
- **truncate_label_value_with_hash()** - Truncate long label values
- **parse_size_to_bytes()** - Convert size string to bytes
- **format_bc_result()** - Format bc calculator results
- **get_import_file_for_command()** - Get import file for command
- **get_node_import_file_for_command()** - Get import file for node command
- **usage()** - Display usage information

---

## Execution Modes

### 1. POD Debugging Mode (`-l label`)
**Function Call Chain:**
```
main()
├─ find_pods_by_label()
├─ select_target_pods()
├─ prepare_target_pods()
├─ create_debug_pods_for_targets()
│  ├─ generate_command_container()
│  ├─ generate_file_monitor_container()
│  └─ create_single_debug_pod()
├─ wait_for_debug_pods_ready()
└─ cleanup_debug_pods()
```

### 2. NODE Debugging Mode (`-L label`)
**Function Call Chain:**
```
main()
├─ select_target_nodes()
├─ create_node_debug_pods()
│  ├─ detect_cri_socket_from_node()
│  ├─ build_node_debug_script()
│  └─ create_single_node_debug_pod()
├─ wait_for_debug_pods_ready()
└─ cleanup_debug_pods()
```

### 3. File Discovery Mode (`-s` / `-S`)
**Function Call Chain:**
```
main()
├─ create_file_discovery_pods()
│  ├─ build_file_monitor_script()
│  ├─ create_single_debug_pod()
│  └─ build_discovery_script()
├─ wait_for_discovery_pods_ready()
├─ handle_file_downloads()
│  └─ get_pod_log_file()
└─ cleanup_discovery_pods()
```

### 4. Kill Switch Monitoring (Optional `--kill-switch-*`)
**Function Call Chain:**
```
main()
├─ detect_kubelet_eviction_threshold()
├─ create_kill_switch_monitor_pods()
│  └─ build_kill_switch_monitor_script()
├─ monitor_kill_switches()
└─ cleanup_kill_switch_monitor_pods()
```

---

## Component Interactions

### Data Flow

```
User Input
    ↓
parse_arguments() → validate_arguments()
    ↓
Execution Mode Determination
    ↓
Target Selection (pods/nodes)
    ↓
Debug Pod Creation
    ├─ generate_*_container() → Generate container specs
    ├─ build_*_script() → Generate execution scripts
    └─ run_kube_cmd() → Create pods via kubectl
    ↓
Wait for Pod Readiness
    ├─ wait_for_debug_pods_ready()
    └─ wait_for_discovery_pods_ready()
    ↓
Execution/Monitoring
    ├─ User interaction (if interactive)
    └─ monitor_kill_switches() (if enabled)
    ↓
File Operations (if applicable)
    ├─ handle_file_downloads()
    └─ get_pod_log_file()
    ↓
Cleanup
    ├─ cleanup_debug_pods()
    ├─ cleanup_discovery_pods()
    └─ cleanup_kill_switch_monitor_pods()
```

### Function Dependencies

**High-Level Dependencies:**
```
main()
├─ Depends on: parse_arguments, validate_*, initialize_variables
├─ Depends on: detect_kube_cli, setup_*
├─ Calls: (mode-specific orchestration)
└─ Calls: cleanup_* functions

create_debug_pods_for_targets()
├─ Depends on: generate_*_container, create_single_debug_pod
├─ Calls: run_kube_cmd indirectly
└─ Calls: wait_for_debug_pods_ready

create_single_debug_pod()
├─ Depends on: run_kube_cmd
├─ Depends on: generate_exec_command
└─ Calls: Kubernetes API via kubectl/oc

wait_for_debug_pods_ready()
├─ Depends on: run_kube_cmd
└─ Polls: kubectl get pods until ready

handle_file_downloads()
├─ Depends on: get_pod_log_file
├─ Depends on: run_kube_cmd
└─ Copies: files from pod to local filesystem
```

---

## Technical Characteristics

### Error Handling Strategy
- **Pre-execution validation**: Check all requirements before creating pods
- **Runtime validation**: Verify pod readiness before proceeding
- **Cleanup on failure**: Ensure pods are cleaned up even if operations fail

### Resource Management
- **Pod Lifecycle Tracking**: Arrays track created pods for reliable cleanup
- **Timeout Handling**: Configurable timeouts for pod readiness
- **Kill Switch Protection**: Automatic cleanup when disk usage exceeds thresholds

### CRI Socket Detection
```
detect_cri_socket_from_node()
├─ SSH to node via debug pod
├─ Check /run/containerd/containerd.sock
├─ Check /var/run/crio/crio.sock
├─ Check /var/run/docker.sock
└─ Return detected socket path

configure_crictl_socket()
├─ Export CONTAINER_RUNTIME_ENDPOINT
└─ Use for crictl commands
```

### Kill Switch Monitoring Algorithm
```
detect_kubelet_eviction_threshold()
├─ Parse kubelet config
├─ Get eviction hard/soft thresholds
└─ Return memory/disk limits

monitor_kill_switches()
├─ Loop: Check disk usage
│  ├─ Calculate free space
│  ├─ Compare to threshold
│  ├─ If exceeded: cleanup_* pods
│  └─ Sleep and repeat
└─ Exit: When user terminates or threshold hit
```

---

## Summary

The kube-dump architecture implements a modular, function-based design with:
- **62 functions** organized into 10 functional categories
- **Clear separation of concerns** between orchestration, validation, and execution
- **Multiple execution modes** (pod, node, discovery) with shared utilities
- **Comprehensive error handling** and resource cleanup
- **Flexible CRI support** with runtime detection
- **Automatic protection** via kill switch monitoring

All functions work together to provide a safe, efficient debugging experience for Kubernetes clusters.
