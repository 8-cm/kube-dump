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
  echo "  -l, --label          Label selector to find multiple pods (can be specified multiple times for OR logic) [default: dumpme=yes]"
  echo "  -L, --node-label     Label selector to find multiple nodes (can be specified multiple times for OR logic)"
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
  echo "  --kill-switch-rel    Kill pods when free space falls below relative threshold (e.g., 10%) [requires 'bc' in image]"
  echo "  --pod-volume         Volume path to monitor for pod-based kill switches (e.g., /tmp)"
  echo "  --node-volume        Volume path to monitor for node-based kill switches (e.g., /var)"
  echo "  --image              Container image for debug/discovery/killswitch pods [default: nicolaka/netshoot]"
  echo "  --no-glyphs          Disable emojis and use text labels like [INFO], [ERROR], [OK]"
  echo "  --verbose            Enable verbose logging (max k8s verbosity, per-pod logs to OUTPUT_DIR/debug/)"
  echo "  -h, --help           Show this help message and exit"
  echo ""
  echo "Examples:"
  echo "  # Use defaults (dumpme=yes label, tcpdump -i any -nn -s 0):"
  echo "  $0"
  echo ""
  echo "  # Capture traffic from all pods with app=nginx label:"
  echo "  $0 -l app=nginx"
  echo ""
  echo "  # Capture from pods with multiple labels (AND logic within selector):"
  echo "  $0 -l 'tier=frontend,env=prod'"
  echo ""
  echo "  # Capture from pods matching ANY of multiple label selectors (OR logic):"
  echo "  $0 -l app=nginx -l app=apache -l app=httpd"
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
  echo "  # Run command on nodes matching ANY of multiple label selectors (OR logic):"
  echo "  $0 -L zone=us-west -L zone=us-east -E 'ss -tuln'"
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
  echo "  $0 -l app=web --image alpine:latest"
  echo ""
  echo "  # Enable verbose logging with max Kubernetes verbosity (requires -o):"
  echo "  $0 -l app=web -o ./output --verbose"
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
  POD_LABELS=("dumpme=yes")  # Array of label selectors for finding pods (OR logic)
  POD_LABEL_EXPLICIT=false  # Track if POD_LABELS was explicitly set by user
  NODE_NAMES=()  # Array for discovered nodes
  NODE_LABELS=()  # Array of label selectors for finding nodes (OR logic)
  NODE_COMMAND="tcpdump -i any -nn -s 0"  # Default tcpdump command (same as pod mode)
  CUSTOM_NODE_COMMAND=""  # Custom command from -E
  SELECT_TO_DOWNLOAD_COMMAND=""  # Command to list files to download from -s
  NODE_SELECT_TO_DOWNLOAD_COMMAND=""  # Command to list files to download from -S
  ENCODED_SELECT_COMMAND=""  # Base64 encoded select command
  ENCODED_NODE_SELECT_COMMAND=""  # Base64 encoded node select command
  OUTPUT_DIR=""  # Output directory for downloaded files from -o
  PLACEHOLDER_CHAR="%"  # Default placeholder character for hostname substitution
  DISCOVERY_POD_NAMES=()  # Array for file discovery pods
  DISCOVERY_POD_INFO=()  # Array to track discovery pod info: "discovery_pod_name:node_name:type:target_name"
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
  DEBUG_IMAGE="nicolaka/netshoot"  # Default container image for debug/discovery/killswitch pods
  KILL_SWITCH_MONITOR_PODS=()  # Array for kill switch monitor pods
  KUBE_CLI=""  # Will be set to 'oc' or '$KUBE_CLI' based on availability
  VERBOSE="false"  # Default: disable verbose logging
  DEBUG_LOG_DIR=""  # Directory for verbose logs (created as OUTPUT_DIR/debug)
}

# -------------------------------------------------------------------------------
# Function: detect_kube_cli
# -------------------------------------------------------------------------------
# Description:
#   Detects and configures the appropriate Kubernetes command-line interface (CLI)
#   tool to use for the script. This function first checks for OpenShift CLI (oc),
#   then falls back to the standard kubectl if oc is not available. It sets the
#   global KUBE_CLI variable and provides user feedback about which CLI is being used.
#
# Parameters:
#   None.
#
# Example Usage:
#   detect_kube_cli
#   # This will detect the CLI and set KUBE_CLI variable
#
# Expected Output:
#   - Sets KUBE_CLI global variable to either "oc" or "kubectl"
#   - Prints informational message to stderr indicating which CLI is being used
#   - Exits with status 1 if no compatible CLI is found
#
# Detailed Behavior:
#   - First checks if 'oc' (OpenShift CLI) is available in PATH
#   - If oc is found, sets KUBE_CLI="oc" and notifies user via stderr
#   - If oc is not found, checks if kubectl is available in PATH
#   - If kubectl is found, sets KUBE_CLI="kubectl" and notifies user via stderr
#   - If neither CLI is available, prints error message and exits with status 1
#   - This function must be called early in script execution to ensure proper CLI setup
# -------------------------------------------------------------------------------
detect_kube_cli() {
  if command -v oc >/dev/null 2>&1; then
    KUBE_CLI="oc"
    echo "Using OpenShift CLI (oc)" >&2
  elif command -v "$KUBE_CLI" >/dev/null 2>&1; then
    echo "Using Kubernetes CLI ($KUBE_CLI)" >&2
  else
    echo "Error: Neither 'oc' nor '$KUBE_CLI' found in PATH" >&2
    exit 1
  fi
}

