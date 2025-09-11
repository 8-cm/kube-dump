#!/bin/bash
# -------------------------------------------------------------------------------
# Function: usage
# -------------------------------------------------------------------------------
# Description:
#   Displays comprehensive usage information for the kube-dump script, including
#   all available command-line options, their descriptions, and practical examples.
#   This function serves as the primary help system for users.
#
# Parameters:
#   None.
#
# Example Usage:
#   ./kube-dump.sh -h
#   ./kube-dump.sh --help
#   This will display the complete usage information and exit the script.
#
# Expected Output:
#   - Detailed usage syntax with multiple invocation patterns
#   - Complete list of all command-line options with descriptions
#   - Comprehensive examples covering common use cases
#   - Terminates the script with exit status 0
#
# Detailed Behavior:
#   - Shows three different usage patterns: pod-based, node-based, and mixed execution
#   - Lists all options with short and long forms where applicable
#   - Provides real-world examples for network capture, custom commands, file downloads
#   - Includes examples for both pod-level and node-level operations
#   - Demonstrates advanced features like placeholder substitution and cross-namespace operations
# -------------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [-l <label_selector>] [-n <namespace>] [--to-namespace=<debug_namespace>] [-e <command>]"
  echo "   or: $0 [-L <node_label>] [-E <node_execute>] [--to-namespace=<debug_namespace>]"
  echo "   or: $0 [--label <label_selector>] [--namespace <namespace>] [--to-namespace=<debug_namespace>] [--execute <command>]"
  echo ""
  echo "Options:"
  echo "  -l, --label          Label selector to find multiple pods [default: dumpme=yes]"
  echo "  -L, --node-label     Label selector to find multiple nodes (for node-level commands)"
  echo "  -n, --namespace      Namespace where debug pods should be created (optional)"
  echo "  --to-namespace       Alias for -n/--namespace (deprecated, use -n instead)"
  echo "  --cri                Container runtime interface (containerd, crio, docker) [default: containerd]"
  echo "  --cri-socket         Custom CRI socket path (absolute path on node)"
  echo "  --install-deps       Allow automatic installation of CRI dependencies (crictl only)"
  echo "  --no-cleanup         Skip cleanup, leave debug pods running for log inspection"
  echo "  --include-nodes      Also run -E on nodes hosting pods selected by -l"
  echo "  -e, --execute        Command to execute [default: tcpdump -i any -nn -s 0]"
  echo "  -E, --node-execute   Command to execute on nodes [default: tcpdump -i any -nn -s 0]"
  echo "  -s, --select-to-download  Command to list files for download (space-delimited output)"
  echo "  -S, --node-select-to-download  Command to list node files for download"
  echo "  -o, --output         Output directory for downloaded files"
  echo "  -I, --placeholder    Set placeholder character for hostname substitution [default: %]"
  echo "  --kill-switch-abs    Kill pods when disk usage exceeds absolute threshold (e.g., 1GB, 500MB)"
  echo "  --kill-switch-rel    Kill pods when free space falls below relative threshold (e.g., 10%)"
  echo "  --pod-volume         Volume path to monitor for pod-based kill switches (e.g., /tmp)"
  echo "  --node-volume        Volume path to monitor for node-based kill switches (e.g., /var)"
  echo "  --image              Container image for debug/discovery/killswitch pods [default: nicolaka/netshoot]"
  echo "  --no-glyphs          Disable emojis and use text labels like [INFO], [ERROR], [OK]"
  echo "  -h, --help           Show this help message and exit"
  echo ""
  echo "Examples:"
  echo "  # Use defaults (dumpme=yes label, tcpdump -i any -nn -s 0):"
  echo "  $0"
  echo ""
  echo "  # Capture traffic from all pods with app=nginx label:"
  echo "  $0 -l app=nginx"
  echo ""
  echo "  # Capture from pods with multiple labels:"
  echo "  $0 -l 'tier=frontend,env=prod'"
  echo ""
  echo "  # Create debug pods in specific namespace (pods found cluster-wide):"
  echo "  $0 -l app=backend -n monitoring"
  echo ""
  echo "  # Custom complex command:"
  echo "  $0 -l app=web -e 'tcpdump -i any -w /tmp/capture.pcap host 10.1.1.1'"
  echo ""
  echo "  # Complex command with pipes and redirects:"
  echo "  $0 -l app=web -e 'tcpdump -i any -c 100 | grep \"port 80\" > /tmp/http_traffic.log'"
  echo ""
  echo "  # Use node default (node-label selector, tcpdump -i any -nn -s 0):"
  echo "  $0 -L node-role.kubernetes.io/worker"
  echo ""
  echo "  # Run command on specific nodes:"
  echo "  $0 -L node-role.kubernetes.io/worker=true -E 'ss -tuln'"
  echo ""
  echo "  # Run network diagnostics on control plane nodes:"
  echo "  $0 -L node-role.kubernetes.io/control-plane=true -E 'netstat -i'"
  echo ""
  echo "  # Monitor all worker nodes:"
  echo "  $0 -L worker=true -E 'tcpdump -i eth0 -nn host 10.1.1.1'"
  echo ""
  echo "  # Use placeholder for hostname substitution in commands:"
  echo "  $0 -l app=web -e 'tcpdump -i any -w %.pcap'"
  echo ""
  echo "  # Use custom placeholder character:"
  echo "  $0 -l app=web -e 'tcpdump -i any | tee @.log' -I@"
  echo ""
  echo "  # Generate files and download them:"
  echo "  $0 -l app=web -e 'tcpdump -i any -w %.pcap -c 100' -s 'ls *.pcap' -o ./downloads"
  echo ""
  echo "  # Generate node files with custom placeholder and download:"
  echo "  $0 -L worker=true -E 'ss -tuln > @-ports.txt' -S 'ls @-ports.txt' -I@ -o ./node-files"
  echo ""
  echo "  # Use custom CRI socket path:"
  echo "  $0 -l app=web --cri-socket /var/run/podman/podman.sock"
  echo ""
  echo "  # Use kill switch to prevent disk pressure (absolute threshold):"
  echo "  $0 -l app=web --kill-switch-abs 1GB --pod-volume /tmp"
  echo ""
  echo "  # Use kill switch to prevent disk pressure (relative threshold):"
  echo "  $0 -L worker=true --kill-switch-rel 10% --node-volume /var"
  echo ""
  echo "  # Also run commands on nodes hosting selected pods:"
  echo "  $0 -l app=web --include-nodes -E 'ss -tuln'"
  echo ""
  echo "  # Use custom container image for all debug pods:"
  echo "  $0 -l app=web --image alpine/network-tools"
  echo ""
  echo "Note: Script automatically selects first container from each pod for PID discovery."
  echo "All containers in a pod share the same network namespace."
  echo "For node commands, debug pods run with host networking and privileged access."
  exit 0
}

# -------------------------------------------------------------------------------
# Function: initialize_variables
# -------------------------------------------------------------------------------
# Description:
#   Initializes all script variables to their default values, setting up the
#   foundation for the debugging session. This function establishes default
#   configurations for pod targeting, node operations, command execution,
#   file handling, and runtime behavior.
#
# Parameters:
#   None.
#
# Example Usage:
#   initialize_variables
#   This function is called at the start of the script execution.
#
# Expected Output:
#   - All script variables are set to their default values
#   - Arrays are initialized as empty
#   - String variables are set to appropriate defaults
#   - Boolean flags are set to their default states
#
# Detailed Behavior:
#   - Sets up empty arrays for pod and node discovery
#   - Establishes default label selector (dumpme=yes) for pod targeting
#   - Configures default network capture command (tcpdump)
#   - Initializes container runtime settings (containerd as default)
#   - Sets up placeholder character for hostname substitution (%)
#   - Configures default behavior flags (cleanup enabled, dependencies manual)
#   - Prepares variables for file download operations
# -------------------------------------------------------------------------------
initialize_variables() {
  POD_NAMES=()  # Array for discovered pods
  POD_LABEL="dumpme=yes"  # Default label selector for finding pods
  POD_LABEL_EXPLICIT=false  # Track if POD_LABEL was explicitly set by user
  NODE_NAMES=()  # Array for discovered nodes
  NODE_LABEL=""  # Label selector for finding nodes
  NODE_COMMAND="tcpdump -i any -nn -s 0"  # Default tcpdump command (same as pod mode)
  CUSTOM_NODE_COMMAND=""  # Custom command from -E
  SELECT_TO_DOWNLOAD_COMMAND=""  # Command to list files to download from -s
  NODE_SELECT_TO_DOWNLOAD_COMMAND=""  # Command to list files to download from -S
  ENCODED_SELECT_COMMAND=""  # Base64 encoded select command
  ENCODED_NODE_SELECT_COMMAND=""  # Base64 encoded node select command
  OUTPUT_DIR=""  # Output directory for downloaded files from -o
  PLACEHOLDER_CHAR="%"  # Default placeholder character for hostname substitution
  DISCOVERY_POD_NAMES=()  # Array for file discovery pods
  DISCOVERY_POD_INFO=()  # Array to track discovery pod info: "discovery_pod_name:node_name:type:original_debug_pod_name"
  POD_DEBUG_HOSTNAMES=()     # Array to store debug pod hostnames for pod targets
  NODE_DEBUG_HOSTNAMES=()    # Array to store debug pod hostnames for node targets
  EXECUTION_MODE="pod"  # pod or node execution mode
  DEBUG_NAMESPACE=""
  DEBUG_POD_NAMES=()  # Array for multiple debug pods
  CAPTURE_COMMAND="tcpdump -i any -nn -s 0"  # Default tcpdump command
  CUSTOM_COMMAND=""  # Base64 encoded custom command from -e
  TARGET_PODS=()  # Array of pod info: "pod_name:container_name:node_name:namespace"
  TARGET_NODES=()  # Array for node info: "node_name"
  CRI_RUNTIME="containerd"  # Default container runtime interface
  CRI_SOCKET=""  # Custom CRI socket path (absolute path on node)
  INSTALL_DEPS="false"  # Default: do not install dependencies automatically
  NO_CLEANUP="false"  # Default: cleanup debug pods after execution
  INCLUDE_NODES="false"  # Default: do not auto-include nodes with selected pods
  KILL_SWITCH_ABS=""  # Kill switch absolute threshold (e.g., 1GB, 500MB)
  KILL_SWITCH_REL=""  # Kill switch relative threshold (e.g., 10%)
  POD_VOLUME=""  # Volume path to monitor for pod-based kill switches
  NODE_VOLUME=""  # Volume path to monitor for node-based kill switches
  KILL_SWITCH_MONITOR_PODS=()  # Array for kill switch monitor pods
  DEBUG_IMAGE="nicolaka/netshoot"  # Default container image for debug/discovery/killswitch pods
  KUBE_CLI=""  # Will be set to 'oc' or '$KUBE_CLI' based on availability
}

