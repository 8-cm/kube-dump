# Kube-Dump Architecture

Complete technical architecture diagram showing all function interactions between the local script, Kubernetes API, target pods, and target nodes.

## Complete Function Interaction Diagram

```mermaid
sequenceDiagram
    autonumber
    
    participant User as User (Terminal)
    participant Script as kube-dump.sh (Local)
    participant K8sAPI as Kubernetes API
    participant DebugPod as Debug Pod
    participant TargetPod as Target Pod
    participant TargetNode as Target Node
    participant KillSwitch as Kill Switch Monitor
    participant DiscoveryPod as Discovery Pod
    participant LocalFS as Local Filesystem

    %% ============================================================
    %% PHASE 0: INITIALIZATION
    %% ============================================================
    rect rgb(240, 248, 255)
        Note over User,LocalFS: PHASE 0: Initialization & Validation
        
        User->>Script: ./kube-dump.sh [args]
        activate Script
        
        Script->>Script: main()
        Script->>Script: initialize_variables()
        Note right of Script: Returns: void<br/>Sets: POD_LABELS=["dumpme=yes"]<br/>EXECUTION_MODE="pod"<br/>CRI_RUNTIME="containerd"<br/>DEBUG_IMAGE="nicolaka/netshoot"<br/>Arrays: DEBUG_POD_NAMES=[]<br/>TARGET_PODS=[], TARGET_NODES=[]
        
        Script->>Script: detect_kube_cli()
        Note right of Script: Checks: command -v oc<br/>Checks: command -v kubectl<br/>Returns: void<br/>Sets: KUBE_CLI="oc"|"kubectl"<br/>Exits 1 if neither found
        
        Script->>Script: parse_arguments($@)
        Note right of Script: Parses: -l, -L, -e, -E, -s, -S,<br/>-n, -o, -f, --kill-switch-*,<br/>--cri, --image, --verbose, etc.<br/>Returns: void<br/>Sets: All config variables<br/>Calls: validate_option_value() for each arg<br/>Calls: usage() if -h/--help
        
        alt No arguments provided
            Script->>Script: usage()
            Script-->>User: Display help text
            Note right of Script: Returns: exit 0
        end
        
        Script->>Script: validate_arguments()
        Note right of Script: Validates: Label selectors syntax<br/>Validates: Command combinations<br/>Validates: File paths exist<br/>Validates: Threshold formats<br/>Returns: void or exit 1<br/>Sets: EXECUTION_MODE="pod"|"node"|"mixed"
        
        Script->>Script: show_configuration()
        Note right of Script: Displays: All settings summary<br/>Waits: User confirmation (Enter)<br/>Returns: void
        
        alt OUTPUT_DIR specified
            Script->>LocalFS: mkdir -p $OUTPUT_DIR
            Script->>Script: setup_output_directories()
            Note right of Script: Creates: downloads/, debug/,<br/>killswitch-logs/, discovery-logs/<br/>Returns: 0|1
            LocalFS-->>Script: Directory created
            
            Script->>LocalFS: Create kube-dump-{date}_{epoch}.log
            LocalFS-->>Script: Log file initialized
        end
        
        alt VERBOSE enabled
            Script->>Script: setup_debug_logging()
            Note right of Script: Creates: DEBUG_LOG_DIR<br/>Sets: KUBE_CLI with -v=10<br/>Returns: 0|1
        end
        
        Script->>Script: validate_all_requirements()
        Script->>K8sAPI: $KUBE_CLI cluster-info
        K8sAPI-->>Script: Cluster info response
        Note right of Script: Validates: Cluster connectivity<br/>Validates: RBAC permissions<br/>Validates: Namespace exists<br/>Returns: void or exit 1
    end

    %% ============================================================
    %% PHASE 1: TARGET SELECTION (POD MODE)
    %% ============================================================
    rect rgb(255, 248, 240)
        Note over User,LocalFS: PHASE 1: Target Selection & Debug Pod Creation
        
        alt EXECUTION_MODE == "pod"
            Script->>Script: select_target_pods()
            
            loop For each label in POD_LABELS[]
                Script->>Script: find_pods_by_label(label)
                Script->>K8sAPI: $KUBE_CLI get pods -l {label} -o json --all-namespaces
                K8sAPI-->>Script: JSON: [{name, namespace, nodeName, containers[]}]
                Note right of Script: Returns: void<br/>Appends to: POD_NAMES[]<br/>Format: "name:namespace:node"
            end
            
            Note right of Script: Returns: 0|1<br/>User selects pods interactively<br/>Sets: POD_NAMES[] filtered
            
            Script->>Script: prepare_target_pods()
            
            loop For each pod in POD_NAMES[]
                Script->>K8sAPI: $KUBE_CLI get pod {name} -n {ns} -o json
                K8sAPI-->>Script: JSON: {status.phase, containers[0].name, spec.nodeName}
                
                Script->>Script: truncate_name_with_hash(pod_name)
                Note right of Script: Input: Original name<br/>Returns: Truncated name (≤63 chars)<br/>Uses: MD5 hash suffix if truncated
                
                Script->>Script: truncate_label_value_with_hash(label_value)
                Note right of Script: Input: Label value<br/>Returns: Valid K8s label (≤63 chars)
            end
            
            Note right of Script: Returns: 0|1<br/>Sets: TARGET_PODS[]<br/>Format: "pod:container:node:namespace"
            
            Script->>Script: create_debug_pods_for_targets()
            
            loop For each target in TARGET_PODS[]
                Script->>Script: generate_command_container(index, target_name)
                Note right of Script: Generates: Container YAML spec<br/>Includes: nsenter command wrapper<br/>Includes: Resource limits if set<br/>Returns: YAML string
                
                Script->>Script: build_debug_script(pod_name, container, node)
                Note right of Script: Generates: Entrypoint bash script<br/>Includes: CRI socket detection<br/>Includes: PID discovery via crictl<br/>Includes: nsenter execution<br/>Returns: Base64-encoded script
                
                alt File monitors configured (-s)
                    loop For each SELECT_TO_DOWNLOAD_COMMANDS[]
                        Script->>Script: generate_file_monitor_container(index)
                        Script->>Script: build_file_monitor_script(pod, container, node, target, index)
                        Note right of Script: Generates: Sidecar container spec<br/>Monitors: File list command output<br/>Returns: YAML string
                    end
                end
                
                Script->>Script: create_single_debug_pod(pod_name, node, yaml_spec)
                Script->>K8sAPI: $KUBE_CLI apply -f - <<< {pod_yaml}
                K8sAPI-->>Script: pod/{debug-pod-name} created
                
                Note right of Script: Sets: DEBUG_POD_NAMES[] += debug_pod<br/>Sets: DEBUG_POD_NAMES_META[] += metadata
            end
            
            Note right of Script: Returns: 0|1<br/>Updates: DEBUG_POD_NAMES[]
        end
    end

    %% ============================================================
    %% PHASE 1: TARGET SELECTION (NODE MODE)
    %% ============================================================
    rect rgb(248, 255, 240)
        Note over User,LocalFS: PHASE 1 (continued): Node Target Selection
        
        alt EXECUTION_MODE == "node" or "mixed"
            Script->>Script: select_target_nodes()
            
            loop For each label in NODE_LABELS[]
                Script->>K8sAPI: $KUBE_CLI get nodes -l {label} -o json
                K8sAPI-->>Script: JSON: [{metadata.name, status.conditions}]
            end
            
            Note right of Script: Returns: 0|1<br/>User selects nodes interactively<br/>Sets: TARGET_NODES[]
            
            Script->>Script: create_node_debug_pods()
            
            loop For each node in TARGET_NODES[]
                Script->>Script: detect_cri_socket_from_node(node_name)
                Script->>K8sAPI: $KUBE_CLI debug node/{node} --image={image}
                activate TargetNode
                K8sAPI->>TargetNode: Create ephemeral debug container
                TargetNode-->>K8sAPI: Check socket paths
                K8sAPI-->>Script: CRI socket path detected
                deactivate TargetNode
                Note right of Script: Checks: /run/containerd/containerd.sock<br/>Checks: /var/run/crio/crio.sock<br/>Checks: /var/run/docker.sock<br/>Returns: Socket path string
                
                Script->>Script: build_node_debug_script(node_name)
                Note right of Script: Generates: Node debug bash script<br/>Uses: chroot /host<br/>Includes: CRI socket config<br/>Returns: Base64-encoded script
                
                Script->>Script: create_single_node_debug_pod(node, yaml_spec)
                Script->>K8sAPI: $KUBE_CLI apply -f - <<< {node_debug_pod_yaml}
                K8sAPI-->>Script: pod/{node-debug-pod} created
                
                Note right of Script: Pod spec includes:<br/>hostNetwork: true<br/>hostPID: true<br/>privileged: true<br/>nodeSelector: {node}
            end
            
            Note right of Script: Returns: 0|1<br/>Updates: DEBUG_POD_NAMES[]
        end
    end

    %% ============================================================
    %% PHASE 1: WAIT FOR PODS READY
    %% ============================================================
    rect rgb(255, 255, 240)
        Note over User,LocalFS: PHASE 1 (continued): Wait for Debug Pods Ready
        
        Script->>Script: wait_for_debug_pods_ready()
        
        loop Until all pods ready or timeout
            loop For each pod in DEBUG_POD_NAMES[]
                Script->>Script: run_kube_cmd(get pod {name} -o jsonpath={status})
                Script->>K8sAPI: $KUBE_CLI get pod {name} -n {ns} -o jsonpath='{.status.phase}'
                K8sAPI-->>Script: "Pending"|"Running"|"Succeeded"|"Failed"
                
                alt Pod status == "Running"
                    Script->>K8sAPI: $KUBE_CLI get pod {name} -o jsonpath='{.status.containerStatuses}'
                    K8sAPI-->>Script: Container ready status
                end
            end
            
            alt Not all ready
                Script->>Script: sleep 1
            end
        end
        
        Note right of Script: Returns: 0 (all ready) | 1 (timeout/failed)<br/>Timeout: 300 seconds default
    end

    %% ============================================================
    %% PHASE 1: KILL SWITCH SETUP (OPTIONAL)
    %% ============================================================
    rect rgb(255, 240, 245)
        Note over User,LocalFS: PHASE 1 (continued): Kill Switch Monitor Setup
        
        alt Kill switch configured (--kill-switch-* or --*-volume)
            Script->>Script: detect_kubelet_eviction_threshold()
            Script->>K8sAPI: $KUBE_CLI get --raw /api/v1/nodes/{node}/proxy/configz
            K8sAPI-->>Script: JSON: {kubeletconfig.evictionHard.nodefs.available}
            Note right of Script: Parses: nodefs.available threshold<br/>Adds: 5% safety margin<br/>Returns: Threshold value<br/>Fallback: 10% if detection fails
            
            Script->>Script: create_kill_switch_monitor_pods()
            
            loop For each debug pod
                Script->>Script: create_kill_switch_monitor_pod(debug_pod, type, target)
                Script->>Script: get_effective_cri_socket()
                Note right of Script: Returns: CRI socket path<br/>Priority: User-specified > Auto-detected
                
                Script->>Script: build_kill_switch_monitor_script()
                Note right of Script: Generates: Disk monitoring script<br/>Uses: df command<br/>Threshold: Absolute or relative<br/>Action: Exit 0 when exceeded
                
                Script->>Script: parse_size_to_bytes(threshold)
                Note right of Script: Input: "1GB", "500MB", "10%"<br/>Returns: Bytes (integer)<br/>Calls: format_bc_result() for calc
                
                Script->>K8sAPI: $KUBE_CLI apply -f - <<< {monitor_pod_yaml}
                K8sAPI-->>Script: pod/{kill-switch-monitor} created
            end
            
            Note right of Script: Sets: KILL_SWITCH_MONITOR_PODS[]<br/>Returns: void
            
            Script->>Script: monitor_kill_switches() &
            Note right of Script: Runs: Background process<br/>Polls: Every 1 second<br/>Checks: Monitor pod status<br/>Action: Delete debug pod if triggered
            
            activate KillSwitch
            
            loop Background monitoring loop
                Script->>K8sAPI: $KUBE_CLI get pod {monitor} -o jsonpath='{.status.phase}'
                K8sAPI-->>Script: Pod status
                
                alt Monitor status == "Succeeded"
                    KillSwitch-->>Script: Kill switch triggered!
                    Script->>K8sAPI: $KUBE_CLI delete pod {target_debug_pod}
                    K8sAPI-->>Script: Pod deleted
                    Script->>LocalFS: Save monitor logs
                end
            end
        end
    end

    %% ============================================================
    %% PHASE 2: DEBUG PODS RUNNING
    %% ============================================================
    rect rgb(240, 255, 240)
        Note over User,LocalFS: PHASE 2: Debug Pods Running - Command Execution
        
        Script-->>User: Display: "Debug pods are running"
        Script-->>User: Display: kubectl logs commands
        
        par Debug Pod Execution (Pod Target)
            activate DebugPod
            DebugPod->>DebugPod: Execute entrypoint script
            DebugPod->>DebugPod: configure_crictl_socket()
            Note right of DebugPod: Sets: CONTAINER_RUNTIME_ENDPOINT<br/>Configures: crictl for CRI
            
            DebugPod->>K8sAPI: crictl inspect {container_id}
            K8sAPI->>TargetPod: Get container PID
            TargetPod-->>K8sAPI: Container info JSON
            K8sAPI-->>DebugPod: PID of target container
            
            DebugPod->>DebugPod: generate_exec_command()
            Note right of DebugPod: Builds: nsenter command<br/>Params: -t {PID} -n [-m] [-p] [-u]<br/>Command: User-specified or tcpdump
            
            DebugPod->>TargetPod: nsenter -t {PID} -n {command}
            activate TargetPod
            Note right of TargetPod: Executes in target's<br/>network namespace
            TargetPod-->>DebugPod: Command output (streaming)
            deactivate TargetPod
        and Debug Pod Execution (Node Target)
            DebugPod->>TargetNode: chroot /host {command}
            activate TargetNode
            Note right of TargetNode: Executes with<br/>host filesystem access
            TargetNode-->>DebugPod: Command output (streaming)
            deactivate TargetNode
        and File Monitor Sidecar (if configured)
            DebugPod->>DebugPod: File monitor loop (every 1s)
            DebugPod->>DebugPod: Execute SELECT_TO_DOWNLOAD_COMMANDS
            DebugPod-->>DebugPod: File list with sizes
        end
    end

    %% ============================================================
    %% PHASE 3: USER INPUT
    %% ============================================================
    rect rgb(255, 255, 255)
        Note over User,LocalFS: PHASE 3: Waiting for User Input
        
        Script-->>User: "Press Enter to cleanup, or Ctrl+C to leave running"
        User->>Script: Press Enter
        
        alt User presses Ctrl+C
            Note over Script: Exit without cleanup<br/>Debug pods remain running
        end
    end

    %% ============================================================
    %% PHASE 4: CLEANUP DEBUG PODS
    %% ============================================================
    rect rgb(255, 245, 238)
        Note over User,LocalFS: PHASE 4: Cleanup Debug Pods
        
        alt NO_CLEANUP != true
            opt Kill switch monitoring active
                Script->>Script: kill $MONITOR_PID
                deactivate KillSwitch
            end
            
            Script->>Script: cleanup_debug_pods()
            
            alt OUTPUT_DIR specified
                loop For each debug_pod in DEBUG_POD_NAMES[]
                    Script->>Script: get_pod_log_file(debug_pod)
                    Note right of Script: Returns: Log file path<br/>Format: {OUTPUT_DIR}/debug/{pod}.log
                    
                    Script->>K8sAPI: $KUBE_CLI logs {debug_pod} -n {ns} --all-containers
                    K8sAPI-->>Script: All container logs
                    Script->>LocalFS: Write to debug/{pod}-{container}.log
                    LocalFS-->>Script: Logs saved
                end
            end
            
            Script->>K8sAPI: $KUBE_CLI delete pods {DEBUG_POD_NAMES[]} -n {ns}
            K8sAPI-->>Script: Pods deleted
            deactivate DebugPod
            
            Note right of Script: Returns: void<br/>Clears: DEBUG_POD_NAMES[]
            
            Script->>Script: cleanup_kill_switch_monitor_pods()
            
            alt Kill switch pods exist
                loop For each monitor in KILL_SWITCH_MONITOR_PODS[]
                    Script->>K8sAPI: $KUBE_CLI logs {monitor} -n {ns}
                    K8sAPI-->>Script: Monitor logs
                    Script->>LocalFS: Write to killswitch-logs/{monitor}.log
                end
                
                Script->>K8sAPI: $KUBE_CLI delete pods {KILL_SWITCH_MONITOR_PODS[]}
                K8sAPI-->>Script: Monitor pods deleted
            end
            
            Note right of Script: Returns: void
        end
    end

    %% ============================================================
    %% PHASE 5: FILE DISCOVERY & DOWNLOAD
    %% ============================================================
    rect rgb(240, 248, 255)
        Note over User,LocalFS: PHASE 5: File Discovery & Download
        
        alt OUTPUT_DIR specified AND (SELECT_TO_DOWNLOAD_COMMANDS[] or NODE_SELECT_TO_DOWNLOAD_COMMANDS[])
            Script->>Script: create_file_discovery_pods()
            
            loop For each target (pod or node)
                alt Pod target
                    Script->>Script: build_single_discovery_script(target)
                    Script->>Script: build_discovery_script(pod, container, node)
                    Note right of Script: Generates: File listing script<br/>Outputs: File paths to stdout<br/>Returns: Base64-encoded script
                    
                    Script->>Script: create_discovery_pod(target_info)
                    Script->>K8sAPI: $KUBE_CLI apply -f - <<< {discovery_pod_yaml}
                    K8sAPI-->>Script: pod/{discovery-pod} created
                else Node target
                    Script->>Script: build_single_node_discovery_script(target)
                    Script->>Script: build_node_discovery_script(node)
                    Note right of Script: Generates: Node file listing script<br/>Uses: chroot /host<br/>Returns: Base64-encoded script
                    
                    Script->>Script: create_node_discovery_pod(node_info)
                    Script->>K8sAPI: $KUBE_CLI apply -f - <<< {node_discovery_pod_yaml}
                    K8sAPI-->>Script: pod/{node-discovery-pod} created
                end
            end
            
            Note right of Script: Sets: DISCOVERY_POD_NAMES[]<br/>Sets: DISCOVERY_POD_INFO[]<br/>Returns: 0|1
            
            Script->>Script: wait_for_discovery_pods_ready()
            activate DiscoveryPod
            
            loop Until all discovery pods complete
                loop For each pod in DISCOVERY_POD_NAMES[]
                    Script->>K8sAPI: $KUBE_CLI get pod {discovery_pod} -o jsonpath='{.status.phase}'
                    K8sAPI-->>Script: "Running"|"Succeeded"|"Failed"
                end
            end
            
            Note right of Script: Returns: 0|1<br/>Waits for: status.phase == "Succeeded"
            
            Script->>Script: handle_file_downloads()
            
            loop For each discovery_pod in DISCOVERY_POD_INFO[]
                Script->>K8sAPI: $KUBE_CLI logs {discovery_pod} -n {ns}
                K8sAPI-->>Script: File list (one path per line)
                
                loop For each file_path in file_list
                    Script->>K8sAPI: $KUBE_CLI cp {pod}:{file_path} {local_path}
                    
                    alt Pod target
                        K8sAPI->>TargetPod: Read file from container
                        TargetPod-->>K8sAPI: File contents
                    else Node target
                        K8sAPI->>TargetNode: Read file from /host
                        TargetNode-->>K8sAPI: File contents
                    end
                    
                    K8sAPI-->>Script: File transferred
                    Script->>LocalFS: Write to downloads/{target}/{filename}
                    LocalFS-->>Script: File saved
                    
                    alt DOWNLOAD_VERIFICATION == "hash"
                        Script->>Script: Verify MD5 + SHA256
                    else DOWNLOAD_VERIFICATION == "size"
                        Script->>Script: Verify file size
                    end
                end
            end
            
            deactivate DiscoveryPod
            
            Note right of Script: Returns: void<br/>Files saved to: OUTPUT_DIR/downloads/
            
            Script->>Script: cleanup_discovery_pods()
            
            loop For each pod in DISCOVERY_POD_NAMES[]
                Script->>K8sAPI: $KUBE_CLI logs {discovery_pod}
                K8sAPI-->>Script: Discovery logs
                Script->>LocalFS: Write to discovery-logs/{pod}.log
            end
            
            Script->>K8sAPI: $KUBE_CLI delete pods {DISCOVERY_POD_NAMES[]}
            K8sAPI-->>Script: Discovery pods deleted
            
            Note right of Script: Returns: void
        end
    end

    %% ============================================================
    %% COMPLETION
    %% ============================================================
    rect rgb(240, 255, 240)
        Note over User,LocalFS: Session Complete
        
        alt KUBE_DUMP_LOG_FILE exists
            Script->>LocalFS: Append session end timestamp
            Script-->>User: "Session log saved to: {log_file}"
        end
        
        Script-->>User: "All operations completed!"
        deactivate Script
    end
```

