# Command Reference

Complete reference for all kube-dump command-line options and parameters.

## Basic Syntax

### Pod-Based Operations
```bash
./kube-dump.sh [-l <label_selector>] [-n <namespace>] [-e <command>] [options]
```

### Node-Based Operations
```bash
./kube-dump.sh [-L <node_label>] [-E <node_command>] [options]
```

### Mixed Operations
```bash
./kube-dump.sh [-l <label>] [-L <node_label>] [-e <command>] [-E <node_command>] [options]
```

## Target Selection Options

### Pod Targeting

#### `-l, --label <selector>`
Select pods using Kubernetes label selectors.

**Default:** `dumpme=yes`

**Examples:**
```bash
# Single label
./kube-dump.sh -l app=nginx

# Multiple labels (AND)
./kube-dump.sh -l 'app=web,env=prod'

# Label existence
./kube-dump.sh -l 'tier'

# Label negation
./kube-dump.sh -l 'env!=dev'

# Set-based selectors
./kube-dump.sh -l 'env in (prod,staging)'
```

#### `-n, --namespace <namespace>`
Target namespace for pod selection.

**Default:** Current kubectl context namespace

**Examples:**
```bash
# Specific namespace
./kube-dump.sh -l app=web -n production

# All namespaces (requires cluster-wide permissions)
./kube-dump.sh -l app=web -n ''
```

#### `--to-namespace <namespace>`
Namespace where debug pods will be created.

**Default:** Same as target namespace

**Examples:**
```bash
# Debug production pods from monitoring namespace
./kube-dump.sh -l app=api -n production --to-namespace monitoring
```

### Node Targeting

#### `-L, --node-label <selector>`
Select nodes using Kubernetes label selectors.

**Examples:**
```bash
# Worker nodes
./kube-dump.sh -L node-role.kubernetes.io/worker

# Specific zone
./kube-dump.sh -L topology.kubernetes.io/zone=us-west-2a

# Custom labels
./kube-dump.sh -L env=prod,tier=compute
```

#### `--include-nodes`
Automatically include nodes hosting selected pods.

**Examples:**
```bash
# Include nodes for selected pods
./kube-dump.sh -l app=database --include-nodes
```

## Command Execution Options

### Pod Commands

#### `-e, --execute <command>`
Command to execute within pod network namespaces.

**Default:** `tcpdump -i any -nn -s 0`

**Examples:**
```bash
# Network analysis
./kube-dump.sh -l app=web -e 'ss -tuln'

# Traffic capture with filters
./kube-dump.sh -l app=api -e 'tcpdump -i any -n host 10.1.1.1'

# Multi-command with pipes
./kube-dump.sh -l app=web -e 'netstat -i | grep -v lo'

# File generation
./kube-dump.sh -l app=web -e 'tcpdump -i any -w capture-%.pcap -c 100'
```

### Node Commands

#### `-E, --node-execute <command>`
Command to execute on selected nodes with host access.

**Default:** `tcpdump -i any -nn -s 0`

**Examples:**
```bash
# Host network analysis
./kube-dump.sh -L worker=true -E 'ss -tuln'

# Interface monitoring
./kube-dump.sh -L worker=true -E 'tcpdump -i eth0 -c 100'

# System diagnostics
./kube-dump.sh -L worker=true -E 'top -b -n 1'

# File operations
./kube-dump.sh -L worker=true -E 'tcpdump -i any -w /tmp/node-%.pcap'
```

## File Operations

### File Selection

#### `-s, --select-to-download <command>`
Command to find files for download from pod debug sessions.

**Examples:**
```bash
# Find all pcap files
./kube-dump.sh -l app=web -e 'tcpdump -w %.pcap -c 100' -s 'ls *.pcap'

# Find with patterns
./kube-dump.sh -l app=web -s 'find . -name "*.log" -newer /tmp/start'

# Complex selection
./kube-dump.sh -l app=web -s 'ls -la *.{pcap,txt,log} 2>/dev/null || echo "No files"'
```

#### `-S, --node-select-to-download <command>`
Command to find files for download from node debug sessions.

**Examples:**
```bash
# Node file selection
./kube-dump.sh -L worker=true -E 'tcpdump -w %.pcap' -S 'ls *.pcap'

# Host path selection
./kube-dump.sh -L worker=true -S 'find /tmp -name "node-*.txt"'
```

### Output Directory

#### `-o, --output <directory>`
Directory for downloading generated files and session logs.

**Examples:**
```bash
# Local directory
./kube-dump.sh -l app=web -o ./captures

# Absolute path
./kube-dump.sh -l app=web -o /home/user/debug-sessions

# Date-based directory
./kube-dump.sh -l app=web -o "./debug-$(date +%Y%m%d)"
```

**Auto-created files in output directory:**
- **Session logs**: `kube-dump-YYYY-MM-DD_EPOCH.log`
- **Pod files**: `<pod-name>/`
- **Node files**: `<node-name>/`
- **Kill switch logs**: `killswitch-<monitor-pod>.log`
- **Discovery logs**: `discovery-<pod>.log`

## Placeholder and Customization

### Hostname Placeholder

#### `-I, --placeholder <character>`
Character used as hostname placeholder in commands.

**Default:** `%`

