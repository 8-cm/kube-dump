# Installation Guide

Complete installation and setup guide for kube-dump.

## Prerequisites

### Kubernetes Cluster Requirements
- **Kubernetes Version**: 1.16 or later (required for debug pod features)
- **Cluster Access**: `kubectl` or `oc` (OpenShift CLI) installed and configured
- **Network Policies**: May require adjustment for strict network policy environments

### Required Permissions
The script requires cluster-admin or equivalent permissions to:
- ✅ Create privileged pods across namespaces
- ✅ Access pod network namespaces via container runtime
- ✅ Mount host filesystems for node-level operations
- ✅ Inspect and interact with container runtimes (containerd, crio, docker)
- ✅ Execute commands in debug pods
- ✅ Download files from debug pods using `kubectl cp`

### Verify Cluster Access
```bash
# Check basic pod creation permissions
kubectl auth can-i create pods --all-namespaces

# Check privileged pod permissions
kubectl auth can-i create pods --subresource=exec

# Check if you can create privileged pods (cluster-admin typically required)
kubectl auth can-i create podsecuritypolicy

# Test basic cluster connectivity
kubectl get nodes
```

## Installation

### Method 1: Git Clone (Recommended)
```bash
# Clone the repository
git clone <repository-url>
cd kube-dump

# Make the script executable
chmod +x kube-dump.sh

# Verify installation
./kube-dump.sh --help
```

### Method 2: Direct Download
```bash
# Download the script directly
curl -O <raw-script-url>/kube-dump.sh
chmod +x kube-dump.sh

# Verify the script
./kube-dump.sh --help
```

### Method 3: System-Wide Installation
```bash
# Install globally (optional)
sudo cp kube-dump.sh /usr/local/bin/kube-dump
sudo chmod +x /usr/local/bin/kube-dump

# Use from anywhere
kube-dump --help
```

## Container Runtime Configuration

### Automatic Detection
kube-dump automatically detects available container runtimes:
```bash
# Let kube-dump auto-detect runtime
./kube-dump.sh -l app=web

# Check what runtime was detected
./kube-dump.sh -l app=web --debug
```

### Manual Runtime Configuration
Override automatic detection when necessary:

#### Containerd (Default)
```bash
./kube-dump.sh -l app=web --cri containerd
```

#### CRI-O
```bash
./kube-dump.sh -l app=web --cri crio
```

#### Docker (via cri-dockerd)
```bash
./kube-dump.sh -l app=web --cri docker
```

### Custom Socket Paths
For non-standard runtime socket locations:
```bash
# Custom containerd socket
./kube-dump.sh -l app=web --cri-socket /custom/path/containerd.sock

# Custom CRI-O socket
./kube-dump.sh -l app=web --cri-socket /var/run/crio/crio.sock

# Custom Docker socket
./kube-dump.sh -l app=web --cri-socket /var/run/docker.sock
```

## Validation and Testing

### Basic Functionality Test
```bash
# Test with minimal command (uses default labels)
./kube-dump.sh

# If no pods found, create a test pod
kubectl run test-pod --image=nginx --labels="dumpme=yes"

# Test again
./kube-dump.sh
```

### Permission Validation
```bash
# Test privileged pod creation
kubectl run test-debug --rm -it --image=nicolaka/netshoot \
  --privileged --overrides='{"spec":{"hostNetwork":true}}' \
  -- /bin/bash

# If successful, clean up
kubectl delete pod test-debug --ignore-not-found
```

### Container Runtime Validation
```bash
# Check available runtime sockets on nodes
./kube-dump.sh -L worker=true -E 'ls -la /var/run/ | grep -E "(containerd|crio|docker)"'
```

## Environment Setup

### Optional Environment Variables
```bash
# Enable debug mode for troubleshooting
export DEBUG=1

# Set default output directory
export KUBE_DUMP_OUTPUT_DIR="./kube-dump-sessions"

# Set default namespace
export KUBE_DUMP_NAMESPACE="default"
```

### Bash Completion (Optional)
```bash
# Add to ~/.bashrc or ~/.bash_profile
complete -W "--help --label --node-label --namespace --to-namespace --execute --node-execute --select-to-download --node-select-to-download --output --placeholder --cri --cri-socket --install-deps --no-cleanup --include-nodes --kill-switch-abs --kill-switch-rel --pod-volume --node-volume --no-glyphs" kube-dump.sh
```

## Troubleshooting Installation

### Common Issues

#### Permission Denied
```bash
# Error: cannot create privileged pods
# Solution: Ensure you have cluster-admin permissions
kubectl auth can-i '*' '*' --all-namespaces
```

#### Runtime Detection Failure
```bash
# Error: cannot detect container runtime
# Solution: Specify runtime manually
./kube-dump.sh -l app=web --cri containerd
```

#### Network Policy Restrictions
```bash
# Error: debug pods cannot communicate
# Solution: Check network policies
kubectl get networkpolicy --all-namespaces
```

#### Pod Security Policy Issues
```bash
# Error: privileged pods blocked
# Solution: Check pod security policies
kubectl get podsecuritypolicy
kubectl describe podsecuritypolicy <policy-name>
```

### Validation Commands
```bash
# Check cluster version
kubectl version --short

# Check node container runtime
kubectl get nodes -o wide

# Check existing pod security contexts
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# Test CRI tools installation
./kube-dump.sh -l app=web --install-deps
```

## Next Steps

After successful installation:
1. 📖 Review the [Quick Start Guide](quick-start.md)
2. 🧪 Try the [Examples](examples.md)
3. 📚 Read the [Command Reference](command-reference.md)
4. 🔧 Check [Usage Patterns](usage-patterns.md) for best practices