## Function Reference

### Entry Point Functions
| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `main()` | `$@` (all CLI args) | exit 0\|1 | Main orchestrator - coordinates entire workflow |
| `usage()` | none | exit 0 | Displays help text and exits |

### Initialization Functions
| Function | Parameters | Returns | Sets |
|----------|------------|---------|------|
| `initialize_variables()` | none | void | All global variables to defaults |
| `detect_kube_cli()` | none | void | `KUBE_CLI` = "oc"\|"kubectl" |
| `parse_arguments()` | `$@` | void | All config variables from CLI |
| `validate_arguments()` | none | void\|exit 1 | `EXECUTION_MODE` |
| `validate_option_value()` | `$val`, `$option_name` | void\|exit 1 | - |
| `validate_variable()` | `$name`, `$value`, `$pattern` | 0\|1 | - |
| `validate_all_requirements()` | none | void\|exit 1 | - |

### Setup Functions
| Function | Parameters | Returns | Creates |
|----------|------------|---------|---------|
| `setup_output_directories()` | none | 0\|1 | downloads/, debug/, killswitch-logs/, discovery-logs/ |
| `setup_debug_logging()` | none | 0\|1 | DEBUG_LOG_DIR |
| `show_configuration()` | none | void | - |

### Target Selection Functions
| Function | Parameters | Returns | Sets |
|----------|------------|---------|------|
| `select_target_pods()` | none | 0\|1 | `POD_NAMES[]` |
| `find_pods_by_label()` | `$label` | void | Appends to `POD_NAMES[]` |
| `prepare_target_pods()` | none | 0\|1 | `TARGET_PODS[]` |
| `select_target_nodes()` | none | 0\|1 | `TARGET_NODES[]` |