# -------------------------------------------------------------------------------
# Function: detect_kube_cli
# -------------------------------------------------------------------------------
detect_kube_cli() {
  if command -v oc >/dev/null 2>&1; then
    KUBE_CLI="oc"
    echo "Using OpenShift CLI (oc)" >&2
  elif command -v $KUBE_CLI >/dev/null 2>&1; then
    KUBE_CLI="$KUBE_CLI"
    echo "Using Kubernetes CLI ($KUBE_CLI)" >&2
  else
    echo "Error: Neither 'oc' nor '$KUBE_CLI' found in PATH" >&2
    exit 1
  fi
}

# -------------------------------------------------------------------------------
# Function: validate_option_value
# -------------------------------------------------------------------------------
validate_option_value() {
  local val="$1"
  local option_name="$2"

  if [[ -z "$val" || "$val" == -* ]]; then
    echo "Error: Argument $option_name requires a value" >&2
    usage
  fi
}

# -------------------------------------------------------------------------------
# Function: format_message
# -------------------------------------------------------------------------------
format_message() {
  local message="$1"
  
  if [[ "$NO_GLYPHS" == "true" ]]; then
    message="${message//🔍/[SEARCH]}"
    message="${message//🔧/[SETUP]}"
    message="${message//🛡️/[SECURITY]}"
    message="${message//✅/[OK]}"
    message="${message//🔴/[KILL]}"
    message="${message//❌/[ERROR]}"
    message="${message//🟢/[SUCCESS]}"
    message="${message//⚠️/[WARNING]}"
    message="${message//📋/[INFO]}"
    message="${message//🔄/[PROGRESS]}"
    message="${message//📥/[DOWNLOAD]}"
    message="${message//🚫/[BLOCKED]}"
    message="${message//💾/[STORAGE]}"
    message="${message//⏳/[WAITING]}"
    message="${message//🖥️/[NODE]}"
    message="${message//ℹ️/[INFO]}"
    message="${message//⏸️/[PAUSE]}"
    message="${message//🗑️/[CLEANUP]}"
    message="${message//📦/[POD]}"
    message="${message//🧹/[CLEAN]}"
    message="${message//🚀/[LAUNCH]}"
    message="${message//🎯/[TARGET]}"
    message="${message//📊/[STATUS]}"
    message="${message//🎉/[COMPLETE]}"
    message="${message//━/=}"
  fi
  
  echo "$message"
  
  # Log to file if OUTPUT_DIR is specified (indicating -o was used)
  if [[ -n "$OUTPUT_DIR" && -n "$KUBE_DUMP_LOG_FILE" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$KUBE_DUMP_LOG_FILE"
  fi
}

# -------------------------------------------------------------------------------
# Function: format_message_stderr
# -------------------------------------------------------------------------------
format_message_stderr() {
  local message="$1"
  
  if [[ "$NO_GLYPHS" == "true" ]]; then
    message="${message//🔍/[SEARCH]}"
    message="${message//🔧/[SETUP]}"
    message="${message//🛡️/[SECURITY]}"
    message="${message//✅/[OK]}"
    message="${message//🔴/[KILL]}"
    message="${message//❌/[ERROR]}"
    message="${message//🟢/[SUCCESS]}"
    message="${message//⚠️/[WARNING]}"
    message="${message//📋/[INFO]}"
    message="${message//🔄/[PROGRESS]}"
    message="${message//📥/[DOWNLOAD]}"
    message="${message//🚫/[BLOCKED]}"
    message="${message//💾/[STORAGE]}"
    message="${message//⏳/[WAITING]}"
    message="${message//🖥️/[NODE]}"
    message="${message//ℹ️/[INFO]}"
    message="${message//⏸️/[PAUSE]}"
    message="${message//🗑️/[CLEANUP]}"
    message="${message//📦/[POD]}"
    message="${message//🧹/[CLEAN]}"
    message="${message//🚀/[LAUNCH]}"
    message="${message//🎯/[TARGET]}"
    message="${message//📊/[STATUS]}"
    message="${message//🎉/[COMPLETE]}"
    message="${message//━/=}"
  fi
  
  echo "$message" >&2
  
  # Log to file if OUTPUT_DIR is specified (indicating -o was used)
  if [[ -n "$OUTPUT_DIR" && -n "$KUBE_DUMP_LOG_FILE" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - STDERR: $message" >> "$KUBE_DUMP_LOG_FILE"
  fi
}

# -------------------------------------------------------------------------------
# Function: get_effective_cri_socket
# -------------------------------------------------------------------------------
get_effective_cri_socket() {
  if [[ -n "$CRI_SOCKET" ]]; then
    echo "$CRI_SOCKET"
  else
    case "$CRI_RUNTIME" in
      "containerd")
        echo "/run/containerd/containerd.sock"
        ;;
      "crio")
        echo "/run/crio/crio.sock"
        ;;
      "docker")
        echo "/var/run/cri-dockerd.sock"
        ;;
      *)
        echo "/run/containerd/containerd.sock"
        ;;
    esac
  fi
}

# -------------------------------------------------------------------------------
# Function: show_configuration
# -------------------------------------------------------------------------------
show_configuration() {
  echo ""
  format_message "📋 Configuration Summary:"
  echo "=================================================="
  echo "Execution Mode:      $EXECUTION_MODE"
  echo "Kubernetes CLI:      $KUBE_CLI"
  echo ""
  echo "Pod Selection:"
  echo "  Label Selector:    ${POD_LABEL:-"(not set)"}"
  echo "  Namespace:         ${DEBUG_NAMESPACE:-"(current/default)"}"
  echo ""
  echo "Node Selection:"
  echo "  Node Label:        ${NODE_LABEL:-"(not set)"}"
  echo "  Include Nodes:     ${INCLUDE_NODES}"
  echo ""
  echo "Commands:"
  echo "  Pod Command:       ${CUSTOM_COMMAND:-"$CAPTURE_COMMAND"}"
  echo "  Node Command:      ${CUSTOM_NODE_COMMAND:-"$NODE_COMMAND"}"
  echo ""
  echo "Container Settings:"
  echo "  Image:             $DEBUG_IMAGE"
  echo "  CRI Runtime:       $CRI_RUNTIME"
  echo "  CRI Socket:        $(get_effective_cri_socket)"
  echo "  Install Deps:      $INSTALL_DEPS"
  echo ""
  echo "File Operations:"
  echo "  Pod File Cmd:      ${SELECT_TO_DOWNLOAD_COMMAND:-"(not set)"}"
  echo "  Node File Cmd:     ${NODE_SELECT_TO_DOWNLOAD_COMMAND:-"(not set)"}"
  echo "  Output Dir:        ${OUTPUT_DIR:-"(not set)"}"
  echo "  Placeholder:       $PLACEHOLDER_CHAR"
  echo ""
  echo "Kill Switch:"
  echo "  Absolute:          ${KILL_SWITCH_ABS:-"(not set)"}"
  echo "  Relative:          ${KILL_SWITCH_REL:-"(not set)"}"
  echo "  Pod Volume:        ${POD_VOLUME:-"(not set)"}"
  echo "  Node Volume:       ${NODE_VOLUME:-"(not set)"}"
  echo ""
  echo "Options:"
  echo "  No Cleanup:        $NO_CLEANUP"
  echo "  No Glyphs:         ${NO_GLYPHS:-"false"}"
  echo "  Mock Mode:         ${MOCK_MODE:-"false"}"
  echo "=================================================="
  echo ""
}