# -------------------------------------------------------------------------------
# Function: validate_option_value
# -------------------------------------------------------------------------------
# Description:
#   Validates that a command-line option has been provided with a proper value.
#   This function ensures that options requiring values are not left empty or
#   accidentally given another option (starting with '-') as their value. It
#   provides user-friendly error messages and displays usage information when
#   validation fails.
#
# Parameters:
#   $1 (val): The value to validate - should be the argument following an option
#   $2 (option_name): The name of the option being validated (for error messages)
#
# Example Usage:
#   validate_option_value "$2" "-l"
#   validate_option_value "$OPTARG" "--namespace"
#   # These calls check if the provided value is valid for the given option
#
# Expected Output:
#   - No output if validation passes
#   - Error message to stderr if validation fails
#   - Calls usage() and exits if validation fails
#
# Detailed Behavior:
#   - Checks if the provided value is empty (zero-length string)
#   - Checks if the provided value starts with '-' (indicating it's likely another option)
#   - If either condition is true, considers it a validation failure
#   - On failure, prints descriptive error message identifying the problematic option
#   - Calls usage() function to display help information and terminate script
#   - This function is critical for preventing malformed command-line parsing
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
# Function: truncate_name_with_hash
# -------------------------------------------------------------------------------
# Description:
#   Ensures a Kubernetes resource name does not exceed 253 characters (DNS subdomain
#   limit per RFC 1123). If the name is too long, it truncates it and appends a
#   hash of the original name to maintain uniqueness.
#
# Parameters:
#   $1 (name): The name to validate and potentially truncate
#
# Example Usage:
#   safe_name=$(truncate_name_with_hash "very-long-node-name-debug-12345678-1234567890")
#
# Expected Output:
#   - Returns the original name if it's 253 characters or less
#   - Returns truncated name with 8-char hash suffix if longer
#
# Detailed Behavior:
#   - Checks if name length exceeds 253 characters
#   - If too long, generates 8-character hash of the full name
#   - Truncates to (253 - 9) = 244 chars and appends "-{hash}"
#   - Uses md5sum, md5, or cksum depending on platform availability
# -------------------------------------------------------------------------------
truncate_name_with_hash() {
  local name="$1"
  local max_length=253

  if [[ ${#name} -le $max_length ]]; then
    echo "$name"
    return
  fi

  # Generate hash of full name for uniqueness
  local name_hash
  if command -v md5sum &>/dev/null; then
    name_hash=$(echo "$name" | md5sum | cut -c1-8)
  elif command -v md5 &>/dev/null; then
    name_hash=$(echo "$name" | md5 | cut -c1-8)
  else
    name_hash=$(echo "$name" | cksum | cut -d' ' -f1 | cut -c1-8)
  fi

  # Truncate to fit: max_length - 1 (dash) - 8 (hash)
  local truncate_to=$((max_length - 9))
  local truncated="${name:0:$truncate_to}"

  echo "${truncated}-${name_hash}"
}

# -------------------------------------------------------------------------------
# Function: truncate_label_value_with_hash
# -------------------------------------------------------------------------------
# Description:
#   Ensures a Kubernetes label value does not exceed 63 characters. If the value
#   is too long, it truncates it and appends a hash of the original value to
#   maintain uniqueness.
#
# Parameters:
#   $1 (value): The label value to validate and potentially truncate
#
# Example Usage:
#   safe_label=$(truncate_label_value_with_hash "very-long-node-name-that-exceeds-limits")
#
# Expected Output:
#   - Returns the original value if it's 63 characters or less
#   - Returns truncated value with 8-char hash suffix if longer
#
# Detailed Behavior:
#   - Checks if value length exceeds 63 characters
#   - If too long, generates 8-character hash of the full value
#   - Truncates to (63 - 9) = 54 chars and appends "-{hash}"
#   - Uses md5sum, md5, or cksum depending on platform availability
# -------------------------------------------------------------------------------
truncate_label_value_with_hash() {
  local value="$1"
  local max_length=63

  if [[ ${#value} -le $max_length ]]; then
    echo "$value"
    return
  fi

  # Generate hash of full value for uniqueness
  local value_hash
  if command -v md5sum &>/dev/null; then
    value_hash=$(echo "$value" | md5sum | cut -c1-8)
  elif command -v md5 &>/dev/null; then
    value_hash=$(echo "$value" | md5 | cut -c1-8)
  else
    value_hash=$(echo "$value" | cksum | cut -d' ' -f1 | cut -c1-8)
  fi

  # Truncate to fit: max_length - 1 (dash) - 8 (hash)
  local truncate_to=$((max_length - 9))
  local truncated="${value:0:$truncate_to}"

  echo "${truncated}-${value_hash}"
}

# -------------------------------------------------------------------------------
# Function: setup_debug_logging
# -------------------------------------------------------------------------------
# Description:
#   Sets up the debug logging directory when --verbose flag is enabled. Creates
#   a 'debug' subdirectory inside the output directory specified by -o flag.
#   This function should be called after OUTPUT_DIR is set and before any
#   operations that need verbose logging.
#
# Parameters:
#   None. (Uses global OUTPUT_DIR and VERBOSE variables)
#
# Example Usage:
#   setup_debug_logging
#
# Expected Output:
#   - Sets DEBUG_LOG_DIR to OUTPUT_DIR/debug if VERBOSE=true
#   - Creates the debug directory if it doesn't exist
#   - Returns 0 on success, 1 on failure
#
# Detailed Behavior:
#   - Only acts if VERBOSE is true
#   - Requires OUTPUT_DIR to be set (via -o flag)
#   - Creates nested directory structure if needed
#   - Prints error message if directory creation fails
# -------------------------------------------------------------------------------
setup_debug_logging() {
  if [[ "$VERBOSE" != "true" ]]; then
    return 0
  fi

  if [[ -z "$OUTPUT_DIR" ]]; then
    echo "Error: --verbose requires -o (output directory) to be specified" >&2
    return 1
  fi

  DEBUG_LOG_DIR="${OUTPUT_DIR}/debug"

  if ! mkdir -p "$DEBUG_LOG_DIR" 2>/dev/null; then
    echo "Error: Failed to create debug log directory: $DEBUG_LOG_DIR" >&2
    return 1
  fi

  format_message "📋 Verbose logging enabled: $DEBUG_LOG_DIR"
  return 0
}

# -------------------------------------------------------------------------------
# Function: get_pod_log_file
# -------------------------------------------------------------------------------
# Description:
#   Generates the log file path for a specific pod and operation. Returns
#   different paths for stdout and stderr, or empty string if verbose logging
#   is disabled.
#
# Parameters:
#   $1 (pod_name): Name of the pod
#   $2 (operation): Operation type (e.g., "create", "exec", "logs", "cp")
#   $3 (stream): Either "stdout" or "stderr"
#
# Example Usage:
#   stdout_log=$(get_pod_log_file "debug-pod-123" "create" "stdout")
#   stderr_log=$(get_pod_log_file "debug-pod-123" "exec" "stderr")
#
# Expected Output:
#   - Returns path like: /output/debug/debug-pod-123.create.stdout.log
#   - Returns empty string if VERBOSE is false
#
# Detailed Behavior:
#   - Checks if VERBOSE is enabled
#   - Constructs log file path with pod name, operation, and stream type
#   - Returns empty string if verbose logging is disabled
# -------------------------------------------------------------------------------
get_pod_log_file() {
  local pod_name="$1"
  local operation="$2"
  local stream="$3"

  if [[ "$VERBOSE" != "true" || -z "$DEBUG_LOG_DIR" ]]; then
    echo ""
    return
  fi

  echo "${DEBUG_LOG_DIR}/${pod_name}.${operation}.${stream}.log"
}

# -------------------------------------------------------------------------------
# Function: run_kube_cmd
# -------------------------------------------------------------------------------
# Description:
#   Wrapper function for kubectl/oc commands that adds verbose logging when
#   enabled. Captures stdout and stderr to separate log files per pod and
#   operation, and uses maximum Kubernetes verbosity level (--v=10).
#
# Parameters:
#   $1 (pod_name): Name of the pod for logging (use "global" for non-pod operations)
#   $2 (operation): Operation type (e.g., "create", "apply", "exec", "get", "delete")
#   $@ (remaining): The kubectl/oc command arguments
#
# Example Usage:
#   run_kube_cmd "debug-pod-123" "create" apply -f - <<EOF ... EOF
#   run_kube_cmd "debug-pod-123" "exec" exec debug-pod-123 -n default -- ls
#   run_kube_cmd "global" "get" get pods -n default
#
# Expected Output:
#   - Executes the command with or without verbose logging based on VERBOSE flag
#   - When VERBOSE=true: adds --v=10 and redirects stdout/stderr to log files
#   - Returns the exit code of the command
#
# Detailed Behavior:
#   - If VERBOSE=false: executes command normally without logging
#   - If VERBOSE=true:
#     * Adds --v=10 to kubectl/oc commands (max verbosity)
#     * Redirects stdout to: DEBUG_LOG_DIR/{pod_name}.{operation}.stdout.log
#     * Redirects stderr to: DEBUG_LOG_DIR/{pod_name}.{operation}.stderr.log
#     * Appends to log files (doesn't overwrite)
#   - Preserves command exit code
# -------------------------------------------------------------------------------
run_kube_cmd() {
  local pod_name="$1"
  local operation="$2"
  shift 2

  if [[ "$VERBOSE" != "true" ]]; then
    # No verbose logging, run command normally
    $KUBE_CLI "$@"
    return $?
  fi

  # Verbose logging enabled
  local stdout_log
  local stderr_log
  stdout_log=$(get_pod_log_file "$pod_name" "$operation" "stdout")
  stderr_log=$(get_pod_log_file "$pod_name" "$operation" "stderr")

  # Add timestamp to logs
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') - $operation ===" >> "$stdout_log"
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') - $operation ===" >> "$stderr_log"

  # Run command with max verbosity and redirect output
  # Use tee to send output to both log file and stdout so callers can capture it
  $KUBE_CLI --v=10 "$@" 2>> "$stderr_log" | tee -a "$stdout_log"
  local exit_code=${PIPESTATUS[0]}

  # Log completion
  echo "=== Completed with exit code: $exit_code ===" >> "$stdout_log"
  echo "=== Completed with exit code: $exit_code ===" >> "$stderr_log"
  echo "" >> "$stdout_log"
  echo "" >> "$stderr_log"

  return $exit_code
}

# -------------------------------------------------------------------------------
# Function: format_message
# -------------------------------------------------------------------------------
# Description:
#   Formats output messages by conditionally replacing Unicode emoji glyphs with
#   ASCII text equivalents when NO_GLYPHS is enabled. This function also handles
#   logging to a file when output directory is specified. It ensures consistent
#   message formatting across the entire script while supporting both visual
#   (emoji) and text-only display modes for different terminal environments.
#
# Parameters:
#   $1 (message): The message string to format, potentially containing emoji glyphs
#
# Example Usage:
#   format_message "🔍 Searching for pods..."
#   format_message "✅ Debug pod created successfully"
#   # These will output formatted messages and optionally log them
#
# Expected Output:
#   - Formatted message printed to stdout
#   - If NO_GLYPHS=true, emojis are replaced with [TEXT] equivalents
#   - If OUTPUT_DIR is set, message is also logged to KUBE_DUMP_LOG_FILE with timestamp
#
# Detailed Behavior:
#   - Checks NO_GLYPHS global variable to determine formatting mode
#   - If NO_GLYPHS is true, performs comprehensive emoji-to-text substitution:
#     * 🔍 → [SEARCH], 🔧 → [SETUP], 🛡️ → [SECURITY], ✅ → [OK]
#     * 🔴 → [KILL], ❌ → [ERROR], 🟢 → [SUCCESS], ⚠️ → [WARNING]
#     * 📋 → [INFO], 🔄 → [PROGRESS], 📥 → [DOWNLOAD], 📂 → [DIR], 🚫 → [BLOCKED]
#     * 💾 → [STORAGE], ⏳ → [WAITING], 🖥️ → [NODE], ℹ️ → [INFO]
#     * ⏸️ → [PAUSE], 🗑️ → [CLEANUP], 📦 → [POD], 🧹 → [CLEAN]
#     * 🚀 → [LAUNCH], 🎯 → [TARGET], 📊 → [STATUS], 🎉 → [COMPLETE]
#     * ➕ → [+], • → * (bullet point)
#     * ━ → = (converts Unicode box drawing to ASCII)
#   - Prints formatted message to stdout
#   - If OUTPUT_DIR and KUBE_DUMP_LOG_FILE are set, appends timestamped entry to log file
#   - This function is the primary output handler for user-visible messages
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
    message="${message//📂/[DIR]}"
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
    message="${message//➕/[+]}"
    message="${message//•/*}"
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
# Description:
#   Formats and outputs messages to standard error (stderr) with conditional
#   emoji-to-text conversion when NO_GLYPHS is enabled. This function mirrors
#   the functionality of format_message() but directs output to stderr for
#   error messages, warnings, and informational content that should not interfere
#   with primary script output. It also provides logging capabilities.
#
# Parameters:
#   $1 (message): The message string to format and send to stderr, potentially containing emoji glyphs
#
# Example Usage:
#   format_message_stderr "⚠️ Warning: Debug pod already exists"
#   format_message_stderr "❌ Error: Failed to create pod"
#   # These will output formatted messages to stderr and optionally log them
#
# Expected Output:
#   - Formatted message printed to stderr (file descriptor 2)
#   - If NO_GLYPHS=true, emojis are replaced with [TEXT] equivalents
#   - If OUTPUT_DIR is set, message is also logged to KUBE_DUMP_LOG_FILE with "STDERR:" prefix
#
# Detailed Behavior:
#   - Performs identical emoji-to-text substitution as format_message() when NO_GLYPHS is true
#   - Applies the same comprehensive glyph replacement mapping:
#     * 🔍 → [SEARCH], 🔧 → [SETUP], 🛡️ → [SECURITY], ✅ → [OK]
#     * 🔴 → [KILL], ❌ → [ERROR], 🟢 → [SUCCESS], ⚠️ → [WARNING]
#     * 📋 → [INFO], 🔄 → [PROGRESS], 📥 → [DOWNLOAD], 📂 → [DIR], 🚫 → [BLOCKED]
#     * 💾 → [STORAGE], ⏳ → [WAITING], 🖥️ → [NODE], ℹ️ → [INFO]
#     * ⏸️ → [PAUSE], 🗑️ → [CLEANUP], 📦 → [POD], 🧹 → [CLEAN]
#     * 🚀 → [LAUNCH], 🎯 → [TARGET], 📊 → [STATUS], 🎉 → [COMPLETE]
#     * ➕ → [+], • → * (bullet point)
#     * ━ → = (converts Unicode box drawing to ASCII)
#   - Outputs formatted message to stderr using >&2 redirection
#   - If OUTPUT_DIR and KUBE_DUMP_LOG_FILE are set, appends timestamped entry with "STDERR:" prefix
#   - This function is used for error handling, warnings, and informational messages
#   - Ensures error messages don't mix with primary script output that may be piped or redirected
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
    message="${message//📂/[DIR]}"
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
    message="${message//➕/[+]}"
    message="${message//•/*}"
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
# Description:
#   Determines the appropriate Container Runtime Interface (CRI) socket path to use
#   for container operations. This function provides runtime-specific socket paths
#   for different container runtimes (containerd, CRI-O, Docker) and allows for
#   custom socket paths when explicitly specified. It serves as the authoritative
#   source for CRI socket configuration throughout the script.
#
# Parameters:
#   None.
#
# Example Usage:
#   socket_path=$(get_effective_cri_socket)
#   crictl_socket="--runtime-endpoint=$(get_effective_cri_socket)"
#   # These will return the appropriate CRI socket path for the current runtime
#
# Expected Output:
#   - Returns the full absolute path to the CRI socket
#   - Custom path if CRI_SOCKET is set by user
#   - Runtime-specific default path if CRI_SOCKET is not set
#
# Detailed Behavior:
#   - First checks if CRI_SOCKET global variable is set (custom user-provided path)
#   - If CRI_SOCKET is set, returns that path without modification
#   - If CRI_SOCKET is not set, determines path based on CRI_RUNTIME variable:
#     * "containerd": Returns "/run/containerd/containerd.sock"
#     * "crio": Returns "/run/crio/crio.sock"
#     * "docker": Returns "/var/run/cri-dockerd.sock"
#     * Any other value: Defaults to "/run/containerd/containerd.sock"
#   - These paths represent the standard socket locations for each container runtime
#   - The returned path is used by crictl and other container runtime commands
#   - This function ensures consistent CRI socket configuration across all operations
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
# Description:
#   Displays a comprehensive summary of the current script configuration including
#   all operational settings, command parameters, runtime options, and feature flags.
#   This function provides users with a clear view of how the script will execute
#   before any actual operations begin, enabling configuration validation and debugging.
#
# Parameters:
#   None.
#
# Example Usage:
#   show_configuration
#   # This will display all current configuration settings in formatted output
#
# Expected Output:
#   - Formatted configuration summary with section headers
#   - Shows execution mode (pod or node)
#   - Lists Kubernetes CLI being used (oc or kubectl)
#   - Displays pod and node selection criteria
#   - Shows commands that will be executed
#   - Lists container runtime settings
#   - Shows file operation parameters
#   - Displays kill switch configuration
#   - Lists all boolean option flags
#
# Detailed Behavior:
#   - Uses format_message() for consistent header formatting with emoji support
#   - Displays configuration in organized sections: Pod Selection, Node Selection, Commands, etc.
#   - Shows both set and unset values, with "(not set)" or "(current/default)" indicators
#   - For commands, shows custom commands if set, otherwise shows defaults
#   - Calls get_effective_cri_socket() to show the actual CRI socket that will be used
#   - Uses consistent formatting with section separators and indented sub-items
#   - Provides visual confirmation of all script parameters before execution
# -------------------------------------------------------------------------------
show_configuration() {
  echo ""
  format_message "📋 Configuration Summary:"
  echo "=================================================="
  echo "Execution Mode:      $EXECUTION_MODE"
  echo "Kubernetes CLI:      $KUBE_CLI"
  echo ""
  echo "Pod Selection:"
  if [[ ${#POD_LABELS[@]} -eq 0 ]]; then
    echo "  Label Selectors:   (not set)"
  elif [[ ${#POD_LABELS[@]} -eq 1 ]]; then
    echo "  Label Selector:    ${POD_LABELS[0]}"
  else
    echo "  Label Selectors:   (OR logic)"
    for label in "${POD_LABELS[@]}"; do
      if [[ "$NO_GLYPHS" == "true" ]]; then
        echo "                     * $label"
      else
        echo "                     • $label"
      fi
    done
  fi
  echo "  Namespace:         ${DEBUG_NAMESPACE:-"(current/default)"}"
  echo ""
  echo "Node Selection:"
  if [[ ${#NODE_LABELS[@]} -eq 0 ]]; then
    echo "  Node Labels:       (not set)"
  elif [[ ${#NODE_LABELS[@]} -eq 1 ]]; then
    echo "  Node Label:        ${NODE_LABELS[0]}"
  else
    echo "  Node Labels:       (OR logic)"
    for label in "${NODE_LABELS[@]}"; do
      if [[ "$NO_GLYPHS" == "true" ]]; then
        echo "                     * $label"
      else
        echo "                     • $label"
      fi
    done
  fi
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
  echo "=================================================="
  echo ""
}

# -------------------------------------------------------------------------------
# Function: validate_variable
# -------------------------------------------------------------------------------
# Description:
#   Performs comprehensive validation of script variables based on specified validation
#   types and constraints. This function ensures that all critical script parameters
#   meet their requirements before script execution proceeds. It supports multiple
#   validation types including enums, booleans, arrays, and strings with customizable
#   requirements for each variable.
#
# Parameters:
#   $1 (var_name): The name of the variable being validated (for error messages)
#   $2 (var_value): The actual value of the variable to validate
#   $3 (validation_type): Type of validation - "enum", "boolean", "array", or "string"
#   $4 (allowed_values): Comma-separated list of allowed values (for enum type)
#   $5 (is_required): "true" if variable is required, any other value means optional
#
# Example Usage:
#   validate_variable "CRI_RUNTIME" "$CRI_RUNTIME" "enum" "containerd,crio,docker" "true"
#   validate_variable "NO_CLEANUP" "$NO_CLEANUP" "boolean" "" "false"
#   validate_variable "POD_NAMES" "POD_NAMES" "array" "" "false"
#
# Expected Output:
#   - No output if validation passes
#   - Error message to stderr and exits with status 1 if validation fails
#
# Detailed Behavior:
#   - First checks if variable is required but empty, exits on failure
#   - Skips further validation if variable is empty and not required
#   - Performs type-specific validation:
#     * enum: Checks if value is in comma-separated allowed_values list
#     * boolean: Ensures value is exactly "true" or "false"
#     * array: Verifies the array variable is properly declared
#     * string: Basic string validation (extensible)
#   - For enum validation, splits allowed_values on commas and checks each
#   - Provides descriptive error messages including variable name and constraints
#   - Exits script immediately on validation failure to prevent invalid execution
#   - This function is critical for ensuring script stability and preventing runtime errors
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
# Description:
#   Parses all command-line arguments and options provided to the script, setting
#   appropriate global variables for each option. This function handles both short
#   and long argument formats, validates argument values, and manages complex
#   option interactions. It supports GNU-style long options with equals syntax
#   (--option=value) as well as traditional space-separated arguments.
#
# Parameters:
#   $@ (all arguments): All command-line arguments passed to the script
#
# Example Usage:
#   parse_arguments "$@"
#   # This processes all command-line arguments and sets global variables
#
# Expected Output:
#   - No output if all arguments are valid
#   - Error messages to stderr and usage display for invalid arguments
#   - Sets numerous global variables based on parsed options
#
# Detailed Behavior:
#   - Iterates through all provided arguments using a while loop
#   - Handles two argument formats: --option=value and --option value (or -o value)
#   - Supports extensive option set including:
#     * -l/--label: Pod label selector for targeting pods
#     * -L/--node-label: Node label selector for targeting nodes
#     * -n/--namespace: Kubernetes namespace specification
#     * -e/--execute: Custom command to execute in debug pods
#     * -E/--node-execute: Custom command to execute on nodes
#     * -s/--select-to-download: Command to list files for download from pods
#     * -S/--node-select-to-download: Command to list files for download from nodes
#     * -o/--output-dir: Output directory for downloaded files
#     * --to-namespace: Target namespace for debug pod creation
#     * --cri-runtime: Container runtime interface (containerd, crio, docker)
#     * --cri-socket: Custom CRI socket path
#     * --image: Debug container image to use
#     * --install-deps: Automatic dependency installation flag
#     * --no-cleanup: Disable debug pod cleanup
#     * --include-nodes: Include nodes with selected pods
#     * --kill-switch-*: Various kill switch threshold options
#     * --pod-volume/--node-volume: Volume paths to monitor
#     * --placeholder-char: Hostname substitution character
#     * --no-glyphs: Disable emoji output
#     * -h/--help: Display usage information
#   - Validates option values using validate_option_value() function
#   - Manages complex option interactions (e.g., clearing default pod labels when node-only targeting)
#   - Handles Base64 encoding for custom commands to preserve special characters
#   - Sets execution mode based on which types of targets are specified
#   - Shifts arguments appropriately for space-separated option-value pairs
#   - Provides comprehensive error handling with descriptive messages
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
          # On first explicit -l, clear default and add new value
          if [[ "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABELS=()
          fi
          POD_LABELS+=("$val")
          POD_LABEL_EXPLICIT=true
        else
          validate_option_value "$val" "-l|--label"
          # On first explicit -l, clear default and add new value
          if [[ "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABELS=()
          fi
          POD_LABELS+=("$val")
          POD_LABEL_EXPLICIT=true
          shift
        fi
        ;;
      -L|--node-label)
        if [[ $1 == --node-label=* ]]; then
          NODE_LABELS+=("$val")
          # Clear default pod labels if only node targeting is intended (not explicitly set)
          if [[ -z "$CUSTOM_COMMAND" && ${#POD_LABELS[@]} -eq 1 && "${POD_LABELS[0]}" == "dumpme=yes" && "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABELS=()
          fi
        else
          validate_option_value "$val" "-L|--node-label"
          NODE_LABELS+=("$val")
          # Clear default pod labels if only node targeting is intended (not explicitly set)
          if [[ -z "$CUSTOM_COMMAND" && ${#POD_LABELS[@]} -eq 1 && "${POD_LABELS[0]}" == "dumpme=yes" && "$POD_LABEL_EXPLICIT" == "false" ]]; then
            POD_LABELS=()
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
      --verbose)
        VERBOSE=true
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
# Description:
#   Validates the complete set of parsed command-line arguments and determines the
#   execution mode based on provided options. This function performs comprehensive
#   validation of all script parameters, checks for required argument combinations,
#   validates mutually exclusive options, and ensures that all dependencies between
#   options are satisfied. It serves as the final argument validation before script execution.
#
# Parameters:
#   None. (Uses global variables set by parse_arguments)
#
# Example Usage:
#   validate_arguments
#   # This validates all global variables set during argument parsing
#
# Expected Output:
#   - No output if validation passes
#   - Error messages to stderr and returns 1 if validation fails
#   - Sets EXECUTION_MODE global variable ("pod", "node", or "mixed")
#
# Detailed Behavior:
#   - Determines execution mode based on which options are provided:
#     * "pod": Only pod-related options specified (default mode)
#     * "node": Only node-related options specified
#     * "mixed": Both pod and node options, or pod options with --include-nodes
#   - Validates execution mode using validate_variable with enum constraint
#   - For pod/mixed modes: validates POD_LABEL, CAPTURE_COMMAND, CUSTOM_COMMAND
#   - For node/mixed modes: validates NODE_COMMAND, CUSTOM_NODE_COMMAND, NODE_LABEL
#   - Handles special case for --include-nodes where NODE_LABEL is optional
#   - Validates --include-nodes requires -E/--node-execute for command specification
#   - Validates core configuration: DEBUG_NAMESPACE, CRI_RUNTIME, INSTALL_DEPS
#   - Validates file download options: SELECT_TO_DOWNLOAD_COMMAND, NODE_SELECT_TO_DOWNLOAD_COMMAND, OUTPUT_DIR
#   - Validates file download dependencies: -s/-S options require -o/--output-dir
#   - Validates kill switch arguments: KILL_SWITCH_ABS, KILL_SWITCH_REL
#   - Ensures kill switch mutual exclusivity (absolute vs relative thresholds)
#   - Validates kill switch volume dependencies based on execution mode:
#     * Pod mode requires --pod-volume
#     * Node mode requires --node-volume
#     * Mixed mode requires both --pod-volume and --node-volume
#   - Uses validate_variable() for type-specific validation (enum, boolean, string)
#   - Returns non-zero exit status for validation failures
#   - This function ensures all argument combinations are logically consistent
# -------------------------------------------------------------------------------
validate_arguments() {
  # Determine execution mode based on what options are provided
  local has_pod_options=false
  local has_node_options=false

  if [[ ${#POD_LABELS[@]} -gt 0 ]]; then
    has_pod_options=true
  fi

  if [[ ${#NODE_LABELS[@]} -gt 0 ]]; then
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
    # Validate that POD_LABELS array has at least one element
    if [[ ${#POD_LABELS[@]} -eq 0 ]]; then
      echo "Error: No pod label selectors provided" >&2
      return 1
    fi
    validate_variable "CAPTURE_COMMAND" "$CAPTURE_COMMAND" "string" "" "true"
    validate_variable "CUSTOM_COMMAND" "$CUSTOM_COMMAND" "string" "" "false"
  fi

  if [[ "$EXECUTION_MODE" == "node" || "$EXECUTION_MODE" == "mixed" ]]; then
    validate_variable "NODE_COMMAND" "$NODE_COMMAND" "string" "" "true"
    validate_variable "CUSTOM_NODE_COMMAND" "$CUSTOM_NODE_COMMAND" "string" "" "false"

    # For mixed mode triggered by --include-nodes, NODE_LABELS is optional
    if [[ "$EXECUTION_MODE" == "mixed" && "$INCLUDE_NODES" == "true" && ${#NODE_LABELS[@]} -eq 0 ]]; then
      # --include-nodes case: NODE_LABELS is not required
      :
    else
      # Validate that NODE_LABELS array has at least one element
      if [[ ${#NODE_LABELS[@]} -eq 0 ]]; then
        echo "Error: No node label selectors provided" >&2
        return 1
      fi
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

  # Execution mode and command details are shown in configuration summary
}

# -------------------------------------------------------------------------------
# Function: select_target_pods
# -------------------------------------------------------------------------------
# Description:
#   Selects and prepares target pods for debugging operations based on label selectors.
#   This function determines the appropriate debug namespace, validates label selector
#   requirements, and delegates to find_pods_by_label() to discover matching pods.
#   It serves as the entry point for pod selection in the debugging workflow.
#
# Parameters:
#   None. (Uses global variables POD_LABEL and DEBUG_NAMESPACE)
#
# Example Usage:
#   select_target_pods
#   # This will find pods matching POD_LABEL and set up DEBUG_NAMESPACE
#
# Expected Output:
#   - Sets DEBUG_NAMESPACE if not already specified
#   - Calls find_pods_by_label() to populate POD_NAMES array
#   - Returns 0 on success, 1 on error
#
# Detailed Behavior:
#   - Determines debug namespace using kubectl config if DEBUG_NAMESPACE is empty
#   - Falls back to "default" namespace if no namespace is configured
#   - Validates that POD_LABEL is provided (required for pod selection)
#   - Calls find_pods_by_label() to perform actual pod discovery
#   - This function is called during the pod selection phase of the workflow
#   - Sets up the foundation for subsequent pod debugging operations
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
  if [[ ${#POD_LABELS[@]} -eq 0 ]]; then
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
# Description:
#   Prepares discovered target pods for debugging by extracting detailed pod information
#   and building the TARGET_PODS array with structured pod data. This function processes
#   the POD_NAMES array and enriches it with container and namespace information needed
#   for debug pod creation and command execution.
#
# Parameters:
#   None. (Uses global POD_NAMES array populated by find_pods_by_label)
#
# Example Usage:
#   prepare_target_pods
#   # This processes POD_NAMES and populates TARGET_PODS array
#
# Expected Output:
#   - Populates TARGET_PODS array with structured pod information
#   - Progress messages indicating pod preparation status
#   - Each entry format: "pod_name:container_name:node_name:namespace"
#
# Detailed Behavior:
#   - Iterates through each pod in POD_NAMES array
#   - Extracts pod name, container name, node name, and namespace for each pod
#   - Uses kubectl/oc commands to gather additional pod metadata
#   - Builds TARGET_PODS array entries in structured format for later use
#   - Provides progress feedback during the preparation process
#   - This prepared data is used by create_debug_pods_for_targets() function
#   - Handles cases where pods may have multiple containers
# -------------------------------------------------------------------------------
prepare_target_pods() {
  format_message "🔧 Preparing target pods for debugging..."

  for pod_info in "${POD_NAMES[@]}"; do
    local pod_name
    local containers
    local node_name
    local pod_namespace
    pod_name=$(echo "$pod_info" | cut -d':' -f1)
    containers=$(echo "$pod_info" | cut -d':' -f2)
    node_name=$(echo "$pod_info" | cut -d':' -f3)
    pod_namespace=$(echo "$pod_info" | cut -d':' -f4)

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
    local target_container
    target_container=$(echo "$containers" | awk '{print $1}')
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
# Description:
#   Selects target nodes for debug pod creation based on node label selectors and
#   optional inclusion of nodes hosting selected pods. This function queries the
#   Kubernetes cluster for nodes matching the specified criteria and populates
#   both NODE_NAMES and TARGET_NODES arrays for subsequent processing.
#
# Parameters:
#   Uses global variables:
#     $NODE_LABEL    - Label selector string for finding nodes (e.g., "worker=true")
#     $INCLUDE_NODES - Boolean flag to include nodes hosting selected pods
#     $TARGET_PODS[] - Array of selected pods (used when INCLUDE_NODES is true)
#     $KUBE_CLI      - Kubernetes CLI command (kubectl/oc)
#   Modifies global arrays:
#     NODE_NAMES[]   - Names of nodes selected by label selector
#     TARGET_NODES[] - All target nodes (label-selected + pod-hosting nodes)
#
# Example Usage:
#   NODE_LABEL="node-role.kubernetes.io/worker=true"
#   select_target_nodes
#   # Finds all worker nodes and adds them to TARGET_NODES
#
#   NODE_LABEL="zone=us-west"
#   INCLUDE_NODES="true"
#   select_target_nodes
#   # Finds nodes with zone=us-west label AND nodes hosting selected pods
#
# Expected Output:
#   - Progress messages showing node discovery process
#   - List of found nodes with visual indicators
#   - Success confirmation with node count
#   - Additional nodes notification when --include-nodes is used
#   - Returns 0 on success, 1 on error
#
# Detailed Behavior:
#   1. Queries Kubernetes API for nodes matching NODE_LABEL selector
#   2. Validates that at least one node was found, exits with error if none
#   3. Populates NODE_NAMES array with matching node names
#   4. Copies all found nodes to TARGET_NODES array
#   5. When INCLUDE_NODES=true and TARGET_PODS exists:
#      - Extracts node names from TARGET_PODS entries (format: namespace:pod:node:container)
#      - Deduplicates and finds nodes not already selected by label
#      - Adds additional nodes to TARGET_NODES array
#      - Reports count of additional nodes added
#   6. Provides visual feedback throughout the process using format_message
#   7. Handles errors gracefully with descriptive error messages
# -------------------------------------------------------------------------------
select_target_nodes() {
  # Display all label selectors being used
  if [[ ${#NODE_LABELS[@]} -eq 1 ]]; then
    format_message "🔍 Finding nodes with label selector: ${NODE_LABELS[0]}"
  else
    format_message "🔍 Finding nodes with label selectors (OR logic):"
    for label in "${NODE_LABELS[@]}"; do
      format_message "   • $label"
    done
  fi
  echo ""

  # Collect all nodes from all label selectors
  local all_nodes_output=""

  # Iterate through each label selector
  for node_label in "${NODE_LABELS[@]}"; do
    local nodes_output
    if ! nodes_output=$($KUBE_CLI get nodes -l "$node_label" -o custom-columns="NAME:.metadata.name" --no-headers 2>/dev/null); then
      echo "Error: Failed to query nodes with label selector '$node_label'" >&2
      return 1
    fi

    # Collect nodes from this label selector
    if [[ -n "$nodes_output" ]]; then
      all_nodes_output="${all_nodes_output}${nodes_output}"$'\n'
    fi
  done

  # Check if any nodes were found
  if [[ -z "$all_nodes_output" ]]; then
    echo "Error: No nodes found matching any of the label selectors" >&2
    return 1
  fi

  # Convert to array with deduplication (bash 3.2 compatible)
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # Check if already in array (bash 3.2 compatible)
      local already_added=false
      for existing_node in "${NODE_NAMES[@]}"; do
        if [[ "$existing_node" == "$line" ]]; then
          already_added=true
          break
        fi
      done

      # Only add if not already in array
      if [[ "$already_added" == "false" ]]; then
        NODE_NAMES+=("$line")
      fi
    fi
  done <<< "$all_nodes_output"

  format_message "✅ Found ${#NODE_NAMES[@]} unique nodes:"
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
      local node_name
      node_name=$(echo "$target_pod" | cut -d':' -f3)
      pod_nodes+=("$node_name")
    done

    # Remove duplicates and find nodes not already selected by -L
    local unique_pod_nodes=()
    while IFS= read -r node; do
      [[ -n "$node" ]] && unique_pod_nodes+=("$node")
    done < <(printf '%s\n' "${pod_nodes[@]}" | sort -u)
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
      format_message "   ➕ Added ${#additional_nodes[@]} additional nodes from pod selections:"
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
# Description:
#   Discovers pods matching the specified label selector and populates the POD_NAMES
#   array with their information. This function performs the core pod discovery logic
#   using kubectl/oc commands and validates that target pods are found and running.
#   It handles namespace-specific searches and provides detailed feedback about discovered pods.
#
# Parameters:
#   None. (Uses global POD_LABEL and DEBUG_NAMESPACE variables)
#
# Example Usage:
#   find_pods_by_label
#   # This searches for pods matching POD_LABEL and populates POD_NAMES
#
# Expected Output:
#   - Progress messages showing pod discovery process
#   - List of discovered pods with their status
#   - Populates global POD_NAMES array
#   - Error messages if no pods found or pods not running
#
# Detailed Behavior:
#   - Uses kubectl/oc to search for pods matching the label selector
#   - Searches in specified namespace or current context namespace
#   - Validates that discovered pods are in Running state
#   - Populates POD_NAMES array with format: "pod_name:container_name:node_name:namespace"
#   - Provides detailed output showing pod names, nodes, and status
#   - Exits with error if no matching pods are found
#   - This function is the core of the pod discovery mechanism
# -------------------------------------------------------------------------------
find_pods_by_label() {
  # Display all label selectors being used
  if [[ ${#POD_LABELS[@]} -eq 1 ]]; then
    format_message "🔍 Finding pods with label selector: ${POD_LABELS[0]}"
  else
    format_message "🔍 Finding pods with label selectors (OR logic):"
    for label in "${POD_LABELS[@]}"; do
      format_message "   • $label"
    done
  fi
  echo ""

  # Collect all pods from all label selectors
  local all_pods_list=""

  # Iterate through each label selector
  for pod_label in "${POD_LABELS[@]}"; do
    local pod_list
    if ! pod_list=$($KUBE_CLI get pods --all-namespaces -l "${pod_label}" -o jsonpath='{range .items[*]}{.metadata.name}{":"}{.spec.containers[*].name}{":"}{.spec.nodeName}{":"}{.metadata.namespace}{"\n"}{end}' 2>/dev/null); then
      echo "Error: Failed to query pods with label '$pod_label'" >&2
      return 1
    fi

    # Collect pods from this label selector
    if [[ -n "$pod_list" ]]; then
      all_pods_list="${all_pods_list}${pod_list}"$'\n'
    fi
  done

  # Check if any pods were found
  if [[ -z "$all_pods_list" ]]; then
    echo "Error: No pods found matching any of the label selectors (searched cluster-wide)" >&2
    return 1
  fi

  # Parse pod list and populate POD_NAMES array with deduplication (bash 3.2 compatible)
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      # Extract pod name and namespace for deduplication key
      local pod_name
      local pod_namespace
      pod_name=$(echo "$line" | cut -d':' -f1)
      pod_namespace=$(echo "$line" | cut -d':' -f4)
      local pod_key="${pod_name}:${pod_namespace}"

      # Check if already in array (bash 3.2 compatible)
      local already_added=false
      for existing_pod in "${POD_NAMES[@]}"; do
        # Extract existing pod's key
        local existing_pod_name
        local existing_pod_namespace
        existing_pod_name=$(echo "$existing_pod" | cut -d':' -f1)
        existing_pod_namespace=$(echo "$existing_pod" | cut -d':' -f4)
        local existing_key="${existing_pod_name}:${existing_pod_namespace}"

        if [[ "$existing_key" == "$pod_key" ]]; then
          already_added=true
          break
        fi
      done

      # Only add if not already in array
      if [[ "$already_added" == "false" ]]; then
        POD_NAMES+=("$line")
      fi
    fi
  done <<< "$all_pods_list"

  format_message "✅ Found ${#POD_NAMES[@]} unique pods:"
  for pod_info in "${POD_NAMES[@]}"; do
    local pod_name
    local pod_namespace
    pod_name=$(echo "$pod_info" | cut -d':' -f1)
    pod_namespace=$(echo "$pod_info" | cut -d':' -f4)
    format_message "   📦 $pod_name (namespace: $pod_namespace)"
  done
  echo ""

  return 0
}

# -------------------------------------------------------------------------------
# Function: validate_all_requirements
# -------------------------------------------------------------------------------
# Description:
#   Validates all system requirements and Kubernetes cluster permissions needed
#   for successful script execution. This function performs comprehensive checks
#   including cluster connectivity, required permissions, and dependency availability.
#   It ensures the environment is properly configured before proceeding with operations.
#
# Parameters:
#   None. (Uses global KUBE_CLI and other configuration variables)
#
# Example Usage:
#   validate_all_requirements
#   # This checks all prerequisites for script execution
#
# Expected Output:
#   - No output if all requirements are met
#   - Error messages to stderr if requirements are not satisfied
#   - Exits with error status if critical requirements are missing
#
# Detailed Behavior:
#   - Checks Kubernetes cluster connectivity and authentication
#   - Validates required permissions: pod creation, deletion, and execution
#   - Verifies kubectl/oc CLI availability and functionality
#   - Checks for required system capabilities and dependencies
#   - Validates namespace access and permissions
#   - Ensures container runtime interface availability if needed
#   - This function acts as a pre-flight check before any operations
#   - Prevents script execution in environments that lack necessary prerequisites
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
# Description:
#   Creates debug pods for all target pods selected by the label selector. This function
#   iterates through the TARGET_PODS array and creates individual debug pods that will
#   execute commands within the network namespace of each target pod. It handles command
#   encoding, unique naming, and maintains arrays of created debug pods for later management.
#
# Parameters:
#   Uses global variables:
#     $TARGET_PODS[]               - Array of pod info strings (format: pod:container:node:namespace)
#     $CUSTOM_COMMAND              - Optional custom command to execute in debug pods
#     $SELECT_TO_DOWNLOAD_COMMAND  - Command to select files for download
#     $NODE_SELECT_TO_DOWNLOAD_COMMAND - Command to select node files for download
#     $DEBUG_NAMESPACE             - Target namespace for debug pod creation
#     $NAMESPACE                   - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI                    - Kubernetes CLI command (kubectl/oc)
#   Modifies global arrays:
#     DEBUG_POD_NAMES[]            - Names of successfully created debug pods
#     POD_DEBUG_HOSTNAMES[]        - Hostnames for file download operations
#   Sets global variables:
#     $CAPTURE_COMMAND             - Base64 encoded custom command
#     $ENCODED_SELECT_COMMAND      - Base64 encoded select-to-download command
#     $ENCODED_NODE_SELECT_COMMAND - Base64 encoded node select command
#
# Example Usage:
#   TARGET_PODS=("nginx-pod:nginx:worker1:default" "app-pod:app:worker2:prod")
#   CUSTOM_COMMAND="tcpdump -i any -w capture.pcap"
#   create_debug_pods_for_targets
#   # Creates debug pods for nginx-pod and app-pod with custom tcpdump command
#
# Expected Output:
#   - Progress messages for each debug pod creation
#   - Success/failure notifications for individual pods
#   - Updates to DEBUG_POD_NAMES array with created pod names
#   - Base64 encoded commands stored in global variables
#   - Returns 0 on completion (individual failures logged but don't stop process)
#
# Detailed Behavior:
#   1. Encodes CUSTOM_COMMAND to base64 for secure pod specification passing
#   2. Encodes SELECT_TO_DOWNLOAD_COMMAND and NODE_SELECT_TO_DOWNLOAD_COMMAND to base64
#   3. Determines target namespace (DEBUG_NAMESPACE or fallback to NAMESPACE)
#   4. Generates epoch timestamp for unique pod naming
#   5. For each target pod in TARGET_PODS array:
#      - Extracts pod name, container name, and node name from target string
#      - Generates unique debug pod name using node name, pod hash, and timestamp
#      - Ensures uniqueness by checking existing pods and incrementing counter if needed
#      - Calls create_single_debug_pod() to create the actual debug pod
#      - Adds successful pod names to DEBUG_POD_NAMES and POD_DEBUG_HOSTNAMES arrays
#      - Reports creation status with visual indicators
#   6. Continues processing all pods even if individual creations fail
#   7. Uses MD5 hashing for shorter, predictable pod names (with fallbacks)
# -------------------------------------------------------------------------------
create_debug_pods_for_targets() {
  # Set capture command before creating pods
  local HAS_CUSTOM_CMD="false"
  if [[ -n "$CUSTOM_COMMAND" ]]; then
    # Encode custom command to base64
    CAPTURE_COMMAND=$(echo -n "$CUSTOM_COMMAND" | base64 -w 0)
    HAS_CUSTOM_CMD="true"
  fi

  # Encode select-to-download commands to base64
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    ENCODED_SELECT_COMMAND=$(echo -n "$SELECT_TO_DOWNLOAD_COMMAND" | base64 -w 0)
  fi

  if [[ -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" ]]; then
    ENCODED_NODE_SELECT_COMMAND=$(echo -n "$NODE_SELECT_TO_DOWNLOAD_COMMAND" | base64 -w 0)
  fi

  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time
  epoch_time=$(date +"%s")


  for target_pod in "${TARGET_PODS[@]}"; do
    local pod_name
    local container_name
    local node_name
    pod_name=$(echo "$target_pod" | cut -d':' -f1)
    container_name=$(echo "$target_pod" | cut -d':' -f2)
    node_name=$(echo "$target_pod" | cut -d':' -f3)

    # Generate unique debug pod name with hash for shorter names
    # Use "pod-debug-" prefix to distinguish from node-debug pods
    local pod_hash
    if command -v md5sum >/dev/null 2>&1; then
      pod_hash=$(echo "$pod_name" | md5sum | cut -c1-8)
    elif command -v md5 >/dev/null 2>&1; then
      pod_hash=$(echo "$pod_name" | md5 | cut -c1-8)
    else
      # Fallback to simple hash
      pod_hash=$(echo "$pod_name" | cksum | cut -d' ' -f1 | cut -c1-8)
    fi
    local debug_pod_name
    debug_pod_name=$(truncate_name_with_hash "pod-debug-${pod_hash}-${epoch_time}")

    # Check if pod name exists and increment until unique
    local counter=1
    while $KUBE_CLI get pod "${debug_pod_name}" -n "${debug_ns}" &>/dev/null; do
      counter=$((counter + 1))
      debug_pod_name=$(truncate_name_with_hash "pod-debug-${pod_hash}-${epoch_time}-${counter}")
    done

    format_message "   📦 Creating debug pod for ${pod_name}:${container_name} on ${node_name}"

    if create_single_debug_pod "$pod_name" "$container_name" "$node_name" "$debug_pod_name" "$debug_ns"; then
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
# Description:
#   Creates debug pods on selected nodes for executing node-level commands with host
#   networking and privileged access. This function iterates through the TARGET_NODES
#   array and creates individual debug pods that run on each node with access to the
#   host network namespace and filesystem for system-level diagnostics and operations.
#
# Parameters:
#   Uses global variables:
#     $TARGET_NODES[]      - Array of node names where debug pods should be created
#     $DEBUG_NAMESPACE     - Target namespace for debug pod creation
#     $NAMESPACE           - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI            - Kubernetes CLI command (kubectl/oc)
#   Modifies global arrays:
#     DEBUG_POD_NAMES[]    - Names of successfully created debug pods
#     NODE_DEBUG_HOSTNAMES[] - Hostnames for node-based file download operations
#
# Example Usage:
#   TARGET_NODES=("worker1" "worker2" "master1")
#   DEBUG_NAMESPACE="monitoring"
#   create_node_debug_pods
#   # Creates debug pods on worker1, worker2, and master1 in monitoring namespace
#
# Expected Output:
#   - Progress messages for each node debug pod creation
#   - Success/failure notifications for individual nodes
#   - Updates to DEBUG_POD_NAMES and NODE_DEBUG_HOSTNAMES arrays
#   - Returns 0 on completion (individual failures logged but don't stop process)
#
# Detailed Behavior:
#   1. Determines target namespace (DEBUG_NAMESPACE or fallback to NAMESPACE or default)
#   2. For each node in TARGET_NODES array:
#      - Generates a hash of the node name for unique but predictable pod naming
#      - Creates unique debug pod name using format: node-{hash}-{timestamp}
#      - Ensures uniqueness by checking existing pods and incrementing counter if needed
#      - Calls create_single_node_debug_pod() to create debug pod with host networking
#      - Adds successful pod names to DEBUG_POD_NAMES and NODE_DEBUG_HOSTNAMES arrays
#      - Reports creation status with visual node indicators
#   3. Continues processing all nodes even if individual creations fail
#   4. Uses MD5 hashing for consistent pod names (with platform-specific fallbacks)
#   5. Node debug pods run with privileged access and hostNetwork for system diagnostics
#   6. Generated pod names are shorter than regular debug pods due to node-specific usage
# -------------------------------------------------------------------------------
create_node_debug_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE:-default}}"

  for node_name in "${TARGET_NODES[@]}"; do
    # Generate unique node debug pod name with hash
    # Use "node-debug-" prefix to clearly indicate node-level debugging
    local node_hash
    if command -v md5sum >/dev/null 2>&1; then
      node_hash=$(echo "$node_name" | md5sum | cut -c1-6)
    elif command -v md5 >/dev/null 2>&1; then
      node_hash=$(echo "$node_name" | md5 | cut -c1-6)
    else
      # Fallback to simple hash
      node_hash=$(echo "$node_name" | cksum | cut -d' ' -f1 | cut -c1-6)
    fi
    local debug_pod_name
    debug_pod_name=$(truncate_name_with_hash "node-debug-${node_hash}-$(date +%s)")
    local counter=1

    # Check if pod name exists and increment until unique
    while $KUBE_CLI get pod "${debug_pod_name}" -n "${debug_ns}" &>/dev/null; do
      counter=$((counter + 1))
      debug_pod_name=$(truncate_name_with_hash "node-debug-${node_hash}-$(date +%s)-${counter}")
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
# Description:
#   Creates a single debug pod on a specific node for executing node-level commands.
#   This debug pod runs with full host access (networking, PID, IPC) and privileged
#   security context to perform system-level operations, diagnostics, and troubleshooting
#   directly on the Kubernetes node infrastructure.
#
# Parameters:
#   $1 - node_name: Name of the target node where debug pod should be created
#   $2 - debug_pod_name: Unique name for the debug pod to be created
#   $3 - debug_ns: Namespace where the debug pod should be created
#   Uses global variables:
#     $DEBUG_IMAGE - Container image for debug pod (default: nicolaka/netshoot)
#     $KUBE_CLI    - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   create_single_node_debug_pod "worker1" "node-abc123-1234567890" "monitoring"
#   # Creates debug pod named node-abc123-1234567890 on worker1 in monitoring namespace
#   # Debug pod will have full access to worker1's host system
#
# Expected Output:
#   - Creates Kubernetes pod resource via kubectl/oc apply
#   - Debug pod runs with privileged security context and host access
#   - Returns kubectl/oc apply exit status (0 for success)
#   - No direct stdout output (creation handled by Kubernetes API)
#
# Detailed Behavior:
#   1. Accepts three required parameters for node-specific pod creation
#   2. Generates complete Kubernetes pod specification with:
#      - Metadata: name, namespace, and node-specific labels
#      - Host access: hostPID, hostNetwork, and hostIPC all enabled
#      - Container: uses DEBUG_IMAGE with embedded node debug script
#      - Security: privileged context running as root (UID 0)
#      - Node affinity: uses nodeSelector to ensure scheduling on target node
#      - Host filesystem: mounted at /host for complete file system access
#   3. Embeds node debug script using build_node_debug_script() function
#   4. Script is indented properly for YAML format using sed
#   5. Pod runs as one-shot job with no restart policy specified (defaults to Always)
#   6. Uses nodeSelector instead of nodeName for more flexible scheduling
#   7. Applies pod specification directly to Kubernetes cluster
#   8. Includes debug and node labels for easy identification and filtering
#   9. Designed for system administration tasks like network diagnostics, file operations
# -------------------------------------------------------------------------------
create_single_node_debug_pod() {
  local node_name="$1"
  local debug_pod_name="$2"
  local debug_ns="$3"

  # Truncate node name for label value (63 char limit)
  local node_label_value
  node_label_value=$(truncate_label_value_with_hash "$node_name")

  # Create pod with embedded script

  run_kube_cmd "$debug_pod_name" "apply" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${debug_pod_name}
  namespace: ${debug_ns}
  labels:
    app: debug
    node: ${node_label_value}
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
# Description:
#   Generates a complete bash script for execution within node-level debug pods.
#   This function creates a self-contained script that executes node-level commands
#   directly on the host system with full access to node resources. The script handles
#   optional dependency installation and placeholder substitution for node-specific operations.
#
# Parameters:
#   $1 - node_name: Name of the target node (used for placeholder substitution)
#   $2 - debug_pod_name: Name of the debug pod (for logging/identification only)
#   Uses global variables:
#     $NODE_COMMAND     - The command to execute on the node
#     $PLACEHOLDER_CHAR - Character for target substitution in commands (% replaced with node_name)
#     $INSTALL_DEPS     - Boolean flag for automatic dependency installation
#
# Example Usage:
#   NODE_COMMAND="tcpdump -i any -w %.pcap"
#   SCRIPT_CONTENT=$(build_node_debug_script "worker1" "node-debug-123")
#   # Returns bash script that executes tcpdump on worker1, saving to worker1.pcap
#   # Placeholder % in commands will be replaced with "worker1"
#
# Expected Output:
#   - Complete bash script suitable for execution in node debug pod
#   - Script includes optional dependency installation and command execution
#   - Returns script content to stdout for embedding in pod specifications
#   - Generated script runs with host-level privileges and keeps pod alive with tail
#
# Detailed Behavior:
#   1. Accepts node and debug pod names as parameters for context and substitution
#   2. Performs placeholder substitution in NODE_COMMAND using target node name
#   3. Generates script header with error handling and node identification logging
#   4. Implements optional CRI dependency installation when INSTALL_DEPS=true:
#      - Downloads and installs crictl v1.28.0 from GitHub releases
#      - Supports both curl and wget download methods with fallbacks
#      - Installs to /usr/local/bin with proper permissions
#      - Provides warning messages for installation failures
#   5. Executes the final node command directly on host system
#   6. Appends "tail -f /dev/null" to keep debug pod running after command completion
#   7. Uses heredoc (<<SCRIPT...SCRIPT) for clean multi-line script generation
#   8. Generated script runs with full node privileges via hostNetwork/hostPID/privileged
#   9. Includes comprehensive logging for troubleshooting and monitoring
#   10. Simpler than build_debug_script() as it doesn't require namespace operations
# -------------------------------------------------------------------------------
build_node_debug_script() {
  local node_name="$1"
  local debug_pod_name="$2"

  # Substitute placeholder with target node name in node command
  local final_node_command="${NODE_COMMAND//${PLACEHOLDER_CHAR}/$node_name}"

  cat <<SCRIPT
set -e
echo "======================================================================" >&2
echo "Starting command execution" >&2
echo "  Target: node=${node_name}" >&2
echo "  Debug Pod: ${debug_pod_name}" >&2
echo "  Command: ${final_node_command}" >&2
echo "======================================================================" >&2

# Install crictl if needed
if [[ "${INSTALL_DEPS}" == "true" ]] && ! command -v crictl >/dev/null 2>&1; then
  echo "Installing crictl..." >&2
  if command -v curl >/dev/null 2>&1; then
    curl -sL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz | tar -C /usr/local/bin -xz 2>/dev/null && chmod +x /usr/local/bin/crictl
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz | tar -C /usr/local/bin -xz 2>/dev/null && chmod +x /usr/local/bin/crictl
  fi
  echo "CRI tools setup completed" >&2
fi

# Execute the node command directly
${final_node_command} ; tail -f /dev/null
SCRIPT
}

# -------------------------------------------------------------------------------
# Function: create_single_debug_pod
# -------------------------------------------------------------------------------
# Description:
#   Creates a single debug pod that attaches to a target pod's network namespace to
#   execute commands within that pod's network context. The debug pod runs with
#   privileged access, host networking, and access to host filesystem for deep
#   system inspection and troubleshooting capabilities.
#
# Parameters:
#   $1 - pod_name: Name of the target pod to debug
#   $2 - container_name: Name of the target container within the pod
#   $3 - node_name: Name of the node where both pods reside
#   $4 - debug_pod_name: Unique name for the debug pod to be created
#   $5 - debug_ns: Namespace where the debug pod should be created
#   Uses global variables:
#     $DEBUG_IMAGE - Container image for debug pod (default: nicolaka/netshoot)
#     $KUBE_CLI    - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   create_single_debug_pod "nginx-app" "nginx" "worker1" "worker1-debug-abc123-1234567890" "monitoring"
#   # Creates debug pod named worker1-debug-abc123-1234567890 in monitoring namespace
#   # Debug pod will attach to nginx-app pod's network namespace on worker1
#
# Expected Output:
#   - Creates Kubernetes pod resource via kubectl/oc apply
#   - Debug pod runs with privileged security context
#   - Returns kubectl/oc apply exit status (0 for success)
#   - No direct stdout output (creation handled by Kubernetes API)
#
# Detailed Behavior:
#   1. Accepts five required parameters for pod creation context
#   2. Generates complete Kubernetes pod specification with:
#      - Metadata: name and namespace from parameters
#      - Container: uses DEBUG_IMAGE with embedded debug script
#      - Security: privileged context running as root (UID 0)
#      - Networking: hostNetwork=true for network namespace access
#      - Access: hostPID=true and hostIPC=true for system visibility
#      - Node affinity: scheduled on specific node via nodeName
#      - Host filesystem: mounted at /host for file system access
#   3. Embeds debug script using build_debug_script() function
#   4. Script is indented properly for YAML format using sed
#   5. Pod runs as one-shot job with restartPolicy=Never
#   6. Uses privileged security context for container runtime access
#   7. Applies pod specification directly to Kubernetes cluster
#   8. Returns success/failure status from kubectl/oc command
# -------------------------------------------------------------------------------
create_single_debug_pod() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local debug_pod_name="$4"
  local debug_ns="$5"

  # Create pod with embedded script

  run_kube_cmd "$debug_pod_name" "apply" apply -f - <<EOF
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
# Description:
#   Generates a complete bash script that will be executed inside debug pods to attach
#   to target pod network namespaces and execute debugging commands. This function creates
#   a self-contained script that handles CRI runtime detection, container process discovery,
#   and network namespace execution for pod-level debugging operations.
#
# Parameters:
#   $1 - pod_name: Name of the target pod to debug (used for placeholder substitution)
#   $2 - container_name: Name of the target container within the pod
#   $3 - node_name: Name of the node where the pod resides (informational)
#   $4 - debug_pod_name: Name of the debug pod (for logging/identification only)
#   Uses global variables:
#     $CRI_SOCKET      - Custom CRI socket path if specified
#     $CRI_RUNTIME     - Container runtime type (containerd/crio/docker)
#     $INSTALL_DEPS    - Boolean flag for automatic dependency installation
#     $NAMESPACE       - Kubernetes namespace containing the target pod
#     $CUSTOM_COMMAND  - Custom command to execute (if specified)
#     $CAPTURE_COMMAND - Encoded command or default tcpdump command
#     $PLACEHOLDER_CHAR - Character for target substitution in commands (% replaced with pod_name)
#
# Example Usage:
#   SCRIPT_CONTENT=$(build_debug_script "nginx-app" "nginx" "worker1" "pod-debug-123")
#   # Returns complete bash script for debugging nginx-app pod
#   # Placeholder % in commands will be replaced with "nginx-app"
#
# Expected Output:
#   - Complete bash script suitable for execution in debug pod
#   - Script includes CRI socket configuration, container discovery, and command execution
#   - Returns script content to stdout for embedding in pod specifications
#   - Generated script handles all error cases and provides detailed logging
#
# Detailed Behavior:
#   1. Generates script header with error handling and container identification logging
#   2. Includes configure_crictl_socket() function for CRI runtime configuration
#   3. Sets up CRI socket path based on runtime type or custom socket specification
#   4. Handles crictl installation/discovery with multiple fallback options
#   5. Implements optional dependency installation when INSTALL_DEPS=true
#   6. Creates pod and container discovery logic using crictl:
#      - Finds pod by name and namespace using crictl pods
#      - Locates specific container by name using crictl ps
#      - Extracts container PID using crictl inspect with JSON parsing
#   7. Implements network namespace execution using nsenter
#   8. Calls generate_exec_command() to build final command with placeholder substitution
#   9. Includes comprehensive error handling for missing pods, containers, or PIDs
#   10. Provides detailed logging at each step for troubleshooting
#   11. Generated script runs autonomously within debug pod environment
#   12. Uses heredoc (<<SCRIPT...SCRIPT) for clean multi-line script generation
# -------------------------------------------------------------------------------
build_debug_script() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local debug_pod_name="$4"

  cat <<SCRIPT
set -e
echo "======================================================================" >&2
echo "Starting command execution" >&2
echo "  Target: pod=${pod_name} container=${container_name}" >&2
echo "  Node: ${node_name}" >&2
echo "  Debug Pod: ${debug_pod_name}" >&2

# Show command that will be executed (with placeholder substitution for display)
if [[ "${HAS_CUSTOM_CMD}" == "true" ]]; then
  PREVIEW_CMD=\$(echo '${CAPTURE_COMMAND}' | base64 -d)
  PREVIEW_CMD="\${PREVIEW_CMD//${PLACEHOLDER_CHAR}/${pod_name}}"
  echo "  Command: \$PREVIEW_CMD" >&2
else
  PREVIEW_CMD="${CAPTURE_COMMAND//${PLACEHOLDER_CHAR}/${pod_name}}"
  echo "  Command: \$PREVIEW_CMD" >&2
fi
echo "======================================================================" >&2

# -------------------------------------------------------------------------------
# Function: configure_crictl_socket
# -------------------------------------------------------------------------------
# Description:
#   Configures the Container Runtime Interface (CRI) socket for crictl operations
#   within debug pods. This embedded function sets up the appropriate runtime
#   endpoint based on the detected or specified container runtime, enabling
#   crictl commands to communicate with the host's container runtime.
#
# Parameters:
#   None (uses global environment variables from parent script)
#   - CRI_SOCKET: Custom CRI socket path (optional)
#   - CRI_RUNTIME: Detected container runtime (containerd, crio, docker)
#
# Example Usage:
#   configure_crictl_socket
#   This function is called within debug pod scripts to set up crictl access.
#
# Expected Output:
#   - Creates /etc/crictl.yaml with runtime endpoint configuration
#   - Outputs configuration confirmation message to stderr
#   - Enables crictl commands to function within the debug pod environment
#
# Detailed Behavior:
#   1. Determines appropriate socket path based on custom or runtime-specific defaults:
#      - Uses CRI_SOCKET if explicitly provided (prefixed with /host)
#      - Falls back to runtime-specific defaults for containerd, crio, or docker
#      - Defaults to containerd socket for unknown runtimes
#   2. Creates /etc/crictl.yaml configuration file with runtime-endpoint setting
#   3. Provides confirmation output showing the configured endpoint
#   4. Enables subsequent crictl operations within the debug pod environment
# -------------------------------------------------------------------------------
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
echo "======================================================================" >&2
echo "Executing command for pod:${pod_name} container:${container_name} PID:\$PID" >&2
echo "======================================================================" >&2

# Execute in network namespace
if [[ -d "/host/proc/\$PID" ]]; then
  $(generate_exec_command "${pod_name}")
else
  echo "ERROR: PID \$PID not found" >&2
  exit 1
fi
SCRIPT
}


# -------------------------------------------------------------------------------
# Function: generate_exec_command
# -------------------------------------------------------------------------------
# Description:
#   Generates the final execution command for running inside debug pods within
#   target container network namespaces. This function handles both custom commands
#   and default commands, performs placeholder substitution, and constructs the
#   proper nsenter command for network namespace execution.
#
# Parameters:
#   $1 - target_pod_name: Name of the target pod for placeholder substitution
#   Uses global variables:
#     $CUSTOM_COMMAND    - Boolean/flag indicating custom command usage
#     $CAPTURE_COMMAND   - Base64 encoded command or default tcpdump command
#     $PLACEHOLDER_CHAR  - Character used for target substitution (default: %)
#
# Example Usage:
#   CUSTOM_COMMAND="true"
#   CAPTURE_COMMAND="dGNwZHVtcCAtaSBhbnkgLXcgJS5wY2Fw"  # base64: "tcpdump -i any -w %.pcap"
#   PLACEHOLDER_CHAR="%"
#   generate_exec_command "nginx-app-123"
#   # Returns: DECODED_CMD=$(echo 'dGNw...' | base64 -d)
#   #          FINAL_CMD=$(echo "$DECODED_CMD" | sed 's/%/nginx-app-123/g')
#   #          nsenter -n -t $PID /bin/bash -c "$FINAL_CMD" & ...
#
# Expected Output:
#   - Bash command lines for execution within debug pod script
#   - Commands include base64 decoding for custom commands
#   - Placeholder substitution with actual target pod name
#   - Returns properly formatted nsenter command to stdout
#
# Detailed Behavior:
#   1. Accepts target pod name for placeholder substitution
#   2. Branches based on CUSTOM_COMMAND flag:
#      a. Custom command path:
#         - Generates base64 decode command for CAPTURE_COMMAND
#         - Creates sed command for placeholder substitution with target pod name
#         - Wraps in nsenter with network namespace and adds tail to keep pod alive
#      b. Default command path:
#         - Directly substitutes placeholder in CAPTURE_COMMAND with target pod name
#         - Creates simple nsenter command without bash wrapping
#   3. Uses nsenter -n -t $PID to enter target container's network namespace
#   4. For custom commands, appends "tail -f /dev/null" to prevent pod exit
#   5. Output is embedded directly into generated debug pod scripts
#   6. Handles complex commands with pipes, redirects, and special characters
#   7. Ensures proper escaping for shell execution within nsenter context
# -------------------------------------------------------------------------------
generate_exec_command() {
  local target_pod_name="$1"

  if [[ -n "$CUSTOM_COMMAND" ]]; then
    echo "DECODED_CMD=\$(echo '${CAPTURE_COMMAND}' | base64 -d)"
    echo "FINAL_CMD=\$(echo \"\$DECODED_CMD\" | sed 's/${PLACEHOLDER_CHAR}/${target_pod_name}/g')"
    cat <<'EXECEND'
# Run command in target pod's network namespace (keep debug pod's mount namespace for /host access)
nsenter -n -t $PID /bin/bash -c "$FINAL_CMD" 2>&1 &
NSENTER_PID=$!
echo "Command started in background (PID: $NSENTER_PID)" >&2

# Keep pod alive and monitor the background process
tail -f /dev/null &
TAIL_PID=$!

# Wait for nsenter process to complete or continue
wait $NSENTER_PID 2>/dev/null || true
echo "Command completed with exit code: $?" >&2

# Keep pod alive with tail
wait $TAIL_PID
EXECEND
  else
    local final_capture_cmd="${CAPTURE_COMMAND//${PLACEHOLDER_CHAR}/$target_pod_name}"
    echo "nsenter -n -t \$PID ${final_capture_cmd} 2>&1 &"
    echo "NSENTER_PID=\$!"
    echo "echo \"Command started in background (PID: \$NSENTER_PID)\" >&2"
    echo "tail -f /dev/null"
  fi
}

# -------------------------------------------------------------------------------
# Function: wait_for_debug_pods_ready
# -------------------------------------------------------------------------------
# Description:
#   Waits for all debug pods in the DEBUG_POD_NAMES array to reach Running status
#   before proceeding with debug operations. This function monitors pod startup
#   status, handles failures gracefully, and provides visual progress feedback
#   to ensure all debug infrastructure is ready for command execution.
#
# Parameters:
#   Uses global variables:
#     $DEBUG_POD_NAMES[] - Array of debug pod names to monitor
#     $DEBUG_NAMESPACE   - Namespace where debug pods are created
#     $NAMESPACE         - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI          - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   DEBUG_POD_NAMES=("debug-pod-1" "debug-pod-2" "debug-pod-3")
#   wait_for_debug_pods_ready
#   # Waits up to 60 seconds for all three pods to reach Running status
#
# Expected Output:
#   - Progress indicators showing pod readiness checking
#   - Status summary of ready, failed, and total pods
#   - Success confirmation when all pods are ready
#   - Error messages for failed pods with details
#   - Returns 0 if at least one pod becomes ready, 1 if none ready
#
# Detailed Behavior:
#   1. Sets maximum wait time to 60 seconds for pod startup
#   2. Maintains separate arrays for ready_pods and failed_pods tracking
#   3. Shows initial status message with total pod count
#   4. Implements polling loop that checks every 2 seconds:
#      - Skips already processed pods (ready or failed)
#      - Uses kubectl/oc to get pod phase status
#      - Categorizes pods as Running (ready) or Failed
#      - Tracks wait time and exits loop when timeout or all pods processed
#   5. Provides visual progress feedback with dots during waiting
#   6. Reports final status with counts of ready/failed/total pods
#   7. Lists specific failed pod names for troubleshooting
#   8. Returns success if at least one pod becomes ready
#   9. Designed for fault tolerance - doesn't fail if some pods fail to start
# -------------------------------------------------------------------------------
wait_for_debug_pods_ready() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local max_wait=60

  local ready_pods=()
  local failed_pods=()
  local wait_time=0

  # Show initial status
  printf "%s\n" "$(format_message "🔄 Checking ${#DEBUG_POD_NAMES[@]} debug pods")"

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
# Description:
#   Creates discovery pods for both pod-level and node-level targets to identify and
#   prepare files for download operations. This function handles file discovery for
#   pods with -s option and nodes with -S option, creating specialized pods that
#   execute file listing commands and prepare files for subsequent download.
#
# Parameters:
#   Uses global variables:
#     $SELECT_TO_DOWNLOAD_COMMAND      - Command to list files from pod targets
#     $NODE_SELECT_TO_DOWNLOAD_COMMAND - Command to list files from node targets
#     $POD_DEBUG_HOSTNAMES[]           - Array of pod debug hostnames
#     $NODE_DEBUG_HOSTNAMES[]          - Array of node debug hostnames
#     $TARGET_PODS[]                   - Array of target pod information
#     $TARGET_NODES[]                  - Array of target node names
#     $DEBUG_NAMESPACE                 - Namespace for discovery pod creation
#     $NAMESPACE                       - Fallback namespace
#     $DEBUG_IMAGE                     - Container image for discovery pods
#   Modifies global arrays:
#     DISCOVERY_POD_NAMES[]            - Names of created discovery pods
#
# Example Usage:
#   SELECT_TO_DOWNLOAD_COMMAND="ls *.pcap"
#   NODE_SELECT_TO_DOWNLOAD_COMMAND="ls /tmp/*.log"
#   create_file_discovery_pods
#   # Creates discovery pods to list .pcap files from pods and .log files from nodes
#
# Expected Output:
#   - Progress messages for discovery pod creation
#   - Visual indicators showing pod and node file discovery operations
#   - Updates to DISCOVERY_POD_NAMES array with created pod names
#   - Returns 0 on completion (individual failures logged but don't stop process)
#
# Detailed Behavior:
#   1. Determines target namespace for discovery pod creation
#   2. Generates epoch timestamp for unique pod naming
#   3. Pod target discovery (if SELECT_TO_DOWNLOAD_COMMAND specified):
#      - Iterates through TARGET_PODS array and POD_DEBUG_HOSTNAMES
#      - Extracts pod name, container name, and node name from target strings
#      - Generates unique discovery pod names using node+pod hash+timestamp
#      - Ensures name uniqueness by checking existing pods and incrementing counters
#      - Creates pod-level discovery pods using create_discovery_pod()
#      - Maintains mapping between original debug hostnames and discovery pods
#   4. Node target discovery (if NODE_SELECT_TO_DOWNLOAD_COMMAND specified):
#      - Iterates through TARGET_NODES array and NODE_DEBUG_HOSTNAMES
#      - Generates unique node discovery pod names using node hash+timestamp
#      - Ensures name uniqueness for node discovery pods
#      - Creates node-level discovery pods using create_node_discovery_pod()
#      - Maintains mapping between debug hostnames and discovery pods
#   5. Uses MD5 hashing for consistent, shorter pod names (with platform fallbacks)
#   6. Handles both pod-level and node-level file discovery in single function
#   7. Provides comprehensive logging for troubleshooting discovery operations
# -------------------------------------------------------------------------------
create_file_discovery_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time
  epoch_time=$(date +"%s")
  echo ""

  # Create discovery pods for pod targets (if -s is specified)
  if [[ -n "$SELECT_TO_DOWNLOAD_COMMAND" && ${#POD_DEBUG_HOSTNAMES[@]} -gt 0 ]]; then
    format_message "📦 Creating discovery pods for pod targets..."

    local pod_index=0
    for target_pod in "${TARGET_PODS[@]}"; do
      local pod_name
      local container_name
      local node_name
      local original_debug_hostname
      pod_name=$(echo "$target_pod" | cut -d':' -f1)
      container_name=$(echo "$target_pod" | cut -d':' -f2)
      node_name=$(echo "$target_pod" | cut -d':' -f3)
      original_debug_hostname="${POD_DEBUG_HOSTNAMES[$pod_index]}"

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
      # Use "pod-disc-" prefix to match pod-debug- naming scheme
      local base_name="pod-disc-${pod_hash}-${epoch_time}"
      local counter=1
      local discovery_pod_name
      discovery_pod_name=$(truncate_name_with_hash "${base_name}-${counter}")

      # Find available name with truncation for k8s 253 char limit
      while $KUBE_CLI get pod "$discovery_pod_name" -n "$debug_ns" &>/dev/null; do
        counter=$((counter + 1))
        discovery_pod_name=$(truncate_name_with_hash "${base_name}-${counter}")
      done

      # Create discovery pod with tail -f /dev/null entrypoint
      # Pass target pod name for placeholder substitution
      if create_discovery_pod "$pod_name" "$container_name" "$node_name" "$discovery_pod_name" "$debug_ns" "$pod_name" 2>/dev/null; then
        DISCOVERY_POD_NAMES+=("$discovery_pod_name")
        DISCOVERY_POD_INFO+=("$discovery_pod_name:$node_name:pod:$pod_name")
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
      # Use "node-disc-" prefix to match node-debug- naming scheme
      local node_hash
      if command -v md5sum >/dev/null 2>&1; then
        node_hash=$(echo "$node_name" | md5sum | cut -c1-6)
      elif command -v md5 >/dev/null 2>&1; then
        node_hash=$(echo "$node_name" | md5 | cut -c1-6)
      else
        node_hash=$(echo "$node_name" | cksum | cut -d' ' -f1 | cut -c1-6)
      fi
      local base_name="node-disc-${node_hash}-${epoch_time}"
      local counter=1
      local discovery_pod_name
      discovery_pod_name=$(truncate_name_with_hash "${base_name}-${counter}")

      # Find available name with truncation for k8s 253 char limit
      while $KUBE_CLI get pod "$discovery_pod_name" -n "$debug_ns" &>/dev/null; do
        counter=$((counter + 1))
        discovery_pod_name=$(truncate_name_with_hash "${base_name}-${counter}")
      done

      # Create node discovery pod with tail -f /dev/null entrypoint
      # Pass target node name for placeholder substitution
      if create_node_discovery_pod "$node_name" "$discovery_pod_name" "$debug_ns" "$node_name" 2>/dev/null; then
        DISCOVERY_POD_NAMES+=("$discovery_pod_name")
        DISCOVERY_POD_INFO+=("$discovery_pod_name:$node_name:node:$node_name")
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
    local discovery_pod_name
    local node_name
    local pod_type
    local target_name
    local pod_had_failure=false
    discovery_pod_name=$(echo "$pod_info" | cut -d':' -f1)
    node_name=$(echo "$pod_info" | cut -d':' -f2)
    pod_type=$(echo "$pod_info" | cut -d':' -f3)
    target_name=$(echo "$pod_info" | cut -d':' -f4)

    # Try to execute the command - if it fails due to pod issues, that's an error
    # But if it succeeds with no output, that just means no files to download
    if ! run_kube_cmd "$discovery_pod_name" "exec-test" exec "$discovery_pod_name" -n "$debug_ns" -- true 2>/dev/null; then
      # Pod is not accessible - this is a real error
      format_message_stderr "   ❌ Failed to access pod $discovery_pod_name (node $node_name)"
      failed_pods+=("$discovery_pod_name")
      continue
    fi

    # Execute the select command by decoding it from the pod's environment variable
    # This approach is safer as it avoids passing the command through multiple shell interpretations
    # which could break on special characters like ; && | etc.
    local files_list
    if [[ "$pod_type" == "node" ]]; then
      # For node discovery pods: decode ENCODED_NODE_SELECT_COMMAND, apply placeholder substitution with target node name, and run from /host
      files_list=$(run_kube_cmd "$discovery_pod_name" "exec-list" exec "$discovery_pod_name" -n "$debug_ns" -- bash -c '
TARGET_NAME='"'$target_name'"'
cmd=$(echo "$ENCODED_NODE_SELECT_COMMAND" | base64 -d 2>/dev/null || echo "")
if [[ -n "$cmd" ]]; then
  cmd="${cmd//${PLACEHOLDER_CHAR}/$TARGET_NAME}"
  cd /host && bash -c "$cmd"
fi
' 2>/dev/null || true)
    else
      # For pod discovery pods: decode ENCODED_SELECT_COMMAND and apply placeholder substitution with target pod name
      files_list=$(run_kube_cmd "$discovery_pod_name" "exec-list" exec "$discovery_pod_name" -n "$debug_ns" -- bash -c '
TARGET_NAME='"'$target_name'"'
cmd=$(echo "$ENCODED_SELECT_COMMAND" | base64 -d 2>/dev/null || echo "")
if [[ -n "$cmd" ]]; then
  cmd="${cmd//${PLACEHOLDER_CHAR}/$TARGET_NAME}"
  bash -c "$cmd"
fi
' 2>/dev/null || true)
    fi

    if [[ -z "$files_list" ]]; then
      # No files found - this is not an error, just skip with info message
      format_message_stderr "   📂 No files to download from pod $discovery_pod_name (node $node_name)"
      # Mark as successful since the select command worked correctly (just no files)
      successful_pods+=("$discovery_pod_name")
      continue
    fi
    local downloaded_files=()
    while IFS= read -r file_path; do
      if [[ -n "$file_path" ]]; then
        local output_file
        output_file="$OUTPUT_DIR/${target_name}_$(basename "$file_path")"

        # Try download with up to 3 attempts (handles transient network/pod issues)
        local download_success=false
        local attempt=1
        local max_attempts=3

        while [[ $attempt -le $max_attempts && "$download_success" == "false" ]]; do
          if [[ $attempt -gt 1 ]]; then
            sleep 1  # Brief pause between retries to allow pod/network recovery
          fi

          if run_kube_cmd "$discovery_pod_name" "cp" cp "$debug_ns/$discovery_pod_name:$file_path" "$output_file" 2>/dev/null; then
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
      run_kube_cmd "$discovery_pod_name" "exec-rm" exec "$discovery_pod_name" -n "$debug_ns" -- rm -f "$file_path" 2>/dev/null
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
    run_kube_cmd "discovery-cleanup" "delete" delete pods "${successful_pods[@]}" -n "$debug_ns" --ignore-not-found >/dev/null 2>&1
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
# Description:
#   Cleans up debug pods created by the script by deleting them from the Kubernetes
#   cluster. This function removes all pods listed in the DEBUG_POD_NAMES array to
#   prevent resource accumulation and maintain cluster cleanliness after debug operations.
#
# Parameters:
#   Uses global variables:
#     $DEBUG_POD_NAMES[] - Array of debug pod names to delete
#     $DEBUG_NAMESPACE   - Namespace where debug pods were created
#     $NAMESPACE         - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI          - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   DEBUG_POD_NAMES=("debug-pod-1" "debug-pod-2" "debug-pod-3")
#   cleanup_debug_pods
#   # Deletes all three debug pods from the target namespace
#
# Expected Output:
#   - Silent operation (output redirected to /dev/null)
#   - Pods are removed from Kubernetes cluster
#   - No return value (always succeeds due to --ignore-not-found)
#
# Detailed Behavior:
#   1. Determines target namespace (DEBUG_NAMESPACE or fallback to NAMESPACE)
#   2. Checks if DEBUG_POD_NAMES array contains any pods
#   3. Uses kubectl/oc delete with --ignore-not-found flag for safe deletion
#   4. Deletes all pods in batch operation for efficiency
#   5. Suppresses all output (both stdout and stderr) for clean operation
#   6. Gracefully handles missing pods without errors
# -------------------------------------------------------------------------------
cleanup_debug_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#DEBUG_POD_NAMES[@]} -gt 0 ]]; then
    run_kube_cmd "debug-cleanup" "delete" delete pods "${DEBUG_POD_NAMES[@]}" -n "${debug_ns}" --ignore-not-found >/dev/null 2>&1
  fi
}

# -------------------------------------------------------------------------------
# Function: cleanup_discovery_pods
# -------------------------------------------------------------------------------
# Description:
#   Cleans up file discovery pods created for file download operations by deleting
#   them from the Kubernetes cluster. This function removes all pods listed in the
#   DISCOVERY_POD_NAMES array to prevent resource accumulation after file operations.
#
# Parameters:
#   Uses global variables:
#     $DISCOVERY_POD_NAMES[] - Array of discovery pod names to delete
#     $DEBUG_NAMESPACE       - Namespace where discovery pods were created
#     $NAMESPACE             - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI              - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   DISCOVERY_POD_NAMES=("discovery-pod-1" "discovery-pod-2")
#   cleanup_discovery_pods
#   # Deletes all discovery pods used for file download operations
#
# Expected Output:
#   - Silent operation (output redirected to /dev/null)
#   - Discovery pods are removed from Kubernetes cluster
#   - No return value (always succeeds due to --ignore-not-found)
#
# Detailed Behavior:
#   1. Determines target namespace (DEBUG_NAMESPACE or fallback to NAMESPACE)
#   2. Checks if DISCOVERY_POD_NAMES array contains any pods
#   3. Uses kubectl/oc delete with --ignore-not-found flag for safe deletion
#   4. Deletes all discovery pods in batch operation for efficiency
#   5. Suppresses all output (both stdout and stderr) for clean operation
#   6. Gracefully handles missing pods without errors
# -------------------------------------------------------------------------------
cleanup_discovery_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#DISCOVERY_POD_NAMES[@]} -gt 0 ]]; then
    format_message "🧹 Cleaning up discovery pods..."

    # Download logs from each discovery pod before deletion (only if -o is specified)
    if [[ -n "$OUTPUT_DIR" ]]; then
      for discovery_pod in "${DISCOVERY_POD_NAMES[@]}"; do
        format_message "   📥 Downloading logs from discovery pod: $discovery_pod"
        if $KUBE_CLI get pod "$discovery_pod" -n "${debug_ns}" >/dev/null 2>&1; then
          local log_file="${OUTPUT_DIR}/discovery-${discovery_pod}.log"
          $KUBE_CLI logs "$discovery_pod" -n "${debug_ns}" --ignore-errors > "$log_file" 2>/dev/null || true
          if [[ -s "$log_file" ]]; then
            format_message "      ✅ Discovery logs saved to: $log_file"
          else
            format_message "      ⚠️  No logs available for: $discovery_pod"
            rm -f "$log_file" 2>/dev/null || true
          fi
        else
          format_message "      ⚠️  Discovery pod not found: $discovery_pod"
        fi
      done
    fi

    # Now delete all discovery pods
    run_kube_cmd "discovery-cleanup" "delete" delete pods "${DISCOVERY_POD_NAMES[@]}" -n "${debug_ns}" --ignore-not-found >/dev/null 2>&1
  fi
}

# -------------------------------------------------------------------------------
# Function: build_discovery_script
# -------------------------------------------------------------------------------
# Description:
#   Generates a complete bash script for execution within discovery pods to perform
#   one-time file discovery. This function creates a self-contained script that
#   executes the file selection command once and outputs results. The pod then
#   keeps running to allow the main script to download the discovered files.
#
# Parameters:
#   $1 - pod_name: Name of the target pod (used for placeholder substitution)
#   $2 - container_name: Name of the target container (for logging)
#   $3 - node_name: Name of the node where this discovery pod runs
#   $4 - discovery_pod_name: Name of the discovery pod (for logging/identification)
#   $5 - target_name: Target pod name for placeholder substitution (defaults to pod_name)
#
# Expected Output:
#   - Complete bash script suitable for execution in discovery pod
#   - Script executes selection command once and outputs file list
#   - Pod stays alive with tail -f /dev/null for file downloads
#   - Placeholder % in commands will be replaced with target pod name
# -------------------------------------------------------------------------------
build_discovery_script() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local discovery_pod_name="$4"
  local target_name="${5:-$pod_name}"  # Use target pod name for placeholder substitution

  cat <<DISCOVERY_SCRIPT
#!/bin/bash
set -e

timestamp="\$(date '+%Y-%m-%d %H:%M:%S')"
echo "[\$timestamp] Discovery pod $discovery_pod_name starting" >&2
echo "[\$timestamp] Target: pod=$pod_name, container=$container_name, node=$node_name" >&2

# Execute the select command
if [[ -n "\${ENCODED_SELECT_COMMAND:-}" ]]; then
  select_cmd=\$(echo "\$ENCODED_SELECT_COMMAND" | base64 -d 2>/dev/null || echo "")
  if [[ -n "\$select_cmd" ]]; then
    # Apply placeholder substitution using target pod name
    select_cmd="\${select_cmd//\${PLACEHOLDER_CHAR:-\%}/$target_name}"

    echo "[\$timestamp] Running selection command: \$select_cmd" >&2

    # Execute command and capture output
    if result=\$(bash -c "\$select_cmd" 2>/dev/null); then
      if [[ -n "\$result" ]]; then
        echo "[\$timestamp] FILES_FOUND:" >&2
        echo "\$result" | while IFS= read -r line; do
          [[ -n "\$line" ]] && echo "[\$timestamp]   \$line" >&2
        done
      else
        echo "[\$timestamp] NO_FILES_FOUND" >&2
      fi
    else
      echo "[\$timestamp] ERROR: Selection command failed" >&2
    fi
  fi
else
  echo "[\$timestamp] WARNING: No select command configured" >&2
fi

# Keep pod alive for file downloads
echo "[\$timestamp] Discovery complete, keeping pod alive for downloads..." >&2
tail -f /dev/null
DISCOVERY_SCRIPT
}

# -------------------------------------------------------------------------------
# Function: build_node_discovery_script
# -------------------------------------------------------------------------------
# Description:
#   Generates a complete bash script for execution within node discovery pods to
#   perform one-time file discovery from node filesystem. This function creates a
#   self-contained script that executes the file selection command once on the host
#   node and outputs results. The pod then keeps running to allow log retrieval.
#
# Parameters:
#   $1 - node_name: Name of the target node (used for placeholder substitution)
#   $2 - discovery_pod_name: Name of the discovery pod (for logging/identification)
#   $3 - target_name: Target node name for placeholder substitution (defaults to node_name)
#
# Expected Output:
#   - Complete bash script suitable for execution in node discovery pod
#   - Script executes file selection command once on host filesystem
#   - Outputs timestamped file discovery results once, then keeps pod alive
#   - Placeholder % in commands will be replaced with target node name
# -------------------------------------------------------------------------------
build_node_discovery_script() {
  local node_name="$1"
  local discovery_pod_name="$2"
  local target_name="${3:-$node_name}"  # Use target node name for placeholder substitution

  cat <<NODE_DISCOVERY_SCRIPT
#!/bin/bash
set -e

echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Node discovery pod $discovery_pod_name starting on node $node_name" >&2

# Get current timestamp
timestamp="\$(date '+%Y-%m-%d %H:%M:%S')"

# Execute the node select command on host filesystem
if [[ -n "\${ENCODED_NODE_SELECT_COMMAND:-}" ]]; then
  select_cmd=\$(echo "\$ENCODED_NODE_SELECT_COMMAND" | base64 -d 2>/dev/null || echo "")
  if [[ -n "\$select_cmd" ]]; then
    # Apply placeholder substitution using target node name
    select_cmd="\${select_cmd//\${PLACEHOLDER_CHAR:-\%}/$target_name}"

    echo "[\$timestamp] Running node selection command: \$select_cmd" >&2

    # Execute command on host filesystem and capture output
    if result=\$(cd /host && bash -c "\$select_cmd" 2>/dev/null); then
      if [[ -n "\$result" ]]; then
        echo "[\$timestamp] NODE_FILES_FOUND:" >&2
        echo "\$result" | while IFS= read -r line; do
          [[ -n "\$line" ]] && echo "[\$timestamp]   \$line" >&2
        done
      else
        echo "[\$timestamp] NO_NODE_FILES_FOUND" >&2
      fi
    else
      echo "[\$timestamp] ERROR: Node select command failed: \$select_cmd" >&2
    fi
  fi
else
  echo "[\$timestamp] WARNING: No node select command configured" >&2
fi

# Keep pod alive
echo "[\$timestamp] Discovery complete, keeping pod alive..." >&2
tail -f /dev/null
NODE_DISCOVERY_SCRIPT
}

# -------------------------------------------------------------------------------
# Function: create_discovery_pod
# -------------------------------------------------------------------------------
# Description:
#   Creates a single file discovery pod for pod-level file operations. This debug pod
#   attaches to a target pod's network namespace to execute file discovery commands,
#   list files for download, and prepare them for subsequent download operations.
#
# Parameters:
#   $1 - pod_name: Name of the target pod containing files
#   $2 - container_name: Name of the target container within the pod
#   $3 - node_name: Name of the node where the pod resides
#   $4 - discovery_pod_name: Unique name for the discovery pod
#   $5 - debug_ns: Namespace where discovery pod should be created
#   Uses global variables:
#     $DEBUG_IMAGE - Container image for discovery pods
#     $KUBE_CLI    - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   create_discovery_pod "nginx-app" "nginx" "worker1" "disc-worker1-abc123" "monitoring"
#   # Creates discovery pod to find files in nginx-app pod on worker1
#
# Expected Output:
#   - Creates Kubernetes pod resource for file discovery
#   - Pod runs with privileged access and network namespace attachment
#   - Returns kubectl/oc apply exit status
#
# Detailed Behavior:
#   - Similar to create_single_debug_pod but specialized for file discovery
#   - Uses build_debug_script for network namespace attachment
#   - Executes file listing commands instead of debug commands
# -------------------------------------------------------------------------------
create_discovery_pod() {
  local pod_name="$1"
  local container_name="$2"
  local node_name="$3"
  local discovery_pod_name="$4"
  local debug_ns="$5"
  local target_name="${6:-$pod_name}"  # Target pod name for placeholder substitution

  # Create discovery pod using YAML manifest for file discovery
  run_kube_cmd "$discovery_pod_name" "apply" apply -f - <<EOF
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
    command: ["/bin/bash", "-c"]
    args:
    - |
$(build_discovery_script "$pod_name" "$container_name" "$node_name" "$discovery_pod_name" "$target_name" | sed 's/^/      /')
    securityContext:
      privileged: true
    env:
    - name: CRI_RUNTIME
      value: "${CRI_RUNTIME}"
    - name: CRI_SOCKET
      value: "${CRI_SOCKET}"
    - name: ENCODED_SELECT_COMMAND
      value: "${ENCODED_SELECT_COMMAND}"
    - name: PLACEHOLDER_CHAR
      value: "${PLACEHOLDER_CHAR}"
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
  local target_name="${4:-$node_name}"  # Target node name for placeholder substitution

  # Create node discovery pod using YAML manifest
  run_kube_cmd "$discovery_pod_name" "apply" apply -f - <<EOF
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
    command: ["/bin/bash", "-c"]
    args:
    - |
$(build_node_discovery_script "$node_name" "$discovery_pod_name" "$target_name" | sed 's/^/      /')
    securityContext:
      privileged: true
    env:
    - name: ENCODED_NODE_SELECT_COMMAND
      value: "${ENCODED_NODE_SELECT_COMMAND}"
    - name: PLACEHOLDER_CHAR
      value: "${PLACEHOLDER_CHAR}"
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
create_kill_switch_monitor_pods() {
  # Skip if no kill switches are configured
  if [[ -z "$KILL_SWITCH_ABS" && -z "$KILL_SWITCH_REL" ]]; then
    return 0
  fi

  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local epoch_time
  epoch_time=$(date +"%s")

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

    # Create shorter name with prefix based on debug pod type
    local debug_pod_hash
    if command -v md5sum >/dev/null 2>&1; then
      debug_pod_hash=$(echo "$debug_pod" | md5sum | cut -c1-8)
    elif command -v md5 >/dev/null 2>&1; then
      debug_pod_hash=$(echo "$debug_pod" | md5 | cut -c1-8)
    else
      # Fallback to simple hash
      debug_pod_hash=$(echo "$debug_pod" | cksum | cut -d' ' -f1 | cut -c1-8)
    fi

    # Determine prefix based on debug pod type
    local ks_prefix
    if [[ "$debug_pod" == pod-debug-* ]]; then
      ks_prefix="pod-ks"
    elif [[ "$debug_pod" == node-debug-* ]]; then
      ks_prefix="node-ks"
    else
      # Fallback for legacy naming
      ks_prefix="ks"
    fi

    local monitor_pod_name
    monitor_pod_name=$(truncate_name_with_hash "${ks_prefix}-${debug_pod_hash}")

    # Check if pod name exists and increment until unique
    local counter=1
    while $KUBE_CLI get pod "${monitor_pod_name}" -n "${debug_ns}" &>/dev/null; do
      counter=$((counter + 1))
      monitor_pod_name=$(truncate_name_with_hash "${ks_prefix}-${debug_pod_hash}-${counter}")
    done

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
create_kill_switch_monitor_pod() {
  local target_debug_pod="$1"
  local node_name="$2"
  local monitor_pod_name="$3"
  local debug_ns="$4"
  local volume_path="$5"

  # Truncate target pod name for label value (63 char limit)
  local target_pod_label_value
  target_pod_label_value=$(truncate_label_value_with_hash "$target_debug_pod")

  run_kube_cmd "$monitor_pod_name" "apply" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${monitor_pod_name}
  namespace: ${debug_ns}
  labels:
    app: kill-switch-monitor
    target-pod: ${target_pod_label_value}
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
#   Generates a complete bash script for execution within kill switch monitor pods.
#   This function creates a self-contained monitoring script that continuously checks
#   filesystem usage against configured thresholds and triggers pod termination when
#   limits are exceeded to prevent disk pressure issues on Kubernetes nodes.
#
# Parameters:
#   $1 - target_debug_pod: Name of the debug pod being monitored
#   $2 - volume_path: Filesystem path to monitor for disk usage (e.g., /tmp, /var)
#   Uses global variables:
#     $KILL_SWITCH_ABS - Absolute disk usage threshold (e.g., "1GB", "500MB")
#     $KILL_SWITCH_REL - Relative disk usage threshold (e.g., "10%", "5%")
#
# Example Usage:
#   KILL_SWITCH_ABS="1GB"
#   SCRIPT_CONTENT=$(build_kill_switch_monitor_script "debug-pod-123" "/tmp")
#   # Returns script that monitors /tmp and kills debug-pod-123 if usage exceeds 1GB
#
# Expected Output:
#   - Complete bash script suitable for execution in kill switch monitor pod
#   - Script includes size parsing, threshold monitoring, and termination logic
#   - Returns script content to stdout for embedding in pod specifications
#   - Generated script runs continuously until threshold is triggered or interrupted
#
# Detailed Behavior:
#   1. Accepts target debug pod name and volume path for monitoring context
#   2. Embeds parse_size_to_bytes() function for unit conversion (B, KB, MB, GB, TB)
#   3. Installs bc package for floating-point calculations in relative threshold checks
#   4. Configures monitoring parameters from global variables:
#      - KILL_SWITCH_ABS for absolute threshold monitoring
#      - KILL_SWITCH_REL for relative threshold monitoring
#      - CHECK_INTERVAL hardcoded to 1 second for filesystem checks
#   5. Implements continuous monitoring loop that:
#      - Uses df command to get filesystem statistics for specified volume path
#      - Extracts used_bytes, available_bytes, and total_bytes from df output
#      - Checks absolute threshold: triggers when available space falls below limit
#      - Checks relative threshold: calculates percentage and triggers when below limit
#   6. Uses bc calculator for precise floating-point percentage calculations
#   7. Exits with status 0 when threshold is exceeded (signals successful kill trigger)
#   8. Provides detailed logging for monitoring status and threshold violations
#   9. Supports both traditional (1000-based) and binary (1024-based) units
#   10. Handles various unit formats: B, K/Ki, M/Mi/MB, G/Gi/GB, T/Ti/TB
#   11. Runs indefinitely until threshold breach or external termination
#   12. Uses heredoc (<<SCRIPT...SCRIPT) for clean multi-line script generation
# -------------------------------------------------------------------------------
build_kill_switch_monitor_script() {
  local target_debug_pod="$1"
  local volume_path="$2"

  cat <<SCRIPT
set -e
echo "=== Kill switch monitor for ${target_debug_pod} ===" >&2

# -------------------------------------------------------------------------------
# Function: parse_size_to_bytes
# -------------------------------------------------------------------------------
# Description:
#   Converts human-readable size strings with units to bytes for precise storage
#   threshold calculations. This embedded function supports both decimal (SI)
#   and binary (IEC) unit standards commonly used in Kubernetes and OpenShift
#   environments, enabling accurate disk usage comparisons.
#
# Parameters:
#   $1 - size_str: Size string with unit (e.g., "1GB", "500MB", "1.5Gi")
#        Supports: B, K/Ki, M/Mi, G/Gi, T/Ti with various case combinations
#
# Example Usage:
#   bytes=\$(parse_size_to_bytes "1GB")     # Returns: 1073741824
#   bytes=\$(parse_size_to_bytes "500MB")   # Returns: 524288000
#   bytes=\$(parse_size_to_bytes "1.5Gi")   # Returns: 1610612736
#
# Expected Output:
#   - Returns the equivalent number of bytes as a string to stdout
#   - Returns empty string and exit code 1 for invalid input formats
#   - Handles both decimal (1000-based) and binary (1024-based) units
#
# Detailed Behavior:
#   1. Uses regex pattern matching to extract numeric value and unit suffix
#   2. Handles decimal numbers with optional fractional parts
#   3. Defaults to bytes (B) if no unit is specified
#   4. Supports comprehensive unit conversion matrix:
#      - Decimal units: K(1000), M(1000²), G(1000³), T(1000⁴)
#      - Binary units: Ki(1024), Mi(1024²), Gi(1024³), Ti(1024⁴)
#      - Case-insensitive unit recognition with multiple format variants
#   5. Uses integer arithmetic for binary calculations to avoid floating-point errors
#   6. Returns empty result for unrecognized units or malformed input
# -------------------------------------------------------------------------------
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
CHECK_INTERVAL=1  # Check every 1 second
VOLUME_PATH="${volume_path}"

# Helper function to format bc output with leading zero
format_bc_result() {
  local result=\$1
  local unit=\$2
  if [[ "\$result" =~ ^\\. ]]; then
    echo "0\${result}\${unit}"
  else
    echo "\${result}\${unit}"
  fi
}

# Print initial configuration
echo "======================================================================" >&2
echo "Kill Switch Monitor - Target Pod: ${target_debug_pod}" >&2
echo "======================================================================" >&2
echo "Monitored Path: \$VOLUME_PATH" >&2
if [[ -n "\$KILL_SWITCH_ABS" ]]; then
  echo "Threshold Type: Absolute (\$KILL_SWITCH_ABS)" >&2
  echo "Trigger: Available space < \$KILL_SWITCH_ABS" >&2
elif [[ -n "\$KILL_SWITCH_REL" ]]; then
  echo "Threshold Type: Relative (\$KILL_SWITCH_REL)" >&2
  echo "Trigger: Free space % < \$KILL_SWITCH_REL" >&2
else
  echo "ERROR: No kill switch thresholds configured" >&2
  exit 1
fi
echo "Check Interval: \${CHECK_INTERVAL}s" >&2
echo "======================================================================" >&2
echo "" >&2

# Find the filesystem mount point for the monitored path
ORIGINAL_PATH="\$VOLUME_PATH"
MOUNT_POINT=""
FILESYSTEM=""

# Try to find an existing parent directory to check
CHECK_PATH="\$VOLUME_PATH"
while [[ ! -d "\$CHECK_PATH" && "\$CHECK_PATH" != "/" && -n "\$CHECK_PATH" ]]; do
  CHECK_PATH="\$(dirname "\$CHECK_PATH")"
done

# Get mount point information
if [[ -d "\$CHECK_PATH" ]]; then
  if df_check=\$(df "\$CHECK_PATH" 2>/dev/null); then
    MOUNT_POINT=\$(echo "\$df_check" | tail -n 1 | awk '{print \$NF}')
    FILESYSTEM=\$(echo "\$df_check" | tail -n 1 | awk '{print \$1}')

    echo "Path Analysis:" >&2
    echo "  Requested Path: \$ORIGINAL_PATH" >&2
    if [[ "\$CHECK_PATH" != "\$ORIGINAL_PATH" ]]; then
      echo "  Path Status: Does not exist (checking parent)" >&2
      echo "  Checked Path: \$CHECK_PATH" >&2
    else
      echo "  Path Status: Exists" >&2
    fi
    echo "  Mount Point: \$MOUNT_POINT" >&2
    echo "  Filesystem: \$FILESYSTEM" >&2
    echo "" >&2

    # Monitor the mount point
    VOLUME_PATH="\$MOUNT_POINT"
  else
    echo "ERROR: Cannot determine filesystem mount for \$ORIGINAL_PATH" >&2
    exit 1
  fi
else
  echo "ERROR: Cannot find accessible directory for \$ORIGINAL_PATH" >&2
  exit 1
fi

# Print table header
if [[ -n "\$KILL_SWITCH_ABS" ]]; then
  printf "%-19s | %-9s | %-9s | %-9s | %-6s | %-6s | %-9s | %-20s\n" \
    "Timestamp" "Total" "Used" "Available" "Used%" "Free%" "Threshold" "Status" >&2
  printf "%s\n" "-------------------+-----------+-----------+-----------+--------+--------+-----------+----------------------" >&2
elif [[ -n "\$KILL_SWITCH_REL" ]]; then
  printf "%-19s | %-9s | %-9s | %-9s | %-6s | %-6s | %-9s | %-20s\n" \
    "Timestamp" "Total" "Used" "Available" "Used%" "Free%" "Threshold" "Status" >&2
  printf "%s\n" "-------------------+-----------+-----------+-----------+--------+--------+-----------+----------------------" >&2
fi

while true; do
  # Get current timestamp
  TIMESTAMP=\$(date '+%Y-%m-%d %H:%M:%S')

  # Get filesystem stats in bytes for precise calculations
  if df_output=\$(df -B1 "\$VOLUME_PATH" 2>/dev/null); then
    stats_line=\$(echo "\$df_output" | tail -n 1)
    used_bytes=\$(echo "\$stats_line" | awk '{print \$3}')
    available_bytes=\$(echo "\$stats_line" | awk '{print \$4}')
    total_bytes=\$(echo "\$stats_line" | awk '{print \$2}')

    # Convert bytes to human-readable format for logging
    if [[ -n "\$total_bytes" && "\$total_bytes" -gt 0 ]]; then
      if [[ "\$total_bytes" -ge 1099511627776 ]]; then  # >= 1TB
        total_raw=\$(echo "scale=2; \$total_bytes / 1099511627776" | bc 2>/dev/null || echo "0")
        used_raw=\$(echo "scale=2; \$used_bytes / 1099511627776" | bc 2>/dev/null || echo "0")
        avail_raw=\$(echo "scale=2; \$available_bytes / 1099511627776" | bc 2>/dev/null || echo "0")
        total_human=\$(format_bc_result "\$total_raw" "TB")
        used_human=\$(format_bc_result "\$used_raw" "TB")
        avail_human=\$(format_bc_result "\$avail_raw" "TB")
      elif [[ "\$total_bytes" -ge 1073741824 ]]; then  # >= 1GB
        total_raw=\$(echo "scale=2; \$total_bytes / 1073741824" | bc 2>/dev/null || echo "0")
        used_raw=\$(echo "scale=2; \$used_bytes / 1073741824" | bc 2>/dev/null || echo "0")
        avail_raw=\$(echo "scale=2; \$available_bytes / 1073741824" | bc 2>/dev/null || echo "0")
        total_human=\$(format_bc_result "\$total_raw" "GB")
        used_human=\$(format_bc_result "\$used_raw" "GB")
        avail_human=\$(format_bc_result "\$avail_raw" "GB")
      elif [[ "\$total_bytes" -ge 1048576 ]]; then  # >= 1MB
        total_raw=\$(echo "scale=2; \$total_bytes / 1048576" | bc 2>/dev/null || echo "0")
        used_raw=\$(echo "scale=2; \$used_bytes / 1048576" | bc 2>/dev/null || echo "0")
        avail_raw=\$(echo "scale=2; \$available_bytes / 1048576" | bc 2>/dev/null || echo "0")
        total_human=\$(format_bc_result "\$total_raw" "MB")
        used_human=\$(format_bc_result "\$used_raw" "MB")
        avail_human=\$(format_bc_result "\$avail_raw" "MB")
      else
        total_human="\${total_bytes}B"
        used_human="\${used_bytes}B"
        avail_human="\${available_bytes}B"
      fi

      # Calculate usage percentage
      if command -v bc >/dev/null 2>&1; then
        usage_percent_raw=\$(echo "scale=1; (\$used_bytes * 100) / \$total_bytes" | bc 2>/dev/null || echo "0.0")
        free_percent_raw=\$(echo "scale=1; (\$available_bytes * 100) / \$total_bytes" | bc 2>/dev/null || echo "0.0")
        if [[ "\$usage_percent_raw" =~ ^\\. ]]; then
          usage_percent="0\${usage_percent_raw}"
        else
          usage_percent="\$usage_percent_raw"
        fi
        if [[ "\$free_percent_raw" =~ ^\\. ]]; then
          free_percent="0\${free_percent_raw}"
        else
          free_percent="\$free_percent_raw"
        fi
      else
        usage_percent="0.0"
        free_percent="0.0"
      fi

      # Check absolute threshold (available space falls below threshold)
      status_msg="OK"
      if [[ -n "\$KILL_SWITCH_ABS" && -n "\$available_bytes" ]]; then
        threshold_bytes=\$(parse_size_to_bytes "\$KILL_SWITCH_ABS")
        if [[ -n "\$threshold_bytes" ]]; then
          # Convert threshold to human-readable for display
          if [[ "\$threshold_bytes" -ge 1073741824 ]]; then
            threshold_raw=\$(echo "scale=2; \$threshold_bytes / 1073741824" | bc 2>/dev/null || echo "0")
            threshold_display=\$(format_bc_result "\$threshold_raw" "GB")
          elif [[ "\$threshold_bytes" -ge 1048576 ]]; then
            threshold_raw=\$(echo "scale=2; \$threshold_bytes / 1048576" | bc 2>/dev/null || echo "0")
            threshold_display=\$(format_bc_result "\$threshold_raw" "MB")
          else
            threshold_display="\${threshold_bytes}B"
          fi

          if [[ "\$available_bytes" -lt "\$threshold_bytes" ]]; then
            status_msg="TRIGGERED"
            printf "%-19s | %-9s | %-9s | %-9s | %5s%% | %5s%% | %-9s | %-20s\n" \
              "\$TIMESTAMP" "\$total_human" "\$used_human" "\$avail_human" "\$usage_percent" "\$free_percent" "\$threshold_display" "\$status_msg" >&2
            echo "" >&2
            echo "======================================================================" >&2
            echo "KILL_SWITCH_TRIGGERED at \$TIMESTAMP" >&2
            echo "Available space (\${avail_human}) < Threshold (\${threshold_display})" >&2
            echo "Terminating target pod: ${target_debug_pod}" >&2
            echo "======================================================================" >&2
            exit 0
          else
            margin_bytes=\$((\$available_bytes - \$threshold_bytes))
            if [[ "\$margin_bytes" -ge 1073741824 ]]; then
              margin_raw=\$(echo "scale=2; \$margin_bytes / 1073741824" | bc 2>/dev/null || echo "0")
              margin_display=\$(format_bc_result "\$margin_raw" "GB")
            elif [[ "\$margin_bytes" -ge 1048576 ]]; then
              margin_raw=\$(echo "scale=2; \$margin_bytes / 1048576" | bc 2>/dev/null || echo "0")
              margin_display=\$(format_bc_result "\$margin_raw" "MB")
            else
              margin_display="\${margin_bytes}B"
            fi
            status_msg="OK +\${margin_display}"
          fi

          printf "%-19s | %-9s | %-9s | %-9s | %5s%% | %5s%% | %-9s | %-20s\n" \
            "\$TIMESTAMP" "\$total_human" "\$used_human" "\$avail_human" "\$usage_percent" "\$free_percent" "\$threshold_display" "\$status_msg" >&2
        fi
      fi

      # Check relative threshold
      if [[ -n "\$KILL_SWITCH_REL" && -n "\$available_bytes" && -n "\$total_bytes" && "\$total_bytes" -gt 0 ]]; then
        rel_threshold="\${KILL_SWITCH_REL%\\%}"  # Remove % if present
        if command -v bc >/dev/null 2>&1; then
          if [[ -n "\$free_percent" && -n "\$rel_threshold" ]]; then
            threshold_display="\${rel_threshold}%"

            should_kill=\$(echo "\$free_percent < \$rel_threshold" | bc -l 2>/dev/null || echo "0")
            if [[ "\$should_kill" == "1" ]]; then
              status_msg="TRIGGERED"
              printf "%-19s | %-9s | %-9s | %-9s | %5s%% | %5s%% | %-9s | %-20s\n" \
                "\$TIMESTAMP" "\$total_human" "\$used_human" "\$avail_human" "\$usage_percent" "\$free_percent" "\$threshold_display" "\$status_msg" >&2
              echo "" >&2
              echo "======================================================================" >&2
              echo "KILL_SWITCH_TRIGGERED at \$TIMESTAMP" >&2
              echo "Free space (\${free_percent}%) < Threshold (\${rel_threshold}%)" >&2
              echo "Terminating target pod: ${target_debug_pod}" >&2
              echo "======================================================================" >&2
              exit 0
            else
              margin_percent=\$(echo "\$free_percent - \$rel_threshold" | bc -l 2>/dev/null || echo "0")
              status_msg="OK +\${margin_percent}%"
              printf "%-19s | %-9s | %-9s | %-9s | %5s%% | %5s%% | %-9s | %-20s\n" \
                "\$TIMESTAMP" "\$total_human" "\$used_human" "\$avail_human" "\$usage_percent" "\$free_percent" "\$threshold_display" "\$status_msg" >&2
            fi
          fi
        else
          echo "ERROR: Relative threshold requires 'bc' command" >&2
          exit 1
        fi
      fi
    fi
  else
    printf "%-19s | ERROR: Cannot read filesystem stats for \$VOLUME_PATH\n" "\$TIMESTAMP" >&2
  fi

  sleep "\$CHECK_INTERVAL"
done
SCRIPT
}

# -------------------------------------------------------------------------------
# Function: monitor_kill_switches
# -------------------------------------------------------------------------------
monitor_kill_switches() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"
  local check_interval=1  # Check every 1 second
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

            # Download kill switch monitor logs immediately
            if [[ -n "$OUTPUT_DIR" ]]; then
              local log_file="${OUTPUT_DIR}/killswitch-${monitor_pod}.log"
              $KUBE_CLI logs "$monitor_pod" -n "$debug_ns" --ignore-errors > "$log_file" 2>/dev/null
            fi

            # Delete the target debug pod but leave monitor pod for cleanup later
            $KUBE_CLI delete pod "$target_pod" -n "$debug_ns" --ignore-not-found >/dev/null 2>&1
          fi
          killed_pods+=("$monitor_pod")
        elif [[ "$pod_status" == "Failed" ]]; then
          format_message_stderr "⚠️  Kill switch monitor $monitor_pod failed - check logs for details"

          # Download failed kill switch monitor logs for debugging
          if [[ -n "$OUTPUT_DIR" ]]; then
            local log_file="${OUTPUT_DIR}/killswitch-${monitor_pod}.log"
            $KUBE_CLI logs "$monitor_pod" -n "$debug_ns" --ignore-errors > "$log_file" 2>/dev/null
          fi

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
#   Cleans up kill switch monitor pods created for disk usage monitoring by deleting
#   them from the Kubernetes cluster. This function provides user feedback and removes
#   all pods listed in the KILL_SWITCH_MONITOR_PODS array to maintain cluster cleanliness.
#
# Parameters:
#   Uses global variables:
#     $KILL_SWITCH_MONITOR_PODS[] - Array of kill switch monitor pod names to delete
#     $DEBUG_NAMESPACE            - Namespace where monitor pods were created
#     $NAMESPACE                  - Fallback namespace if DEBUG_NAMESPACE not set
#     $KUBE_CLI                   - Kubernetes CLI command (kubectl/oc)
#
# Example Usage:
#   KILL_SWITCH_MONITOR_PODS=("killswitch-monitor-1" "killswitch-monitor-2")
#   cleanup_kill_switch_monitor_pods
#   # Shows cleanup message and deletes all kill switch monitor pods
#
# Expected Output:
#   - User-visible cleanup message with cleaning emoji
#   - Kill switch monitor pods are removed from Kubernetes cluster
#   - No return value (always succeeds due to --ignore-not-found)
#
# Detailed Behavior:
#   1. Checks if KILL_SWITCH_MONITOR_PODS array contains any pods
#   2. Displays user-friendly cleanup message using format_message
#   3. Determines target namespace (DEBUG_NAMESPACE or fallback to NAMESPACE)
#   4. Uses kubectl/oc delete with --ignore-not-found flag for safe deletion
#   5. Deletes all monitor pods in batch operation for efficiency
#   6. Suppresses kubectl output but shows user progress message
#   7. Gracefully handles missing pods without errors
# -------------------------------------------------------------------------------
cleanup_kill_switch_monitor_pods() {
  local debug_ns="${DEBUG_NAMESPACE:-${NAMESPACE}}"

  if [[ ${#KILL_SWITCH_MONITOR_PODS[@]} -gt 0 ]]; then
    format_message "🧹 Cleaning up kill switch monitor pods..."

    # Download logs from each kill switch monitor pod before deletion (only if -o is specified)
    if [[ -n "$OUTPUT_DIR" ]]; then
      for monitor_pod in "${KILL_SWITCH_MONITOR_PODS[@]}"; do
        format_message "   📥 Downloading logs from kill switch monitor: $monitor_pod"
        if $KUBE_CLI get pod "$monitor_pod" -n "${debug_ns}" >/dev/null 2>&1; then
          local log_file="${OUTPUT_DIR}/killswitch-${monitor_pod}.log"
          $KUBE_CLI logs "$monitor_pod" -n "${debug_ns}" --ignore-errors > "$log_file" 2>/dev/null || true
          if [[ -s "$log_file" ]]; then
            format_message "      ✅ Kill switch logs saved to: $log_file"
          else
            format_message "      ⚠️  No logs available for: $monitor_pod"
            rm -f "$log_file" 2>/dev/null || true
          fi
        else
          format_message "      ⚠️  Kill switch monitor pod not found: $monitor_pod"
        fi
      done
    fi

    # Now delete all kill switch monitor pods
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
    local current_date
    local epoch_time
    current_date=$(date '+%Y-%m-%d')
    epoch_time=$(date '+%s')
    KUBE_DUMP_LOG_FILE="${OUTPUT_DIR}/kube-dump-${current_date}_${epoch_time}.log"

    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"

    # Initialize log file
    echo "=== Kube-dump session started at $(date) ===" > "$KUBE_DUMP_LOG_FILE"
    echo "Command: $0 $*" >> "$KUBE_DUMP_LOG_FILE"
    echo "===============================================" >> "$KUBE_DUMP_LOG_FILE"
  fi

  # Setup verbose debug logging if --verbose is enabled
  if [[ "$VERBOSE" == "true" ]]; then
    if ! setup_debug_logging; then
      exit 1
    fi
  fi

  if true; then
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
    MONITOR_PID=$!
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
    read -r
    echo

    # Stop background monitoring if running
    if [[ -n "$MONITOR_PID" ]]; then
      { kill "$MONITOR_PID" 2>/dev/null || true; } 2>/dev/null
      wait "$MONITOR_PID" 2>/dev/null || true
    fi

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
    if [[ -n "$KILL_SWITCH_ABS" || -n "$KILL_SWITCH_REL" ]]; then
      format_message "🛡️  Kill switch sidecar containers are running and will auto-terminate debug pods if thresholds are exceeded."
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