### Debug Pod Creation Functions
| Function | Parameters | Returns | Creates |
|----------|------------|---------|---------|
| `create_debug_pods_for_targets()` | none | 0\|1 | Debug pods for pod targets |
| `create_node_debug_pods()` | none | 0\|1 | Debug pods for node targets |
| `create_single_debug_pod()` | `$name`, `$node`, `$yaml` | 0\|1 | Single debug pod |
| `create_single_node_debug_pod()` | `$node`, `$yaml` | 0\|1 | Single node debug pod |

### Container Generation Functions
| Function | Parameters | Returns |
|----------|------------|---------|
| `generate_command_container()` | `$index`, `$target` | YAML string |
| `generate_file_monitor_container()` | `$index` | YAML string |
| `generate_exec_command()` | `$pid`, `$cmd`, `$nsenter_flags` | Command string |

### Script Building Functions
| Function | Parameters | Returns |
|----------|------------|---------|
| `build_debug_script()` | `$pod`, `$container`, `$node` | Base64 script |
| `build_node_debug_script()` | `$node` | Base64 script |
| `build_file_monitor_script()` | `$pod`, `$container`, `$node`, `$target`, `$index` | Bash script |
| `build_node_file_monitor_script()` | `$pod`, `$container`, `$node`, `$target`, `$index` | Bash script |
| `build_discovery_script()` | `$pod`, `$container`, `$node` | Base64 script |
| `build_node_discovery_script()` | `$node` | Base64 script |
| `build_single_discovery_script()` | `$target` | Base64 script |
| `build_single_node_discovery_script()` | `$target` | Base64 script |
| `build_kill_switch_monitor_script()` | none | Bash script |