# -------------------------------------------------------------------------------
# Function: validate_variable
# -------------------------------------------------------------------------------
validate_variable() {
  local var_name="$1"
  local var_value="$2"
  local validation_type="$3"
  local allowed_values="$4"
  local is_required="$5"

  # Check if required and empty
  if [[ "$is_required" == "true" && -z "$var_value" ]]; then
    echo "Error: $var_name is required but empty" >&2
    exit 1
  fi

  # Skip further validation if empty and not required
  if [[ -z "$var_value" && "$is_required" != "true" ]]; then
    return 0
  fi

  case "$validation_type" in
    "enum")
      if [[ -n "$allowed_values" ]]; then
        IFS=',' read -ra VALUES <<< "$allowed_values"
        local valid=false
        for value in "${VALUES[@]}"; do
          if [[ "$var_value" == "$value" ]]; then
            valid=true
            break
          fi
        done
        if [[ "$valid" != "true" ]]; then
          echo "Error: $var_name must be one of: $allowed_values" >&2
          exit 1
        fi
      fi
      ;;
    "boolean")
      if [[ "$var_value" != "true" && "$var_value" != "false" ]]; then
        echo "Error: $var_name must be 'true' or 'false'" >&2
        exit 1
      fi
      ;;
    "array")
      # Check if array is declared (different approach for compatibility)
      if ! declare -p "$var_name" &>/dev/null; then
        echo "Error: Array $var_name is not initialized" >&2
        exit 1
      fi
      ;;
    "string")
      # Basic string validation - could be extended
      if [[ -n "$var_value" && ${#var_value} -eq 0 ]]; then
        echo "Error: $var_name cannot be empty string" >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: Unknown validation type: $validation_type" >&2
      exit 1
      ;;
  esac
}

# -------------------------------------------------------------------------------
# Function: parse_arguments
# -------------------------------------------------------------------------------
parse_arguments() {
  while [[ "$#" -gt 0 ]]; do
    # Process long arguments with "="
    if [[ $1 == --*"="* ]]; then
      arg="${1%%=*}"
      val="${1#*=}"
      if [[ -z "$val" ]]; then
        echo "Error: Argument $arg requires a value" >&2
        usage
      fi
    else
      arg="$1"
      val="$2"
    fi

    case $arg in
      -l|--label)
        if [[ $1 == --label=* ]]; then
          POD_LABEL="$val"
          POD_LABEL_EXPLICIT=true
        else
          validate_option_value "$val" "-l|--label"
          POD_LABEL="$val"
          POD_LABEL_EXPLICIT=true
          shift
        fi
        ;;
      -L|--node-label)
        if [[ $1 == --node-label=* ]]; then
          NODE_LABEL="$val"
          # Clear default pod label if only node targeting is intended (not explicitly set)
          if [[ -z "$CUSTOM_COMMAND" && "$POD_LABEL" == "dumpme=yes" && "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABEL=""
          fi
        else
          validate_option_value "$val" "-L|--node-label"
          NODE_LABEL="$val"
          # Clear default pod label if only node targeting is intended (not explicitly set)
          if [[ -z "$CUSTOM_COMMAND" && "$POD_LABEL" == "dumpme=yes" && "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABEL=""
          fi
          shift
        fi
        ;;
      -n|--namespace)
        if [[ $1 == --namespace=* ]]; then
          DEBUG_NAMESPACE="$val"
        else
          validate_option_value "$val" "-n|--namespace"
          DEBUG_NAMESPACE="$val"
          shift
        fi
        ;;
      --to-namespace)
        if [[ $1 == --to-namespace=* ]]; then
          DEBUG_NAMESPACE="$val"
        else
          validate_option_value "$val" "--to-namespace"
          DEBUG_NAMESPACE="$val"
          shift
        fi
        ;;
      --cri)
        if [[ $1 == --cri=* ]]; then
          CRI_RUNTIME="$val"
        else
          validate_option_value "$val" "--cri"
          CRI_RUNTIME="$val"
          shift
        fi
        ;;
      --cri-socket)
        if [[ $1 == --cri-socket=* ]]; then
          CRI_SOCKET="$val"
        else
          validate_option_value "$val" "--cri-socket"
          CRI_SOCKET="$val"
          shift
        fi
        ;;
      -e|--execute)
        if [[ $1 == --execute=* ]]; then
          CUSTOM_COMMAND="$val"
        else
          validate_option_value "$val" "-e|--execute"
          CUSTOM_COMMAND="$val"
          shift
        fi
        ;;
      -E|--node-execute)
        if [[ $1 == --node-execute=* ]]; then
          CUSTOM_NODE_COMMAND="$val"
          NODE_COMMAND="$val"
        else
          validate_option_value "$val" "-E|--node-execute"
          CUSTOM_NODE_COMMAND="$val"
          NODE_COMMAND="$val"
          shift
        fi
        ;;
      -s|--select-to-download)
        if [[ $1 == --select-to-download=* ]]; then
          SELECT_TO_DOWNLOAD_COMMAND="$val"
        else
          validate_option_value "$val" "-s|--select-to-download"
          SELECT_TO_DOWNLOAD_COMMAND="$val"
          shift
        fi
        ;;
      -S|--node-select-to-download)
        if [[ $1 == --node-select-to-download=* ]]; then
          NODE_SELECT_TO_DOWNLOAD_COMMAND="$val"
        else
          validate_option_value "$val" "-S|--node-select-to-download"
          NODE_SELECT_TO_DOWNLOAD_COMMAND="$val"
          shift
        fi
        ;;
      -o|--output)
        if [[ $1 == --output=* ]]; then
          OUTPUT_DIR="$val"
        else
          validate_option_value "$val" "-o|--output"
          OUTPUT_DIR="$val"
          shift
        fi
        ;;
      -I|--placeholder)
        if [[ $1 == --placeholder=* ]]; then
          PLACEHOLDER_CHAR="$val"
        else
          validate_option_value "$val" "-I|--placeholder"
          PLACEHOLDER_CHAR="$val"
          shift
        fi
        ;;
      -h|--help)
        usage
        ;;
      --install-deps)
        INSTALL_DEPS="true"
        ;;
      --no-cleanup)
        NO_CLEANUP="true"
        ;;
      --include-nodes)
        INCLUDE_NODES="true"
        ;;
      --kill-switch-abs)
        if [[ $1 == --kill-switch-abs=* ]]; then
          KILL_SWITCH_ABS="$val"
        else
          validate_option_value "$val" "--kill-switch-abs"
          KILL_SWITCH_ABS="$val"
          shift
        fi
        ;;
      --kill-switch-rel)
        if [[ $1 == --kill-switch-rel=* ]]; then
          KILL_SWITCH_REL="$val"
        else
          validate_option_value "$val" "--kill-switch-rel"
          KILL_SWITCH_REL="$val"
          shift
        fi
        ;;
      --pod-volume)
        if [[ $1 == --pod-volume=* ]]; then
          POD_VOLUME="$val"
        else
          validate_option_value "$val" "--pod-volume"
          POD_VOLUME="$val"
          shift
        fi
        ;;
      --node-volume)
        if [[ $1 == --node-volume=* ]]; then
          NODE_VOLUME="$val"
        else
          validate_option_value "$val" "--node-volume"
          NODE_VOLUME="$val"
          shift
        fi
        ;;
      --image)
        if [[ $1 == --image=* ]]; then
          DEBUG_IMAGE="$val"
        else
          validate_option_value "$val" "--image"
          DEBUG_IMAGE="$val"
          shift
        fi
        ;;
      --no-glyphs)
        NO_GLYPHS=true
        ;;
      --mock)
        MOCK_MODE=true
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        usage
        ;;
      *)
        echo "Error: Unexpected argument: $1" >&2
        usage
        ;;
    esac
    shift
  done
}

