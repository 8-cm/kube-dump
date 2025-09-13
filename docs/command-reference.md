# Command Reference

Complete reference for all kube-dump command-line options and parameters.

## Synopsis

```bash
./kube-dump.sh [OPTIONS]
```

## Target Selection

### Pod Selection
- `-l, --label LABEL` - Target pods by label selector (default: `dumpme=yes`)
- `-n, --namespace NAMESPACE` - Kubernetes namespace (default: `default`)

### Node Selection
- `-L, --node-label LABEL` - Target nodes by label selector
- `--include-nodes` - Auto-include nodes hosting selected pods

### Mixed Mode
Use both `-l` and `-L` together for mixed pod/node operations.

## Commands

### Pod Commands
- `-c, --command COMMAND` - Command to execute in pod context (default: tcpdump)
- `-s, --select-files COMMAND` - Command to select files for download from pods

### Node Commands
- `-C, --node-command COMMAND` - Command to execute on nodes (default: tcpdump)
- `-S, --select-node-files COMMAND` - Command to select files for download from nodes

### Default Commands
```bash
# Pod command (default)
tcpdump -i any -w /tmp/PLACEHOLDER_CHAR.pcap

# Node command (default)
tcpdump -i any -w /tmp/PLACEHOLDER_CHAR.pcap
```

## Container & Runtime

### Image & Runtime
- `--image IMAGE` - Debug pod container image (default: `nicolaka/netshoot:latest`)
- `--cri-runtime RUNTIME` - Container runtime: `auto|containerd|crio|docker` (default: `auto`)
- `--cri-socket SOCKET` - Container runtime socket path
- `--install-deps` - Install container runtime tools in debug pods

### Namespace & Placement
- `-N, --debug-namespace NAMESPACE` - Namespace for debug pods (default: same as target)

## File Operations

### Output & Downloads
- `-o, --output-dir PATH` - Output directory for files and logs
- `-P, --placeholder-char CHAR` - Character for hostname substitution (default: `%`)

### File Selection
File selection commands support placeholder substitution:
- `PLACEHOLDER_CHAR` is replaced with the target pod/node name
- Use single quotes to prevent shell interpretation

```bash
# Examples
-s 'find /tmp -name "*PLACEHOLDER_CHAR*"'  # Find files with hostname
-S 'ls /var/log/PLACEHOLDER_CHAR/'         # List logs by hostname
```

## Resource Protection

### Kill Switch
Automatically terminate debug pods when disk usage exceeds thresholds:

- `--kill-switch-abs SIZE` - Absolute free space threshold (e.g., `1GB`, `500MB`)
- `--kill-switch-rel PERCENT` - Relative free space threshold (e.g., `10`, `5`)
- `--kill-switch-pod-volume PATH` - Volume path to monitor in pod debug (default: `/tmp`)
- `--kill-switch-node-volume PATH` - Volume path to monitor in node debug (default: `/`)

### Kill Switch Examples
```bash
# Stop when less than 1GB free space
./kube-dump.sh -l app=web --kill-switch-abs 1GB

# Stop when less than 10% free space
./kube-dump.sh -l app=web --kill-switch-rel 10

# Monitor custom volume path
./kube-dump.sh -l app=web --kill-switch-abs 500MB --kill-switch-pod-volume /var/tmp
```

## Execution Control

### Cleanup & Monitoring
- `--no-cleanup` - Keep debug pods running after execution
- `--no-glyphs` - Disable emoji/Unicode characters for terminal compatibility

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