**Examples:**
```bash
# Default placeholder
./kube-dump.sh -l app=web -e 'tcpdump -w %.pcap'

# Custom placeholder
./kube-dump.sh -l app=web -e 'tcpdump -w @.pcap' -I@

# Multiple placeholders
./kube-dump.sh -l app=web -e 'echo "Host: %" > %.txt' -s 'ls *.txt'
```

**Placeholder replacement:**
- Pod mode: `%` → `<pod-name>`
- Node mode: `%` → `<node-name>`

## Container Runtime Options

### Runtime Selection

#### `--cri <runtime>`
Specify container runtime interface.

**Supported values:** `containerd`, `crio`, `docker`
**Default:** `containerd`

**Examples:**
```bash
# Explicit containerd
./kube-dump.sh -l app=web --cri containerd

# CRI-O clusters
./kube-dump.sh -l app=web --cri crio

# Docker (via cri-dockerd)
./kube-dump.sh -l app=web --cri docker
```

#### `--cri-socket <path>`
Custom container runtime socket path.

**Examples:**
```bash
# Custom containerd socket
./kube-dump.sh -l app=web --cri-socket /custom/containerd.sock

# Custom CRI-O socket
./kube-dump.sh -l app=web --cri-socket /var/run/crio/crio.sock

# Podman socket
./kube-dump.sh -l app=web --cri-socket /var/run/podman/podman.sock
```

#### `--install-deps`
Automatically install container runtime tools in debug pods.

**Examples:**
```bash
# Auto-install crictl and containerd tools
./kube-dump.sh -l app=web --install-deps
```

## Protection and Safety

### Kill Switch Options

#### `--kill-switch-abs <size>`
Terminate debug pods when available disk space falls below absolute threshold.

**Supported units:** `B`, `K`, `Ki`, `M`, `Mi`, `G`, `Gi`, `T`, `Ti`

**Examples:**
```bash
# 1 Gigabyte threshold
./kube-dump.sh -l app=web --kill-switch-abs 1GB --pod-volume /tmp

# 500 Megabytes
./kube-dump.sh -l app=web --kill-switch-abs 500MB --pod-volume /tmp

# Binary units (1024-based)
./kube-dump.sh -l app=web --kill-switch-abs 1Gi --pod-volume /tmp
```

#### `--kill-switch-rel <percentage>`
Terminate debug pods when available disk space falls below relative threshold.

**Examples:**
```bash
# 10% free space threshold
./kube-dump.sh -l app=web --kill-switch-rel 10% --pod-volume /tmp

# 5% threshold for nodes
./kube-dump.sh -L worker=true --kill-switch-rel 5% --node-volume /var
```

### Volume Monitoring

#### `--pod-volume <path>`
Volume path to monitor for pod-based kill switches.

**Examples:**
```bash
# Monitor /tmp in pods
./kube-dump.sh -l app=web --kill-switch-abs 1GB --pod-volume /tmp

# Monitor custom mount
./kube-dump.sh -l app=web --kill-switch-rel 10% --pod-volume /data
```

#### `--node-volume <path>`
Host volume path to monitor for node-based kill switches.

**Examples:**
```bash
# Monitor /var on nodes
./kube-dump.sh -L worker=true --kill-switch-abs 2GB --node-volume /var

# Monitor root filesystem
./kube-dump.sh -L worker=true --kill-switch-rel 15% --node-volume /
```

## Behavior Options

### Cleanup Control

#### `--no-cleanup`
Keep debug pods running after command execution.

**Examples:**
```bash
# Keep pods for manual inspection
./kube-dump.sh -l app=web --no-cleanup

# Inspect debug pods manually
kubectl get pods -l kube-dump=debug

# Clean up manually later
kubectl delete pods -l kube-dump=debug
```

### Output Format

#### `--no-glyphs`
Disable emojis and use text labels for terminal compatibility.

**Examples:**
```bash
# Text-only output
./kube-dump.sh -l app=web --no-glyphs

# Good for log files and CI/CD
./kube-dump.sh -l app=web --no-glyphs -o ./logs
```

**Output format comparison:**
```bash
# With emojis (default)
🎯 Found 3 pods matching label: app=web
📦 Creating debug pod...
✅ Debug pod ready

# Without emojis (--no-glyphs)
[TARGET] Found 3 pods matching label: app=web
[INFO] Creating debug pod...
[OK] Debug pod ready
```

## Help and Information

#### `-h, --help`
Display help information and usage examples.

```bash
./kube-dump.sh --help
./kube-dump.sh -h
```

## Advanced Usage Patterns

### Combined Operations
```bash
# Pod and node operations with kill switches
./kube-dump.sh \
  -l app=database \
  -L worker=true \
  --include-nodes \
  -e 'tcpdump -i any port 5432 -w pod-%.pcap -c 1000' \
  -E 'tcpdump -i eth0 port 5432 -w node-%.pcap -c 1000' \
  -s 'ls *.pcap' \
  -S 'ls *.pcap' \
  --kill-switch-abs 500MB \
  --pod-volume /tmp \
  --node-volume /var \
  -o ./database-debug
```

### Production Safety
```bash
# Safe production debugging with limits
./kube-dump.sh \
  -l app=critical-service \
  -n production \
  --to-namespace monitoring \
  -e 'tcpdump -i any -c 100 -w %.pcap' \
  --kill-switch-rel 10% \
  --pod-volume /tmp \
  --no-glyphs \
  -o ./prod-debug-$(date +%Y%m%d)
```