# -------------------------------------------------------------------------------
# Function: validate_arguments
# -------------------------------------------------------------------------------
validate_arguments() {
  # Determine execution mode based on what options are provided
  local has_pod_options=false
  local has_node_options=false

  if [[ -n "$POD_LABEL" ]]; then
    has_pod_options=true
  fi

  if [[ -n "$NODE_LABEL" ]]; then
    has_node_options=true
  fi

  # Set execution mode based on options provided
  if [[ "$has_pod_options" == "true" && "$has_node_options" == "true" ]]; then
    EXECUTION_MODE="mixed"
  elif [[ "$has_pod_options" == "true" && "$INCLUDE_NODES" == "true" ]]; then
    EXECUTION_MODE="mixed"  # --include-nodes with pod options becomes mixed mode
  elif [[ "$has_node_options" == "true" ]]; then
    EXECUTION_MODE="node"
  else
    EXECUTION_MODE="pod"  # Default mode
  fi

  # Validate configuration variables using universal validator
  validate_variable "EXECUTION_MODE" "$EXECUTION_MODE" "enum" "pod,node,mixed" "true"

  if [[ "$EXECUTION_MODE" == "pod" || "$EXECUTION_MODE" == "mixed" ]]; then
    validate_variable "POD_LABEL" "$POD_LABEL" "string" "" "true"
    validate_variable "CAPTURE_COMMAND" "$CAPTURE_COMMAND" "string" "" "true"
    validate_variable "CUSTOM_COMMAND" "$CUSTOM_COMMAND" "string" "" "false"
  fi

  if [[ "$EXECUTION_MODE" == "node" || "$EXECUTION_MODE" == "mixed" ]]; then
    validate_variable "NODE_COMMAND" "$NODE_COMMAND" "string" "" "true"
    validate_variable "CUSTOM_NODE_COMMAND" "$CUSTOM_NODE_COMMAND" "string" "" "false"
    
    # For mixed mode triggered by --include-nodes, NODE_LABEL is optional
    if [[ "$EXECUTION_MODE" == "mixed" && "$INCLUDE_NODES" == "true" && -z "$NODE_LABEL" ]]; then
      # --include-nodes case: NODE_LABEL is not required
      :
    else
      validate_variable "NODE_LABEL" "$NODE_LABEL" "string" "" "true"
    fi
  fi

  # Specific validation for --include-nodes
  if [[ "$INCLUDE_NODES" == "true" && -z "$CUSTOM_NODE_COMMAND" ]]; then
    echo "Error: --include-nodes requires -E/--node-execute to specify what command to run on nodes" >&2
    usage
  fi

  validate_variable "DEBUG_NAMESPACE" "$DEBUG_NAMESPACE" "string" "" "false"
  validate_variable "CRI_RUNTIME" "$CRI_RUNTIME" "enum" "containerd,crio,docker" "true"
  validate_variable "INSTALL_DEPS" "$INSTALL_DEPS" "boolean" "" "true"

  # Validate file download related options
  validate_variable "SELECT_TO_DOWNLOAD_COMMAND" "$SELECT_TO_DOWNLOAD_COMMAND" "string" "" "false"
  validate_variable "NODE_SELECT_TO_DOWNLOAD_COMMAND" "$NODE_SELECT_TO_DOWNLOAD_COMMAND" "string" "" "false"
  validate_variable "OUTPUT_DIR" "$OUTPUT_DIR" "string" "" "false"
  validate_variable "PLACEHOLDER_CHAR" "$PLACEHOLDER_CHAR" "string" "" "true"

  # Validate file download dependencies
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" || -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    if [[ -z "$OUTPUT_DIR" ]]; then
      echo "Error: -o/--output directory must be specified when using -s/-S file download options" >&2
      return 1
    fi
  fi

  # Validate kill switch arguments
  validate_variable "KILL_SWITCH_ABS" "$KILL_SWITCH_ABS" "string" "" "false"
  validate_variable "KILL_SWITCH_REL" "$KILL_SWITCH_REL" "string" "" "false"

  # Kill switch arguments are mutually exclusive
  if [[ -n "$KILL_SWITCH_ABS" && -n "$KILL_SWITCH_REL" ]]; then
    echo "Error: --kill-switch-abs and --kill-switch-rel are mutually exclusive. Use only one." >&2
    return 1
  fi

  # Kill switches require volume path arguments based on execution mode
  if [[ -n "$KILL_SWITCH_ABS" || -n "$KILL_SWITCH_REL" ]]; then
    case "$EXECUTION_MODE" in
      "pod")
        if [[ -z "$POD_VOLUME" ]]; then
          echo "Error: Kill switches in pod mode require --pod-volume to specify the volume path to monitor" >&2
          return 1
        fi
        ;;
      "node")
        if [[ -z "$NODE_VOLUME" ]]; then
          echo "Error: Kill switches in node mode require --node-volume to specify the volume path to monitor" >&2
          return 1
        fi
        ;;
      "mixed")
        if [[ -z "$POD_VOLUME" || -z "$NODE_VOLUME" ]]; then
          echo "Error: Kill switches in mixed mode require both --pod-volume and --node-volume to specify volume paths to monitor" >&2
          return 1
        fi
        ;;
    esac
  fi

  # Arrays are initialized in initialize_variables(), no need to validate here

  # Show message about execution mode and defaults
  if [[ "$EXECUTION_MODE" == "pod" ]]; then
    if [[ -z "$CUSTOM_COMMAND" ]]; then
      echo "Pod command: tcpdump -i any -nn -s 0" >&2
    else
      echo "Pod command: $CUSTOM_COMMAND" >&2
    fi
  elif [[ "$EXECUTION_MODE" == "node" ]]; then
    if [[ -z "$CUSTOM_NODE_COMMAND" ]]; then
      echo "Node command: tcpdump -i any -nn -s 0" >&2
    else
      echo "Node command: $NODE_COMMAND" >&2
    fi
  elif [[ "$EXECUTION_MODE" == "mixed" ]]; then
    echo "Using mixed execution mode (both pod and node targets)" >&2
    if [[ -z "$CUSTOM_COMMAND" ]]; then
      echo "Pod command: tcpdump -i any -nn -s 0" >&2
    else
      echo "Pod command: $CUSTOM_COMMAND" >&2
    fi
    if [[ -z "$CUSTOM_NODE_COMMAND" ]]; then
      echo "Node command: tcpdump -i any -nn -s 0" >&2
    else
      echo "Node command: $NODE_COMMAND" >&2
    fi
  fi

  # Show select commands for file downloads if configured
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    echo "Pod select command: $SELECT_TO_DOWNLOAD_COMMAND" >&2
  fi
  if [[ -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    echo "Node select command: $NODE_SELECT_TO_DOWNLOAD_COMMAND" >&2
  fi
}

# -------------------------------------------------------------------------------
# Function: select_target_pods
# -------------------------------------------------------------------------------
select_target_pods() {
  # Determine debug namespace if not provided (for creating debug pods)
  if [ -z "$DEBUG_NAMESPACE" ]; then
    DEBUG_NAMESPACE=$($KUBE_CLI config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    if [ -z "$DEBUG_NAMESPACE" ]; then
      DEBUG_NAMESPACE="default"
    fi
  fi

  # Label selector is required
  if [[ -z "$POD_LABEL" ]]; then
    echo "Error: Label selector (-l) is required" >&2
    return 1
  fi

  # Find pods using label selector
  find_pods_by_label

  return 0
}

# -------------------------------------------------------------------------------
# Function: prepare_target_pods
# -------------------------------------------------------------------------------
prepare_target_pods() {
  format_message "🔧 Preparing target pods for debugging..."

  for pod_info in "${POD_NAMES[@]}"; do
    local pod_name=$(echo "$pod_info" | cut -d':' -f1)
    local containers=$(echo "$pod_info" | cut -d':' -f2)
    local node_name=$(echo "$pod_info" | cut -d':' -f3)
    local pod_namespace=$(echo "$pod_info" | cut -d':' -f4)

    # Check if pod is running
    local pod_phase
    if ! pod_phase=$($KUBE_CLI get pod "${pod_name}" -n "${pod_namespace}" -o jsonpath='{.status.phase}' 2>/dev/null); then
      echo "  Warning: Failed to get status for pod '$pod_name', skipping" >&2
      continue
    fi

    if [[ "$pod_phase" != "Running" ]]; then
      echo "  Warning: Pod '$pod_name' is not running (status: $pod_phase), skipping" >&2
      continue
    fi

    # Handle container selection for PID discovery
    # All containers share the same network namespace, so we just need any running container
    local target_container=$(echo "$containers" | awk '{print $1}')
    # Add to target pods array
    TARGET_PODS+=("${pod_name}:${target_container}:${node_name}:${pod_namespace}")
    format_message "   ✅ ${pod_name} (${pod_namespace}) -> ${target_container} on ${node_name}"
  done

  if [[ ${#TARGET_PODS[@]} -eq 0 ]]; then
    echo "Error: No valid target pods found" >&2
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------------------
# Function: select_target_nodes
# -------------------------------------------------------------------------------
select_target_nodes() {
  format_message "🔍 Finding nodes with label selector: $NODE_LABEL"
  echo ""

  # Get nodes matching the label selector
  local nodes_output
  if ! nodes_output=$($KUBE_CLI get nodes -l "$NODE_LABEL" -o custom-columns="NAME:.metadata.name" --no-headers 2>/dev/null); then
    echo "Error: Failed to query nodes with label selector '$NODE_LABEL'" >&2
    return 1
  fi

  if [[ -z "$nodes_output" ]]; then
    echo "Error: No nodes found with label selector '$NODE_LABEL'" >&2
    return 1
  fi

  # Convert to array (compatible with older bash versions)
  while IFS= read -r line; do
    NODE_NAMES+=("$line")
  done <<< "$nodes_output"

  format_message "✅ Found ${#NODE_NAMES[@]} nodes:"
  for node_name in "${NODE_NAMES[@]}"; do
    format_message "   🖥️  $node_name"
    TARGET_NODES+=("$node_name")
  done
  echo ""

  # If --include-nodes is enabled and we have pod selections, also include nodes with selected pods
  if [[ "$INCLUDE_NODES" == "true" && ${#TARGET_PODS[@]} -gt 0 ]]; then
    format_message "🔍 Processing --include-nodes: adding nodes hosting selected pods"

    # Get nodes from selected pods
    local pod_nodes=()
    for target_pod in "${TARGET_PODS[@]}"; do
      local node_name=$(echo "$target_pod" | cut -d':' -f3)
      pod_nodes+=("$node_name")
    done

    # Remove duplicates and find nodes not already selected by -L
    local unique_pod_nodes=($(printf '%s\n' "${pod_nodes[@]}" | sort -u))
    local additional_nodes=()

    for pod_node in "${unique_pod_nodes[@]}"; do
      # Check if this node is already in TARGET_NODES
      local already_selected=false
      for existing_node in "${TARGET_NODES[@]}"; do
        if [[ "$existing_node" == "$pod_node" ]]; then
          already_selected=true
          break
        fi
      done

      if [[ "$already_selected" == "false" ]]; then
        additional_nodes+=("$pod_node")
        TARGET_NODES+=("$pod_node")
      fi
    done

    if [[ ${#additional_nodes[@]} -gt 0 ]]; then
      echo "   ➕ Added ${#additional_nodes[@]} additional nodes from pod selections:"
      for node in "${additional_nodes[@]}"; do
        format_message "      🖥️  $node"
      done
      echo ""
    else
      format_message "ℹ️  No additional nodes needed (all pod nodes already selected by -L)"
    fi
  fi

  return 0
}

# -------------------------------------------------------------------------------
# Function: find_pods_by_label
# -------------------------------------------------------------------------------
find_pods_by_label() {
  format_message "🔍 Finding pods with label selector: $POD_LABEL"
  echo ""

  local pod_list
  if ! pod_list=$($KUBE_CLI get pods --all-namespaces -l "${POD_LABEL}" -o jsonpath='{range .items[*]}{.metadata.name}{":"}{.spec.containers[*].name}{":"}{.spec.nodeName}{":"}{.metadata.namespace}{"\n"}{end}' 2>/dev/null); then
    echo "Error: Failed to find pods with label '$POD_LABEL'" >&2
    return 1
  fi

  if [[ -z "$pod_list" ]]; then
    echo "Error: No pods found with label '$POD_LABEL' (searched cluster-wide)" >&2
    return 1
  fi

  # Parse pod list and populate POD_NAMES array
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      POD_NAMES+=("$line")
    fi
  done <<< "$pod_list"

  format_message "✅ Found ${#POD_NAMES[@]} pods:"
  for pod_info in "${POD_NAMES[@]}"; do
    local pod_name=$(echo "$pod_info" | cut -d':' -f1)
    local pod_namespace=$(echo "$pod_info" | cut -d':' -f4)
    format_message "   📦 $pod_name (namespace: $pod_namespace)"
  done
  echo ""

  return 0
}

# -------------------------------------------------------------------------------
# Function: validate_all_requirements
# -------------------------------------------------------------------------------
validate_all_requirements() {
  # Check cluster access
  if ! $KUBE_CLI auth can-i create pods --quiet 2>/dev/null; then
    echo "Error: No permission to create pods" >&2
    return 1
  fi

  if ! $KUBE_CLI cluster-info &>/dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster" >&2
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------------------
# Function: create_debug_pods_for_targets
# -------------------------------------------------------------------------------
create_debug_pods_for_targets() {
  # Set capture command before creating pods
  if [[ -n "$CUSTOM_COMMAND" ]]; then
    # Encode custom command to base64
    CAPTURE_COMMAND=$(echo -n "$CUSTOM_COMMAND" | base64 -w 0)
  fi

  # Encode select-to-download commands to base64
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    ENCODED_SELECT_COMMAND=$(echo -n "$SELECT_TO_DOWNLOAD_COMMAND" | base64 -w 0)
  fi

  if [[ -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    ENCODED_NODE_SELECT_COMMAND=$(echo -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" | base64 -w 0)
  fi

  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time=$(date +"%s")


  for target_pod in "${TARGET_PODS[@]}"; do
    local pod_name=$(echo "$target_pod" | cut -d':' -f1)
    local container_name=$(echo "$target_pod" | cut -d':' -f2)
    local node_name=$(echo "$target_pod" | cut -d':' -f3)

    # Generate unique debug pod name with hash for shorter names
    local pod_hash
    if command -v md5sum >/dev/null 2>&1; then
      pod_hash=$(echo "$pod_name" | md5sum | cut -c1-8)
    elif command -v md5 >/dev/null 2>&1; then
      pod_hash=$(echo "$pod_name" | md5 | cut -c1-8)
    else
      # Fallback to simple hash
      pod_hash=$(echo "$pod_name" | cksum | cut -d' ' -f1 | cut -c1-8)
    fi
    local debug_pod_name="${node_name}-debug-${pod_hash}-${epoch_time}"

    # Check if pod name exists and increment until unique
    local counter=1
    while $KUBE_CLI get pod "${debug_pod_name}" -n "${debug_ns}" &>/dev/null; do
      counter=$((counter + 1))
      debug_pod_name="${node_name}-debug-${pod_hash}-${epoch_time}-${counter}"
    done

    format_message "   📦 Creating debug pod for ${pod_name}:${container_name} on ${node_name}"

    create_single_debug_pod "$pod_name" "$container_name" "$node_name" "$debug_pod_name" "$debug_ns"
    if [[ $? -eq 0 ]]; then
      DEBUG_POD_NAMES+=("$debug_pod_name")
      # Store debug pod hostname for file download phase
      POD_DEBUG_HOSTNAMES+=("$debug_pod_name")
    else
      format_message "      ❌ Failed to create debug pod for $pod_name"
    fi
  done

  return 0
}

# -------------------------------------------------------------------------------
# Function: create_node_debug_pods
# -------------------------------------------------------------------------------
create_node_debug_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE:-default}}"

  for node_name in "${TARGET_NODES[@]}"; do
    local node_hash
    if command -v md5sum >/dev/null 2>&1; then
      node_hash=$(echo "$node_name" | md5sum | cut -c1-6)
    elif command -v md5 >/dev/null 2>&1; then
      node_hash=$(echo "$node_name" | md5 | cut -c1-6)
    else
      # Fallback to simple hash
      node_hash=$(echo "$node_name" | cksum | cut -d' ' -f1 | cut -c1-6)
    fi
    local debug_pod_name="node-${node_hash}-$(date +%s)"
    local counter=1

    # Check if pod name exists and increment until unique
    while $KUBE_CLI get pod "${debug_pod_name}" -n "${debug_ns}" &>/dev/null; do
      counter=$((counter + 1))
      debug_pod_name="node-${node_hash}-$(date +%s)-${counter}"
    done

    format_message "   🖥️  Creating debug pod for node '${node_name}'"

    if create_single_node_debug_pod "$node_name" "$debug_pod_name" "$debug_ns"; then
      DEBUG_POD_NAMES+=("$debug_pod_name")
      # Store debug pod hostname for file download phase
      NODE_DEBUG_HOSTNAMES+=("$debug_pod_name")
    else
      format_message "      ❌ Failed to create debug pod for node $node_name"
    fi
  done

  return 0
}

# -------------------------------------------------------------------------------
# Function: create_single_node_debug_pod
# -------------------------------------------------------------------------------
create_single_node_debug_pod() {
  local node_name="$1"
  local debug_pod_name="$2"
  local debug_ns="$3"

  $KUBE_CLI apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${debug_pod_name}
  namespace: ${debug_ns}
  labels:
    app: debug
    node: ${node_name}
spec:
  hostPID: true
  hostNetwork: true
  hostIPC: true
  containers:
  - name: debugger
    image: ${DEBUG_IMAGE}
    command: ["/bin/bash", "-c"]
    args:
    - |
$(build_node_debug_script "$node_name" "$debug_pod_name" | sed 's/^/      /')
    securityContext:
      privileged: true
      runAsUser: 0
    volumeMounts:
    - name: host
      mountPath: /host
  volumes:
  - name: host
    hostPath:
      path: /
      type: Directory
  nodeSelector:
    kubernetes.io/hostname: ${node_name}
EOF
}

# -------------------------------------------------------------------------------
# Function: build_node_debug_script
# -------------------------------------------------------------------------------
build_node_debug_script() {
  local node_name="$1"
  local debug_pod_name="$2"

  # Substitute placeholder with debug pod hostname in node command
  local final_node_command="${NODE_COMMAND//${PLACEHOLDER_CHAR}/$debug_pod_name}"

  cat <<SCRIPT
set -e
echo "=== Node command execution on node:${node_name} ===" >&2

# Install CRI dependencies if requested
if [[ "${INSTALL_DEPS}" == "true" ]]; then
  echo "Installing CRI dependencies..." >&2

  # Install crictl if needed (the only CRI-related dependency we need)
  if ! command -v crictl >/dev/null 2>&1; then
    echo "Installing crictl..." >&2
    if command -v curl >/dev/null 2>&1; then
      curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz | tar -C /usr/local/bin -xz 2>/dev/null && chmod +x /usr/local/bin/crictl || echo "Warning: Could not install crictl" >&2
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz | tar -C /usr/local/bin -xz 2>/dev/null && chmod +x /usr/local/bin/crictl || echo "Warning: Could not install crictl" >&2
    else
      echo "Warning: No download tool available for crictl" >&2
    fi
  fi
fi

echo "Executing: ${final_node_command}" >&2

# Execute the node command directly
${final_node_command} ; tail -f /dev/null
SCRIPT
}

# -------------------------------------------------------------------------------
# Function: create_single_debug_pod
# -------------------------------------------------------------------------------
create_single_debug_pod() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local debug_pod_name="$4"
  local debug_ns="$5"

  # Create pod with embedded script
  $KUBE_CLI apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${debug_pod_name}
  namespace: ${debug_ns}
spec:
  containers:
  - name: debugger
    image: ${DEBUG_IMAGE}
    command: ["/bin/bash", "-c"]
    args:
    - |
$(build_debug_script "$pod_name" "$container_name" "$node_name" "$debug_pod_name" | sed 's/^/      /')
    securityContext:
      privileged: true
      runAsUser: 0
    volumeMounts:
    - name: host
      mountPath: /host
  hostNetwork: true
  hostPID: true
  hostIPC: true
  nodeName: ${node_name}
  restartPolicy: Never
  volumes:
  - name: host
    hostPath:
      path: /
      type: Directory
EOF
}

# -------------------------------------------------------------------------------
# Function: build_debug_script
# -------------------------------------------------------------------------------
build_debug_script() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local debug_pod_name="$4"

  cat <<SCRIPT
set -e
echo "Starting network capture for ${pod_name}:${container_name}" >&2

# Function to configure crictl socket
configure_crictl_socket() {
  local socket_path

  # Use custom socket if provided, otherwise use runtime defaults
  if [[ -n "${CRI_SOCKET}" ]]; then
    socket_path="unix:///host${CRI_SOCKET}"
  else
    case "${CRI_RUNTIME}" in
      "containerd")
        socket_path="unix:///host/run/containerd/containerd.sock"
        ;;
      "crio")
        socket_path="unix:///host/run/crio/crio.sock"
        ;;
      "docker")
        socket_path="unix:///host/var/run/cri-dockerd.sock"
        ;;
      *)
        socket_path="unix:///host/run/containerd/containerd.sock"
        ;;
    esac
  fi

  echo "runtime-endpoint: \${socket_path}" > /etc/crictl.yaml
  echo "Configured crictl with runtime endpoint: \${socket_path}" >&2
}

# Configure crictl socket based on runtime and custom settings
configure_crictl_socket

# Check for crictl availability
if command -v crictl >/dev/null 2>&1; then
  CRICTL=crictl
elif [[ -x /host/usr/local/bin/crictl ]]; then
  CRICTL=/host/usr/local/bin/crictl
elif [[ "${INSTALL_DEPS}" == "true" ]]; then
  echo "Installing crictl..." >&2
  cd /tmp && curl -sL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz | tar -xzf -
  chmod +x crictl
  CRICTL=/tmp/crictl
else
  echo "ERROR: crictl not available and --install-deps not specified" >&2
  echo "Either use --install-deps flag or ensure crictl is available in the image" >&2
  exit 1
fi

if [[ "${INSTALL_DEPS}" == "true" ]]; then
  echo "CRI tools setup completed" >&2
else
  echo "Using existing CRI tools (--install-deps not specified)" >&2
fi

# Get container PID
echo "Looking up pod in namespace ${NAMESPACE}..." >&2
POD_ID=\$(\$CRICTL pods --namespace "${NAMESPACE}" --name "${pod_name}" -q)
echo "Pod ID: \$POD_ID" >&2

if [ -z "\$POD_ID" ]; then
  echo "ERROR: Could not find pod '${pod_name}' in namespace '${NAMESPACE}'" >&2
  exit 1
fi

echo "Looking up container '${container_name}' directly..." >&2
CID=\$(\$CRICTL ps --name "${container_name}" -q | head -1)
echo "Container ID: \$CID" >&2

if [ -z "\$CID" ]; then
  echo "ERROR: Could not find container '${container_name}'" >&2
  echo "Available containers:" >&2
  \$CRICTL ps
  exit 1
fi

echo "Getting container PID..."
PID=\$(\$CRICTL inspect "\$CID" | jq -r '.info.pid // empty' 2>/dev/null)
if [ -z "\$PID" ]; then
  PID=\$(\$CRICTL inspect "\$CID" | grep '"pid":' | head -1 | cut -d: -f2 | cut -d, -f1 | tr -d ' "')
fi

if [ -z "\$PID" ] || [ "\$PID" = "0" ]; then
  echo "ERROR: Could not get valid PID for container \$CID" >&2
  exit 1
fi

echo "Found container PID: \$PID" >&2
echo "=== Network capture for pod:${pod_name} container:${container_name} PID:\$PID ===" >&2

# Execute in network namespace
if [[ -d "/host/proc/\$PID" ]]; then
  $(generate_exec_command "${debug_pod_name}")
else
  echo "ERROR: PID \$PID not found" >&2
  exit 1
fi
SCRIPT
}

# -------------------------------------------------------------------------------
# Function: generate_exec_command
# -------------------------------------------------------------------------------
generate_exec_command() {
  local debug_pod_hostname="$1"

  if [[ -n "$CUSTOM_COMMAND" ]]; then
    echo "DECODED_CMD=\$(echo '${CAPTURE_COMMAND}' | base64 -d)"
    echo "FINAL_CMD=\$(echo \"\$DECODED_CMD\" | sed 's/${PLACEHOLDER_CHAR}/${debug_pod_hostname}/g')"
    echo 'exec nsenter -n -t $PID /bin/bash -c "$FINAL_CMD ; tail -f /dev/null"'
  else
    local final_capture_cmd="${CAPTURE_COMMAND//${PLACEHOLDER_CHAR}/$debug_pod_hostname}"
    echo "exec nsenter -n -t \$PID ${final_capture_cmd}"
  fi
}

# -------------------------------------------------------------------------------
# Function: wait_for_debug_pods_ready
# -------------------------------------------------------------------------------
wait_for_debug_pods_ready() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local max_wait=60

  local ready_pods=()
  local failed_pods=()
  local wait_time=0

  # Show initial status
  printf "$(format_message "🔄 Checking %d debug pods\n")" "${#DEBUG_POD_NAMES[@]}"

  while [ $wait_time -lt $max_wait ] && [ ${#ready_pods[@]} -lt ${#DEBUG_POD_NAMES[@]} ]; do
    for debug_pod in "${DEBUG_POD_NAMES[@]}"; do
      # Skip if already ready or failed
      if [[ " ${ready_pods[*]} " == *" $debug_pod "* ]] || [[ " ${failed_pods[*]} " == *" $debug_pod "* ]]; then
        continue
      fi

      local pod_status
      if pod_status=$($KUBE_CLI get pod "${debug_pod}" -n "${debug_ns}" -o jsonpath='{.status.phase}' 2>/dev/null); then
        if [[ "$pod_status" == "Running" ]]; then
          ready_pods+=("$debug_pod")
        elif [[ "$pod_status" == "Failed" ]]; then
          failed_pods+=("$debug_pod")
        fi
      fi
    done

    if [ ${#ready_pods[@]} -lt ${#DEBUG_POD_NAMES[@]} ]; then
      sleep 2
      wait_time=$((wait_time + 2))
      printf "."
    fi
  done

  echo ""

  # Show final status
  if [ ${#failed_pods[@]} -gt 0 ]; then
    format_message "   ⚠️  Ready: ${#ready_pods[@]}, Failed: ${#failed_pods[@]}, Total: ${#DEBUG_POD_NAMES[@]}"
    for failed_pod in "${failed_pods[@]}"; do
      format_message "      ❌ $failed_pod failed to start"
    done
  else
    format_message "   ✅ All ${#ready_pods[@]} debug pods are ready"
  fi
  echo ""

  if [ ${#ready_pods[@]} -eq 0 ]; then
    format_message "   ❌ Error: No debug pods became ready"
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------------------
# Function: create_file_discovery_pods
# -------------------------------------------------------------------------------
create_file_discovery_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time=$(date +"%s")
  echo ""

  # Create discovery pods for pod targets (if -s is specified)
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" && ${#POD_DEBUG_HOSTNAMES[@]} -gt 0 ]]; then
    format_message "📦 Creating discovery pods for pod targets..."

    local pod_index=0
    for target_pod in "${TARGET_PODS[@]}"; do
      local pod_name=$(echo "$target_pod" | cut -d':' -f1)
      local container_name=$(echo "$target_pod" | cut -d':' -f2)
      local node_name=$(echo "$target_pod" | cut -d':' -f3)
      local original_debug_hostname="${POD_DEBUG_HOSTNAMES[$pod_index]}"

      # Generate unique discovery pod name (shortened to avoid k8s length limits)
      local pod_hash
      if command -v md5sum >/dev/null 2>&1; then
        pod_hash=$(echo "$pod_name" | md5sum | cut -c1-8)
      elif command -v md5 >/dev/null 2>&1; then
        pod_hash=$(echo "$pod_name" | md5 | cut -c1-8)
      else
        # Fallback to simple hash
        pod_hash=$(echo "$pod_name" | cksum | cut -d' ' -f1 | cut -c1-8)
      fi
      local base_name="disc-${node_name}-${pod_hash}-${epoch_time}"
      local counter=1
      local discovery_pod_name="${base_name}-${counter}"

      # Find available name (truncate if still too long)
      while $KUBE_CLI get pod "$discovery_pod_name" -n "$debug_ns" &>/dev/null; do
        counter=$((counter + 1))
        discovery_pod_name="${base_name}-${counter}"
        # Ensure name is under 63 chars (k8s limit)
        if [[ ${#discovery_pod_name} -gt 63 ]]; then
          discovery_pod_name=$(echo "$discovery_pod_name" | cut -c1-63)
        fi
      done

      # Create discovery pod with tail -f /dev/null entrypoint
      if create_discovery_pod "$pod_name" "$container_name" "$node_name" "$discovery_pod_name" "$debug_ns" 2>/dev/null; then
        DISCOVERY_POD_NAMES+=("$discovery_pod_name")
        DISCOVERY_POD_INFO+=("$discovery_pod_name:$node_name:pod:$original_debug_hostname")
      else
        echo "  Warning: Failed to create discovery pod for $pod_name" >&2
        return 1
      fi

      pod_index=$((pod_index + 1))
    done
  fi

  # Create discovery pods for node targets (if -S is specified)
  if [[ -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" && ${#NODE_DEBUG_HOSTNAMES[@]} -gt 0 ]]; then
    echo ""
    format_message "🖥️  Creating discovery pods for node targets..."

    local node_index=0
    for node_name in "${TARGET_NODES[@]}"; do
      local original_debug_hostname="${NODE_DEBUG_HOSTNAMES[$node_index]}"

      # Generate unique discovery pod name (shortened to avoid k8s length limits)
      local base_name="ndisc-${node_name}-${epoch_time}"
      local counter=1
      local discovery_pod_name="${base_name}-${counter}"

      # Find available name (truncate if still too long)
      while $KUBE_CLI get pod "$discovery_pod_name" -n "$debug_ns" &>/dev/null; do
        counter=$((counter + 1))
        discovery_pod_name="${base_name}-${counter}"
        # Ensure name is under 63 chars (k8s limit)
        if [[ ${#discovery_pod_name} -gt 63 ]]; then
          discovery_pod_name=$(echo "$discovery_pod_name" | cut -c1-63)
        fi
      done

      # Create node discovery pod with tail -f /dev/null entrypoint
      if create_node_discovery_pod "$node_name" "$discovery_pod_name" "$debug_ns" 2>/dev/null; then
        DISCOVERY_POD_NAMES+=("$discovery_pod_name")
        DISCOVERY_POD_INFO+=("$discovery_pod_name:$node_name:node:$original_debug_hostname")
      else
        echo "  Warning: Failed to create discovery pod for node $node_name" >&2
        return 1
      fi

      node_index=$((node_index + 1))
    done
  fi

  if [[ ${#DISCOVERY_POD_NAMES[@]} -eq 0 ]]; then
    echo "Error: No discovery pods were created" >&2
    return 1
  fi

  echo ""
  format_message "⏳ Waiting for discovery pods to be ready..."
  if ! wait_for_discovery_pods_ready 2>/dev/null; then
    format_message_stderr "❌ Discovery pods failed to become ready"
    return 1
  fi
  format_message "   ✅ All discovery pods are ready"

  return 0
}

# -------------------------------------------------------------------------------
# Function: handle_file_downloads
# -------------------------------------------------------------------------------
handle_file_downloads() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local successful_pods=()
  local failed_pods=()

  echo ""
  format_message_stderr "📥 Downloading files..."

  # Create output directory if it doesn't exist
  if ! mkdir -p "$OUTPUT_DIR"; then
    echo "Error: Failed to create output directory: $OUTPUT_DIR" >&2
    return 1
  fi

  for pod_info in "${DISCOVERY_POD_INFO[@]}"; do
    local discovery_pod_name=$(echo "$pod_info" | cut -d':' -f1)
    local node_name=$(echo "$pod_info" | cut -d':' -f2)
    local pod_type=$(echo "$pod_info" | cut -d':' -f3)
    local original_debug_pod_name=$(echo "$pod_info" | cut -d':' -f4)
    local pod_had_failure=false

    # Determine which select command to use based on pod type
    local select_command=""
    if [[ "$pod_type" == "pod" && -n "$ENCODED_SELECT_COMMAND" ]]; then
      select_command=$(echo "$ENCODED_SELECT_COMMAND" | base64 -d)
    elif [[ "$pod_type" == "node" && -n "$ENCODED_NODE_SELECT_COMMAND" ]]; then
      select_command=$(echo "$ENCODED_NODE_SELECT_COMMAND" | base64 -d)
    fi

    if [[ -z "$select_command" ]]; then
      continue
    fi

    # Apply placeholder substitution using the original debug pod name that created the files
    select_command="${select_command//${PLACEHOLDER_CHAR}/$original_debug_pod_name}"

    # Execute the select command to get list of files
    local files_list
    if ! files_list=$($KUBE_CLI exec "$discovery_pod_name" -n "$debug_ns" -- bash -c "$select_command" 2>/dev/null); then
      format_message_stderr "   ❌ Failed to execute select command on pod $discovery_pod_name (node $node_name)"
      failed_pods+=("$discovery_pod_name")
      continue
    fi

    if [[ -z "$files_list" ]]; then
      continue
    fi
    local downloaded_files=()
    while IFS= read -r file_path; do
      if [[ -n "$file_path" ]]; then
        local output_file="$OUTPUT_DIR/${original_debug_pod_name}_$(basename "$file_path")"

        # Try download with up to 3 attempts (handles transient network/pod issues)
        local download_success=false
        local attempt=1
        local max_attempts=3
        
        while [[ $attempt -le $max_attempts && "$download_success" == "false" ]]; do
          if [[ $attempt -gt 1 ]]; then
            sleep 1  # Brief pause between retries to allow pod/network recovery
          fi
          
          if $KUBE_CLI cp "$debug_ns/$discovery_pod_name:$file_path" "$output_file" 2>/dev/null; then
            if [[ $attempt -gt 1 ]]; then
              format_message_stderr "   ✅ $(basename "$file_path") (succeeded on attempt $attempt)"
            else
              format_message_stderr "   ✅ $(basename "$file_path")"
            fi
            downloaded_files+=("$file_path")
            download_success=true
          else
            if [[ $attempt -eq $max_attempts ]]; then
              format_message_stderr "   ❌ Failed: $(basename "$file_path") from pod $discovery_pod_name on node $node_name (after $max_attempts attempts)"
              pod_had_failure=true
            else
              format_message_stderr "   ⚠️  Retrying $(basename "$file_path") (attempt $((attempt + 1))/$max_attempts)"
            fi
          fi
          ((attempt++))
        done
      fi
    done <<< "$files_list"

    # Remove successfully downloaded files from the node's persistent filesystem
    for file_path in "${downloaded_files[@]}"; do
      $KUBE_CLI exec "$discovery_pod_name" -n "$debug_ns" -- rm -f "$file_path" 2>/dev/null
    done

    # Track which pods had issues
    if [[ "$pod_had_failure" == "true" ]]; then
      failed_pods+=("$discovery_pod_name")
    else
      successful_pods+=("$discovery_pod_name")
    fi
  done

  # Clean up only successful pods, keep failed ones for inspection
  if [[ ${#successful_pods[@]} -gt 0 ]]; then
    echo ""
    format_message "🧹 Cleaning up ${#successful_pods[@]} successful discovery pods..."
    $KUBE_CLI delete pods "${successful_pods[@]}" -n "$debug_ns" --ignore-not-found >/dev/null 2>&1
  fi

  if [[ ${#failed_pods[@]} -gt 0 ]]; then
    echo ""
    format_message "⚠️  Keeping ${#failed_pods[@]} discovery pods with issues for inspection:"
    for failed_pod in "${failed_pods[@]}"; do
      format_message "   🔍 $failed_pod"
    done
  fi

  return 0
}

# -------------------------------------------------------------------------------
# Function: cleanup_debug_pods
# -------------------------------------------------------------------------------
cleanup_debug_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#DEBUG_POD_NAMES[@]} -gt 0 ]]; then
    $KUBE_CLI delete pods "${DEBUG_POD_NAMES[@]}" -n "${debug_ns}" --ignore-not-found >/dev/null 2>&1
  fi
}

# -------------------------------------------------------------------------------
# Function: cleanup_discovery_pods
# -------------------------------------------------------------------------------
cleanup_discovery_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#DISCOVERY_POD_NAMES[@]} -gt 0 ]]; then
    $KUBE_CLI delete pods "${DISCOVERY_POD_NAMES[@]}" -n "${debug_ns}" --ignore-not-found >/dev/null 2>&1
  fi
}

# -------------------------------------------------------------------------------
# Function: create_discovery_pod
# -------------------------------------------------------------------------------
create_discovery_pod() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local discovery_pod_name="$4"
  local debug_ns="$5"

  # Create discovery pod using YAML manifest for file discovery
  $KUBE_CLI apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${discovery_pod_name}
  namespace: ${debug_ns}
spec:
  restartPolicy: Never
  hostNetwork: true
  hostPID: true
  nodeSelector:
    kubernetes.io/hostname: ${node_name}
  containers:
  - name: discovery
    image: ${DEBUG_IMAGE}
    command: ["tail", "-f", "/dev/null"]
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-root
      mountPath: /host
      readOnly: false
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
EOF
}

# -------------------------------------------------------------------------------
# Function: create_node_discovery_pod
# -------------------------------------------------------------------------------
create_node_discovery_pod() {
  local node_name="$1"
  local discovery_pod_name="$2"
  local debug_ns="$3"

  # Create node discovery pod using YAML manifest
  $KUBE_CLI apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${discovery_pod_name}
  namespace: ${debug_ns}
spec:
  restartPolicy: Never
  hostNetwork: true
  hostPID: true
  nodeSelector:
    kubernetes.io/hostname: ${node_name}
  containers:
  - name: discovery
    image: ${DEBUG_IMAGE}
    command: ["tail", "-f", "/dev/null"]
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-root
      mountPath: /host
      readOnly: false
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
EOF
}

# -------------------------------------------------------------------------------
# Function: wait_for_discovery_pods_ready
# -------------------------------------------------------------------------------
wait_for_discovery_pods_ready() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local max_wait=120
  local wait_time=0

  echo "Waiting for discovery pods to be ready..." >&2

  while [[ $wait_time -lt $max_wait ]]; do
    local all_ready=true

    for discovery_pod in "${DISCOVERY_POD_NAMES[@]}"; do
      if ! $KUBE_CLI get pod "$discovery_pod" -n "$debug_ns" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Running"; then
        all_ready=false
        break
      fi
    done

    if [[ "$all_ready" == "true" ]]; then
      echo "All discovery pods are ready" >&2
      return 0
    fi

    sleep 2
    wait_time=$((wait_time + 2))
    echo -n "." >&2
  done

  echo "" >&2
  echo "Timeout: Discovery pods did not become ready within ${max_wait}s" >&2
  return 1
}

# -------------------------------------------------------------------------------
# Function: create_kill_switch_monitor_pods
# -------------------------------------------------------------------------------
# Description:
#   Creates monitoring pods that watch storage usage and complete when thresholds are exceeded.
#   These pods run alongside debug pods and signal when to kill the main debug pods.
#
# Parameters:
#   None (uses global variables)
#
# Returns:
#   0 on success, 1 on failure
# -------------------------------------------------------------------------------
create_kill_switch_monitor_pods() {
  # Skip if no kill switches are configured
  if [[ -z "$KILL_SWITCH_ABS" && -z "$KILL_SWITCH_REL" ]]; then
    return 0
  fi

  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time=$(date +"%s")

  format_message "🛡️  Creating kill switch monitor pods..."

  for debug_pod in "${DEBUG_POD_NAMES[@]}"; do
    # Get the node where the debug pod is running
    local node_name
    if ! node_name=$($KUBE_CLI get pod "$debug_pod" -n "$debug_ns" -o jsonpath='{.spec.nodeName}' 2>/dev/null); then
      format_message_stderr "   ⚠️  Warning: Could not get node for debug pod $debug_pod, skipping monitor"
      continue
    fi

    # Determine volume path based on pod type (pod vs node debug pod)
    local volume_path=""
    if [[ "$debug_pod" == *"node-debug"* ]]; then
      volume_path="$NODE_VOLUME"
    else
      volume_path="$POD_VOLUME"
    fi

    # Create shorter name: node + hash of original debug pod name
    local debug_pod_hash
    if command -v md5sum >/dev/null 2>&1; then
      debug_pod_hash=$(echo "$debug_pod" | md5sum | cut -c1-8)
    elif command -v md5 >/dev/null 2>&1; then
      debug_pod_hash=$(echo "$debug_pod" | md5 | cut -c1-8)
    else
      # Fallback to simple hash
      debug_pod_hash=$(echo "$debug_pod" | cksum | cut -d' ' -f1 | cut -c1-8)
    fi
    local monitor_pod_name="ks-${node_name}-${debug_pod_hash}"

    if create_kill_switch_monitor_pod "$debug_pod" "$node_name" "$monitor_pod_name" "$debug_ns" "$volume_path"; then
      KILL_SWITCH_MONITOR_PODS+=("$monitor_pod_name")
      format_message "   ✅ Created kill switch monitor: $monitor_pod_name -> $debug_pod (volume: $volume_path)"
    else
      format_message "   ❌ Failed to create kill switch monitor for $debug_pod"
    fi
  done

  return 0
}

# -------------------------------------------------------------------------------
# Function: create_kill_switch_monitor_pod
# -------------------------------------------------------------------------------
# Description:
#   Creates a single kill switch monitor pod that watches storage and completes when threshold exceeded.
#
# Parameters:
#   $1 - Target debug pod name to monitor
#   $2 - Node name where the debug pod is running
#   $3 - Monitor pod name
#   $4 - Namespace
#   $5 - Volume path to monitor
#
# Returns:
#   0 on success, 1 on failure
# -------------------------------------------------------------------------------
create_kill_switch_monitor_pod() {
  local target_debug_pod="$1"
  local node_name="$2"
  local monitor_pod_name="$3"
  local debug_ns="$4"
  local volume_path="$5"

  $KUBE_CLI apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${monitor_pod_name}
  namespace: ${debug_ns}
  labels:
    app: kill-switch-monitor
    target-pod: ${target_debug_pod}
spec:
  restartPolicy: Never
  hostNetwork: true
  hostPID: true
  nodeSelector:
    kubernetes.io/hostname: ${node_name}
  containers:
  - name: monitor
    image: ${DEBUG_IMAGE}
    command: ["/bin/bash", "-c"]
    args:
    - |
$(build_kill_switch_monitor_script "$target_debug_pod" "$volume_path" | sed 's/^/      /')
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-root
      mountPath: /host
      readOnly: true
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
EOF
}

# -------------------------------------------------------------------------------
# Function: build_kill_switch_monitor_script
# -------------------------------------------------------------------------------
# Description:
#   Generates the monitoring script that runs inside kill switch monitor pods.
#   The script continuously monitors storage and exits with code 0 when threshold is exceeded.
#
# Parameters:
#   $1 - Target debug pod name to monitor
#   $2 - Volume path to monitor
#
# Returns:
#   Script content to stdout
# -------------------------------------------------------------------------------
build_kill_switch_monitor_script() {
  local target_debug_pod="$1"
  local volume_path="$2"

  cat <<SCRIPT
set -e
echo "=== Kill switch monitor for ${target_debug_pod} ===" >&2

# Function to parse size to bytes (supports OpenShift/k8s standard units)
parse_size_to_bytes() {
  local size_str="\$1"
  local size_num=""
  local size_unit=""

  if [[ "\$size_str" =~ ^([0-9]+\.?[0-9]*)([A-Za-z]+)\$ ]]; then
    size_num="\${BASH_REMATCH[1]}"
    size_unit="\${BASH_REMATCH[2]}"
  elif [[ "\$size_str" =~ ^([0-9]+\.?[0-9]*)\$ ]]; then
    size_num="\${BASH_REMATCH[1]}"
    size_unit="B"
  else
    echo ""
    return 1
  fi

  local bytes=""
  case "\$size_unit" in
    "B"|"b") bytes="\$size_num" ;;
    "K"|"k") bytes=\$((\${size_num%.*} * 1000)) ;;
    "Ki"|"KiB"|"ki"|"kib") bytes=\$((\${size_num%.*} * 1024)) ;;
    "M"|"m") bytes=\$((\${size_num%.*} * 1000000)) ;;
    "Mi"|"MiB"|"mi"|"mib"|"MB"|"mb") bytes=\$((\${size_num%.*} * 1048576)) ;;
    "G"|"g") bytes=\$((\${size_num%.*} * 1000000000)) ;;
    "Gi"|"GiB"|"gi"|"gib"|"GB"|"gb") bytes=\$((\${size_num%.*} * 1073741824)) ;;
    "T"|"t") bytes=\$((\${size_num%.*} * 1000000000000)) ;;
    "Ti"|"TiB"|"ti"|"tib"|"TB"|"tb") bytes=\$((\${size_num%.*} * 1099511627776)) ;;
    *) echo ""; return 1 ;;
  esac

  echo "\$bytes"
}

KILL_SWITCH_ABS="${KILL_SWITCH_ABS}"
KILL_SWITCH_REL="${KILL_SWITCH_REL}"
CHECK_INTERVAL=1  # Check every 1 second for fast response

if [[ -n "\$KILL_SWITCH_ABS" ]]; then
  echo "Monitoring storage with absolute threshold: \$KILL_SWITCH_ABS" >&2
elif [[ -n "\$KILL_SWITCH_REL" ]]; then
  echo "Monitoring storage with relative threshold: \$KILL_SWITCH_REL" >&2
else
  echo "No kill switch thresholds configured - exiting" >&2
  exit 1
fi

VOLUME_PATH="${volume_path}"

while true; do
  # Get filesystem stats for the specified volume path
  if df_output=\$(df -B1 "\$VOLUME_PATH" 2>/dev/null); then
    stats_line=\$(echo "\$df_output" | tail -n 1)
    used_bytes=\$(echo "\$stats_line" | awk '{print \$3}')
    available_bytes=\$(echo "\$stats_line" | awk '{print \$4}')
    total_bytes=\$(echo "\$stats_line" | awk '{print \$2}')

    # Check absolute threshold (available space falls below threshold)
    if [[ -n "\$KILL_SWITCH_ABS" && -n "\$available_bytes" ]]; then
      threshold_bytes=\$(parse_size_to_bytes "\$KILL_SWITCH_ABS")
      if [[ -n "\$threshold_bytes" && "\$available_bytes" -lt "\$threshold_bytes" ]]; then
        echo "KILL_SWITCH_TRIGGERED: Available space (\$available_bytes bytes) is below absolute threshold (\$KILL_SWITCH_ABS = \$threshold_bytes bytes)" >&2
        exit 0  # Signal to kill the target pod
      fi
    fi

    # Check relative threshold
    if [[ -n "\$KILL_SWITCH_REL" && -n "\$available_bytes" && -n "\$total_bytes" && "\$total_bytes" -gt 0 ]]; then
      rel_threshold="\${KILL_SWITCH_REL%\\%}"  # Remove % if present
      if command -v bc >/dev/null 2>&1; then
        free_percent=\$(echo "scale=2; (\$available_bytes * 100) / \$total_bytes" | bc 2>/dev/null || echo "")
        if [[ -n "\$free_percent" && -n "\$rel_threshold" ]]; then
          should_kill=\$(echo "\$free_percent < \$rel_threshold" | bc -l 2>/dev/null || echo "0")
          if [[ "\$should_kill" == "1" ]]; then
            echo "KILL_SWITCH_TRIGGERED: Free space (\${free_percent}%) is below relative threshold (\$KILL_SWITCH_REL)" >&2
            exit 0  # Signal to kill the target pod
          fi
        fi
      fi
    fi
  fi

  sleep "\$CHECK_INTERVAL"
done
SCRIPT
}

# -------------------------------------------------------------------------------
# Function: monitor_kill_switches
# -------------------------------------------------------------------------------
# Description:
#   Monitors kill switch pods and kills debug pods when monitors complete successfully.
#   This function runs in the background during the debug session.
#
# Parameters:
#   None (uses global variables)
#
# Returns:
#   None (runs until stopped or all monitors processed)
# -------------------------------------------------------------------------------
monitor_kill_switches() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local check_interval=1  # Check every 1 second for fast response
  local killed_pods=()

  while true; do
    for monitor_pod in "${KILL_SWITCH_MONITOR_PODS[@]}"; do
      # Skip if we already processed this monitor
      if [[ " ${killed_pods[*]} " == *" $monitor_pod "* ]]; then
        continue
      fi

      # Check monitor pod status
      local pod_status
      if pod_status=$($KUBE_CLI get pod "$monitor_pod" -n "$debug_ns" -o jsonpath='{.status.phase}' 2>/dev/null); then
        if [[ "$pod_status" == "Succeeded" ]]; then
          # Monitor completed - kill switch was triggered
          local target_pod
          if target_pod=$($KUBE_CLI get pod "$monitor_pod" -n "$debug_ns" -o jsonpath='{.metadata.labels.target-pod}' 2>/dev/null); then
            format_message_stderr "🔴 Kill switch triggered by $monitor_pod - terminating debug pod $target_pod"
            $KUBE_CLI delete pod "$target_pod" -n "$debug_ns" --ignore-not-found >/dev/null 2>&1

            # Also clean up the monitor pod
            $KUBE_CLI delete pod "$monitor_pod" -n "$debug_ns" --ignore-not-found >/dev/null 2>&1
          fi
          killed_pods+=("$monitor_pod")
        elif [[ "$pod_status" == "Failed" ]]; then
          format_message_stderr "⚠️  Kill switch monitor $monitor_pod failed - check logs for details"
          killed_pods+=("$monitor_pod")
        fi
      else
        # Monitor pod doesn't exist anymore
        killed_pods+=("$monitor_pod")
      fi
    done

    # Check if parent process still exists
    if ! kill -0 $$ 2>/dev/null; then
      break
    fi

    # Exit if all monitors are processed
    if [[ ${#killed_pods[@]} -ge ${#KILL_SWITCH_MONITOR_PODS[@]} ]]; then
      break
    fi

    sleep "$check_interval"
  done
}

# -------------------------------------------------------------------------------
# Function: cleanup_kill_switch_monitor_pods
# -------------------------------------------------------------------------------
# Description:
#   Cleans up kill switch monitor pods.
#
# Parameters:
#   None (uses global variables)
# -------------------------------------------------------------------------------
cleanup_kill_switch_monitor_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#KILL_SWITCH_MONITOR_PODS[@]} -gt 0 ]]; then
    format_message "🧹 Cleaning up kill switch monitor pods..."
    $KUBE_CLI delete pods "${KILL_SWITCH_MONITOR_PODS[@]}" -n "${debug_ns}" --ignore-not-found >/dev/null 2>&1
  fi
}

# -------------------------------------------------------------------------------
# Function: main
# -------------------------------------------------------------------------------
# Description:
#   Main orchestration function that coordinates the entire debugging workflow.
#   This function manages the complete lifecycle from initialization through
#   execution to cleanup, supporting both pod-based and node-based debugging
#   operations with optional file download capabilities.
#
# Parameters:
#   $@ - All command-line arguments passed to the script
#
# Example Usage:
#   main "$@"
#   This is called automatically at the end of the script with all arguments.
#
# Expected Output:
#   - Complete debugging session output with progress indicators
#   - Network capture or custom command execution results
#   - Optional file downloads from debug sessions
#   - Cleanup status and session completion notification
#
# Detailed Behavior:
#   - Initializes all variables and detects Kubernetes CLI
#   - Parses and validates all command-line arguments
#   - Validates Kubernetes connectivity and permissions
#   - Discovers target pods or nodes based on label selectors
#   - Creates and manages debug pods with privileged access
#   - Monitors debug pod readiness and execution
#   - Optionally creates discovery pods for file operations
#   - Downloads files if file selection commands are provided
#   - Performs cleanup of all created resources (unless disabled)
#   - Reports session completion with appropriate status
# -------------------------------------------------------------------------------
main() {
  # Unified workflow for both pod and node execution
  initialize_variables
  detect_kube_cli
  parse_arguments "$@"

  # Show usage if no arguments provided
  if [[ $# -eq 0 ]]; then
    usage
  fi

  format_message "🔍 Initializing Kubernetes debug session..."
  validate_arguments

  # Show complete configuration
  show_configuration

  # Setup log file if -o (OUTPUT_DIR) is specified
  if [[ -n "$OUTPUT_DIR" ]]; then
    local current_date=$(date '+%Y-%m-%d')
    local epoch_time=$(date '+%s')
    KUBE_DUMP_LOG_FILE="${OUTPUT_DIR}/kube-dump-${current_date}_${epoch_time}.log"
    
    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    # Initialize log file
    echo "=== Kube-dump session started at $(date) ===" > "$KUBE_DUMP_LOG_FILE"
    echo "Command: $0 $*" >> "$KUBE_DUMP_LOG_FILE"
    echo "===============================================" >> "$KUBE_DUMP_LOG_FILE"
  fi

  if [[ "$MOCK_MODE" != "true" ]]; then
    validate_all_requirements
  fi
  echo

  format_message "📋 PHASE 1: Target Selection & Debug Pod Creation"
  format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ "$EXECUTION_MODE" == "pod" ]]; then
    format_message "🎯 Pod-based execution mode"
    echo ""
    if ! select_target_pods; then
      exit 1
    fi

    if ! prepare_target_pods; then
      exit 1
    fi

    echo ""
    format_message "🚀 Creating debug pods for pod targets..."
    if ! create_debug_pods_for_targets; then
      exit 1
    fi
  elif [[ "$EXECUTION_MODE" == "node" ]]; then
    format_message "🎯 Node-based execution mode"
    echo ""
    if ! select_target_nodes; then
      exit 1
    fi

    echo ""
    format_message "🚀 Creating debug pods for node targets..."
    if ! create_node_debug_pods; then
      exit 1
    fi
  elif [[ "$EXECUTION_MODE" == "mixed" ]]; then
    format_message "🎯 Mixed execution mode (pods + nodes)"
    echo ""

    format_message "📦 Handling pod targets..."
    echo ""
    if ! select_target_pods; then
      exit 1
    fi

    if ! prepare_target_pods; then
      exit 1
    fi

    echo ""
    format_message "🖥️  Handling node targets..."
    if ! select_target_nodes; then
      exit 1
    fi

    echo ""
    format_message "🚀 Creating debug pods for pod targets..."
    if ! create_debug_pods_for_targets; then
      exit 1
    fi

    echo ""
    format_message "🚀 Creating debug pods for node targets..."
    if ! create_node_debug_pods; then
      exit 1
    fi
  fi
  echo

  if ! wait_for_debug_pods_ready; then
    exit 1
  fi

  # Create kill switch monitor pods if thresholds are configured
  if [[ -n "$KILL_SWITCH_ABS" || -n "$KILL_SWITCH_REL" ]]; then
    create_kill_switch_monitor_pods

    # Start monitoring kill switches in background
    monitor_kill_switches &
    KILL_SWITCH_MONITOR_PID=$!
  fi

  echo ""
  format_message "✅ PHASE 2: Debug Pods Running - Monitor Output"
  format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  format_message "📊 Debug pods are running with commands in their entrypoints."
  echo ""
  echo ""
  format_message "🔍 Monitor command output with these commands:"
  for debug_pod in "${DEBUG_POD_NAMES[@]}"; do
    echo "   $KUBE_CLI logs ${debug_pod} -n ${DEBUG_NAMESPACE:-${NAMESPACE}} -f"
  done
  echo ""
  format_message "🗑️  Or delete all debug pods manually:"
  echo "   $KUBE_CLI delete pods ${DEBUG_POD_NAMES[*]} -n ${DEBUG_NAMESPACE:-${NAMESPACE}}"
  echo ""
  echo ""

  # Skip cleanup if NO_CLEANUP is set
  if [[ "$NO_CLEANUP" != "true" ]]; then
    # Wait for user input before cleanup
    format_message "⏸️  PHASE 3: Waiting for User Input"
    format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    format_message "🔄 Press Enter to cleanup all debug pods, or Ctrl+C to leave them running..."
    echo ""
    read
    echo

    # Cleanup debug pods FIRST
    format_message "🧹 PHASE 4: Cleaning up Debug Pods"
    format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    format_message "🗑️  Deleting ${#DEBUG_POD_NAMES[@]} debug pods..."
    cleanup_debug_pods
    cleanup_kill_switch_monitor_pods
    format_message "   ✅ All debug pods cleaned up"
    echo

    # Handle file downloads if requested (AFTER debug pods are cleaned up)
    if [[ -n "$OUTPUT_DIR" && (-n "$SELECT_TO_DOWNLOAD_COMMAND" || -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND") ]]; then
      format_message "📥 PHASE 5: File Discovery & Download"
      format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      format_message "🚀 Creating discovery pods for file download..."
      if ! create_file_discovery_pods; then
        format_message "❌ Discovery pod creation failed"
        exit 1
      fi

      handle_file_downloads
      echo
    fi

    echo ""
    format_message "🎉 All operations completed!"
  else
    format_message "⚠️  PHASE 3: No-Cleanup Mode"
    format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    format_message "🔧 Skipping cleanup (--no-cleanup specified)"
    echo

    # Handle file downloads even with --no-cleanup (but don't cleanup debug pods)
    if [[ -n "$OUTPUT_DIR" && (-n "$SELECT_TO_DOWNLOAD_COMMAND" || -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND") ]]; then
      format_message "📥 PHASE 4: File Discovery & Download"
      format_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      format_message "🚀 Creating discovery pods for file download..."
      if ! create_file_discovery_pods; then
        format_message "❌ Discovery pod creation failed"
        return 1
      fi

      handle_file_downloads
      echo
    fi

    echo ""
    format_message "🔧 Debug pods are still running. Use kubectl logs to check their output."
    if [[ ${#KILL_SWITCH_MONITOR_PODS[@]} -gt 0 ]]; then
      format_message "🛡️  Kill switch monitor pods are also running and will auto-terminate debug pods if thresholds are exceeded."
    fi
    echo ""
    format_message "🎉 Session completed!"
  fi
  
  # Close log file if it was created
  if [[ -n "$KUBE_DUMP_LOG_FILE" ]]; then
    echo "===============================================" >> "$KUBE_DUMP_LOG_FILE"
    echo "=== Kube-dump session ended at $(date) ===" >> "$KUBE_DUMP_LOG_FILE"
    format_message "📋 Session log saved to: $KUBE_DUMP_LOG_FILE"
  fi
}

# Call the main function
main "$@"