### Discovery & Download Functions
| Function | Parameters | Returns | Creates |
|----------|------------|---------|---------|
| `create_file_discovery_pods()` | none | 0\|1 | Discovery pods |
| `create_discovery_pod()` | `$target_info` | 0\|1 | Single discovery pod |
| `create_node_discovery_pod()` | `$node_info` | 0\|1 | Single node discovery pod |
| `wait_for_discovery_pods_ready()` | none | 0\|1 | - |
| `handle_file_downloads()` | none | void | Downloaded files |

### Kill Switch Functions
| Function | Parameters | Returns |
|----------|------------|---------|
| `detect_kubelet_eviction_threshold()` | none | Threshold value |
| `create_kill_switch_monitor_pods()` | none | void |
| `create_kill_switch_monitor_pod()` | `$debug_pod`, `$type`, `$target` | 0\|1 |
| `monitor_kill_switches()` | none | never returns (background) |
| `parse_size_to_bytes()` | `$size_string` | Integer (bytes) |
| `format_bc_result()` | `$bc_expression` | Formatted number |

### Wait Functions
| Function | Parameters | Returns | Timeout |
|----------|------------|---------|---------|
| `wait_for_debug_pods_ready()` | none | 0\|1 | 300s |
| `wait_for_discovery_pods_ready()` | none | 0\|1 | 300s |

