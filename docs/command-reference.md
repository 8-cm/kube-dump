# Command Reference

Complete reference for all kube-dump command-line options and parameters.

## Synopsis

```bash
./kube-dump.sh [OPTIONS]
```

## Target Selection

### Pod Selection
- `-l, --label LABEL` - Target pods by label selector (can be specified multiple times for OR logic, default: `dumpme=yes`)
- `-n, --namespace NAMESPACE` - Namespace where debug pods should be created
- `--to-namespace NAMESPACE` - Alias for `-n/--namespace` (deprecated, use `-n` instead)

### Node Selection
- `-L, --node-label LABEL` - Target nodes by label selector (can be specified multiple times for OR logic)
- `--include-nodes` - Also run node commands on nodes hosting selected pods

### Mixed Mode
Use both `-l` and `-L` together for mixed pod/node operations.

## Commands

### Pod Commands
- `-e, --execute COMMAND` - Command to execute in pod network namespace (default: `tcpdump -i any -nn -s 0`)
- `-s, --select-to-download COMMAND` - Command to list files for download from pods (space-delimited output)

### Node Commands
- `-E, --node-execute COMMAND` - Command to execute on nodes (default: `tcpdump -i any -nn -s 0`)
- `-S, --node-select-to-download COMMAND` - Command to list node files for download (space-delimited output)

### Default Commands
```bash
# Pod command (default)
tcpdump -i any -nn -s 0

# Node command (default)
tcpdump -i any -nn -s 0
```

## Container & Runtime

### Image & Runtime
- `--image IMAGE` - Container image for debug/discovery/killswitch pods (default: `nicolaka/netshoot`)
- `--cri RUNTIME` - Container runtime interface: `containerd|crio|docker` (default: `containerd`)
- `--cri-socket SOCKET` - Custom CRI socket path (absolute path on node)
- `--install-deps` - Allow automatic installation of CRI dependencies (crictl only)

### Resource Limits
- `--cpu-limit LIMIT` - CPU limit for containers (e.g., `100m`, `500m`, `1`, `2.5`)
- `--memory-limit LIMIT` - Memory limit for containers (e.g., `128Mi`, `512Mi`, `1Gi`)
- `--service-account NAME` - Service account for pods (must exist in target namespace)

### Working Directory
- `--workdir-pod PATH` - Working directory override for pod-based operations
- `--workdir-node PATH` - Working directory override for node-based operations

### Namespace Entry
- `--nsenter-params FLAGS` - Comma-separated nsenter namespace flags for corresponding `-e` command
  - Specify WITHOUT leading dashes (e.g., `n,m` for network+mount)
  - Valid flags: `n` (network), `p` (PID), `m` (mount), `i` (IPC), `u` (UTS), `C` (cgroup), `U` (user), `T` (time)
  - Unspecified commands default to `n` (network namespace only)
  - When using `p` (PID), mount `/proc` first: `mount -t proc none /proc && ps auxf`

## File Operations

### Output & Downloads
- `-o, --output PATH` - Output directory for downloaded files
- `-I, --placeholder CHAR` - Set placeholder character for target/file substitution (default: `%`)
- `--download-verification METHOD` - Verification method for downloads: `hash` (MD5+SHA256), `size`, `none` (default: `none`)

### Script Import
Run local scripts on remote targets:
- `-f, --import-file PATH` - Path to local file to import. Must precede the `-e` or `-E` command it applies to. 
  - Multiple commands can use different import files.
  - The script is base64 encoded and written to a temp file in the target.

### File Selection & Placeholders
Commands support the following placeholders (% is default, configurable via `-I`):
- `%t` - Target name (pod name or node name depending on mode)
- `%n` - Node name (where the pod runs, or the target node itself)
- `%f` - Path to the imported temporary script file (requires `--import-file`)

Examples:
- `%t` is replaced with the target pod/node name
- `%f` is replaced with the temp file path (e.g., `/tmp/kube-dump-import-PID.sh`)
- Use single quotes to prevent shell interpretation

```bash
# Examples
-e 'tcpdump -i any -w %t.pcap'           # Output file named after target
-s 'find /tmp -name "%t*"'               # Find files with target name prefix
-S 'ls /var/log/%t/'                     # List logs by target name
--import-file ./script.sh -e 'bash %f'   # Run imported script
```