### Cleanup Functions
| Function | Parameters | Returns | Deletes |
|----------|------------|---------|---------|
| `cleanup_debug_pods()` | none | void | DEBUG_POD_NAMES[] |
| `cleanup_discovery_pods()` | none | void | DISCOVERY_POD_NAMES[] |
| `cleanup_kill_switch_monitor_pods()` | none | void | KILL_SWITCH_MONITOR_PODS[] |

### Utility Functions
| Function | Parameters | Returns |
|----------|------------|---------|
| `run_kube_cmd()` | `$@` (kubectl args) | Command output |
| `format_message()` | `$message` | void (prints to stdout) |
| `format_message_stderr()` | `$message` | void (prints to stderr) |
| `get_pod_log_file()` | `$pod_name` | File path string |
| `truncate_name_with_hash()` | `$name` | Truncated name (≤63 chars) |
| `truncate_label_value_with_hash()` | `$value` | Valid K8s label |
| `get_import_file_for_command()` | `$index` | Base64 content |
| `get_node_import_file_for_command()` | `$index` | Base64 content |
| `get_effective_cri_socket()` | none | Socket path |
| `configure_crictl_socket()` | none | void |
| `detect_cri_socket_from_node()` | `$node_name` | Socket path |

## Global Variables

### Configuration Arrays
```
POD_LABELS[]                    # Label selectors for pods
NODE_LABELS[]                   # Label selectors for nodes
CUSTOM_COMMANDS[]               # Base64 encoded -e commands
CUSTOM_NODE_COMMANDS[]          # Base64 encoded -E commands
SELECT_TO_DOWNLOAD_COMMANDS[]   # -s file selection commands
NODE_SELECT_TO_DOWNLOAD_COMMANDS[] # -S node file selection commands
NSENTER_PARAMS_INDICES[]        # Command indices with custom nsenter
NSENTER_PARAMS_VALUES[]         # nsenter params for each index
IMPORT_FILE_INDICES[]           # Command indices with import files
IMPORT_FILE_CONTENTS[]          # Base64 encoded import file contents
```

### Runtime State Arrays
```
POD_NAMES[]                     # Discovered pod names
NODE_NAMES[]                    # Discovered node names
TARGET_PODS[]                   # "pod:container:node:namespace"
TARGET_NODES[]                  # Node names to target
DEBUG_POD_NAMES[]               # Created debug pod names
DEBUG_POD_NAMES_META[]          # Debug pod metadata
DISCOVERY_POD_NAMES[]           # Created discovery pod names
DISCOVERY_POD_INFO[]            # Discovery pod info
KILL_SWITCH_MONITOR_PODS[]      # Kill switch monitor pod names
```

### Configuration Variables
```
EXECUTION_MODE                  # "pod" | "node" | "mixed"
DEBUG_NAMESPACE                 # Namespace for debug pods
CRI_RUNTIME                     # "containerd" | "crio" | "docker"
CRI_SOCKET                      # Custom CRI socket path
DEBUG_IMAGE                     # Container image for debug pods
OUTPUT_DIR                      # Output directory for downloads
PLACEHOLDER_CHAR                # Placeholder prefix (default: %)
KILL_SWITCH_ABS                 # Absolute threshold (e.g., "1GB")
KILL_SWITCH_REL                 # Relative threshold (e.g., "10%")
POD_VOLUME                      # Volume path for pod kill switch
NODE_VOLUME                     # Volume path for node kill switch
CPU_LIMIT                       # Container CPU limit
MEMORY_LIMIT                    # Container memory limit
SERVICE_ACCOUNT                 # Service account for pods
KUBE_CLI                        # "kubectl" | "oc"
VERBOSE                         # "true" | "false"
```