## Resource Protection

### Kill Switch
Automatically terminate debug pods when disk usage exceeds thresholds:

- `--kill-switch-abs SIZE` - Absolute free space threshold (e.g., `1GB`, `500MB`)
- `--kill-switch-rel PERCENT` - Relative free space threshold (e.g., `10%`, `5%`)
  - If omitted, auto-detects from kubelet `nodefs.available` (+5% safety margin)
  - Falls back to 10% if auto-detection fails
  - Requires `bc` calculator in the debug image
- `--pod-volume PATH` - Volume path to monitor for pod-based kill switches (e.g., `/tmp`)
- `--node-volume PATH` - Volume path to monitor for node-based kill switches (e.g., `/var`)

### Auto-Detection
When only volume paths are provided without explicit thresholds, the script automatically:
1. Queries kubelet's eviction threshold via `/api/v1/nodes/{node}/proxy/configz`
2. Adds 5% safety margin to the detected threshold
3. Falls back to 10% if detection fails

### Kill Switch Examples
```bash
# Stop when less than 1GB free space
./kube-dump.sh -l app=web --kill-switch-abs 1GB

# Stop when less than 10% free space
./kube-dump.sh -l app=web --kill-switch-rel 10

# Monitor custom volume path
./kube-dump.sh -l app=web --kill-switch-abs 500MB --pod-volume /var/tmp

# Auto-detect kill switch threshold from kubelet
./kube-dump.sh -l app=web --pod-volume /tmp
```

## Execution Control

### Cleanup & Monitoring
- `--no-cleanup` - Skip cleanup, leave debug pods running for log inspection
- `--skip-prepull` - Skip image pre-pulling on target nodes (use if images are already cached)
- `--verbose` - Enable verbose logging (max Kubernetes verbosity, per-pod logs to OUTPUT_DIR/debug/)
- `--no-glyphs` - Disable emojis and use text labels like [INFO], [ERROR], [OK]

## Help & Information

- `-h, --help` - Show help message and examples
- `--version` - Show version information

## Complete Examples

### Basic Usage
```bash
# Default - capture from pods labeled dumpme=yes
./kube-dump.sh

# Target specific pods
./kube-dump.sh -l app=nginx -n production

# Target nodes
./kube-dump.sh -L node-type=worker
```

### File Operations
```bash
# Collect logs from pods
./kube-dump.sh -l app=web -o /tmp/debug -s "find /app/logs -name '*.log'"

# Collect system info from nodes
./kube-dump.sh -L node-type=worker -o /tmp/nodes -S "systemctl status kubelet > /tmp/kubelet-status.txt"
```

### Advanced Usage
```bash
# Mixed mode with kill switch
./kube-dump.sh -l app=web -L node-type=worker --kill-switch-abs 1GB -o /tmp/debug

# Custom runtime configuration
./kube-dump.sh -l app=web --cri-runtime containerd --cri-socket /run/containerd/containerd.sock

# No cleanup mode
./kube-dump.sh -l app=test --no-cleanup

# Script Import (Per-Command)
./kube-dump.sh -l app=web \
  -f ./script-A.sh -e 'bash %f' \
  -f ./script-B.sh -e 'bash %f'
```

## Parameter Validation

### Label Selectors
- Must be valid Kubernetes label selector syntax
- Examples: `app=nginx`, `tier=frontend,version=v1.0`

### Size Specifications
Kill switch sizes support these units:
- `B` - bytes
- `KB` - kilobytes (1000 bytes)
- `MB` - megabytes (1000^2 bytes)
- `GB` - gigabytes (1000^3 bytes)
- `TB` - terabytes (1000^4 bytes)

### Path Specifications
- Must be absolute paths (starting with `/`)
- Directory must exist in target container/node
- Must be writable for file operations

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Invalid arguments
- `3` - Cluster access error
- `4` - Pod creation failure
- `5` - File operation failure

## Environment Variables

These environment variables affect kube-dump behavior:

- `DEBUG=1` - Enable verbose debugging output
- `KUBE_CLI=kubectl|oc` - Override CLI detection
- `DEBUG_IMAGE=image:tag` - Override default debug image

---

For more examples and use cases, see the [Examples](examples.md) guide.