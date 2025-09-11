# kube-dump

A powerful Kubernetes debugging tool that enables network capture, command execution, and file operations across multiple pods and nodes simultaneously through privileged debug pods.

## 🚀 Overview

`kube-dump` simplifies complex Kubernetes debugging scenarios by:
- **Multi-target execution**: Run commands on multiple pods or nodes simultaneously
- **Network capture**: Capture network traffic with tcpdump across container network namespaces
- **Flexible targeting**: Use label selectors to target multiple resources at once
- **File operations**: Generate files during execution and download them automatically
- **Cross-namespace support**: Create debug pods in different namespaces
- **Runtime flexibility**: Support for multiple container runtimes (containerd, crio, docker)

## 📋 Features

### Core Capabilities
- 🎯 **Pod-based debugging**: Execute commands within pod network namespaces
- 🖥️ **Node-based debugging**: Run host-level commands with privileged access
- 🔀 **Mixed mode**: Combine pod and node operations in a single session
- 📦 **File downloads**: Automatically collect generated files from debug sessions
- 🏷️ **Label-based targeting**: Use Kubernetes labels to select multiple targets
- 🔄 **Placeholder substitution**: Dynamic hostname replacement in commands

### Advanced Features
- 🚀 **Automatic cleanup**: Clean up debug pods after execution (configurable)
- 🔧 **Runtime detection**: Automatically detect and configure container runtime
- 📁 **Cross-namespace operations**: Create debug pods in specified namespaces
- ⚙️ **Custom commands**: Execute any command instead of default tcpdump
- 🔗 **Node auto-inclusion**: Automatically include nodes hosting selected pods

## 🛠️ Installation

### Prerequisites
- Kubernetes cluster access with appropriate permissions
- `kubectl` or `oc` (OpenShift CLI) installed and configured
- Cluster-admin or sufficient RBAC permissions to:
  - Create privileged pods
  - Access pod network namespaces
  - Mount host filesystems
  - Inspect container runtimes

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd kube-dump

# Make the script executable
chmod +x kube-dump.sh

# Verify your cluster access
kubectl auth can-i create pods --all-namespaces
```

## 🎯 Usage

### Basic Syntax
```bash
# Pod-based debugging
./kube-dump.sh [-l <label_selector>] [-n <namespace>] [-e <command>]

# Node-based debugging  
./kube-dump.sh [-L <node_label>] [-E <node_execute>]

# Show help
./kube-dump.sh -h
```

### Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-l, --label` | Pod label selector | `dumpme=yes` |
| `-L, --node-label` | Node label selector | None |
| `-n, --namespace` | Target namespace | Current namespace |
| `--to-namespace` | Debug pod namespace | Same as target |
| `-e, --execute` | Pod command | `tcpdump -i any -nn -s 0` |
| `-E, --node-execute` | Node command | `tcpdump -i any -nn -s 0` |
| `-s, --select-to-download` | Pod file selection command | None |
| `-S, --node-select-to-download` | Node file selection command | None |
| `-o, --output` | Download directory | None |
| `-I, --placeholder` | Hostname placeholder character | `%` |
| `--cri` | Container runtime | `containerd` |
| `--cri-socket` | Custom CRI socket path | Auto-detected |
| `--install-deps` | Auto-install CRI tools | Disabled |
| `--no-cleanup` | Keep debug pods running | Disabled |
| `--include-nodes` | Auto-include pod nodes | Disabled |

## 📚 Examples

### Basic Network Capture
```bash
# Capture traffic from all pods with default label
./kube-dump.sh

# Capture from specific application pods
./kube-dump.sh -l app=nginx

# Capture from multiple labels
./kube-dump.sh -l 'tier=frontend,env=prod'
```

### Custom Commands
```bash
# Run custom network analysis
./kube-dump.sh -l app=web -e 'ss -tuln'

# Capture specific traffic patterns
./kube-dump.sh -l app=api -e 'tcpdump -i any -c 100 host 10.1.1.1'

# Complex command with pipes
./kube-dump.sh -l app=web -e 'netstat -i | grep -v lo'
```

### Node-Level Operations
```bash
# Monitor worker nodes
./kube-dump.sh -L node-role.kubernetes.io/worker

# Custom node command
./kube-dump.sh -L worker=true -E 'ss -tuln'

# Network diagnostics on control plane
./kube-dump.sh -L node-role.kubernetes.io/control-plane=true -E 'netstat -i'
```

### File Operations
```bash
# Generate and download pod files
./kube-dump.sh -l app=web \
  -e 'tcpdump -i any -w %.pcap -c 100' \
  -s 'ls *.pcap' \
  -o ./captures

# Generate node files with custom placeholder
./kube-dump.sh -L worker=true \
  -E 'ss -tuln > @-ports.txt' \
  -S 'ls @-ports.txt' \
  -I@ -o ./node-files
```

### Cross-Namespace Operations
```bash
# Debug production pods from monitoring namespace
./kube-dump.sh -l app=backend \
  -n production \
  --to-namespace monitoring

# Mixed pod and node operations
./kube-dump.sh -l app=web -L worker=true \
  -e 'tcpdump -i any -c 50' \
  -E 'tcpdump -i eth0 -c 50'
```

### Advanced Scenarios
```bash
# Include nodes hosting selected pods
./kube-dump.sh -l app=database --include-nodes \
  -e 'tcpdump -i any port 5432' \
  -E 'tcpdump -i any port 5432'

# Custom container runtime
./kube-dump.sh -l app=web --cri crio -e 'ss -tuln'

# Custom CRI socket path
./kube-dump.sh -l app=web --cri-socket /var/run/podman/podman.sock

# Keep debug pods for manual inspection
./kube-dump.sh -l app=api --no-cleanup \
  -e 'tcpdump -i any -w capture.pcap'
```

## 🔧 How It Works

### Pod-Based Debugging
1. **Discovery**: Uses label selectors to find target pods
2. **Debug Pod Creation**: Creates privileged debug pods on the same nodes
3. **Network Namespace Access**: Uses `nsenter` to enter target pod network namespaces
4. **Command Execution**: Runs commands within the isolated network context
5. **File Collection**: Optionally downloads generated files
6. **Cleanup**: Removes debug pods (unless `--no-cleanup` is used)

### Node-Based Debugging
1. **Node Selection**: Identifies nodes using label selectors
2. **Privileged Pod Deployment**: Creates debug pods with host networking
3. **Host Access**: Mounts host filesystem and network interfaces
4. **Command Execution**: Runs commands with host-level access
5. **File Operations**: Collects files from host filesystem
6. **Resource Cleanup**: Cleans up debug resources

### Technical Implementation

#### Container Runtime Support
- **containerd**: Uses `/host/run/containerd/containerd.sock`
- **CRI-O**: Uses `/host/run/crio/crio.sock`  
- **Docker**: Uses `/host/var/run/cri-dockerd.sock`
- **Custom Socket**: Use `--cri-socket` for non-standard paths
- **Auto-detection**: Automatically detects available runtime and socket

#### Security Model
- Requires privileged pod creation permissions
- Uses host PID and network namespaces for node operations
- Mounts container runtime sockets for pod network access
- Implements cleanup mechanisms to prevent resource leaks

#### File Download Process
1. Creates additional "discovery" debug pods
2. Executes file selection commands (`-s` or `-S`)
3. Uses `kubectl cp` to download discovered files
4. Organizes files by pod/node in output directory
5. Provides detailed download reports

## ⚠️ Important Considerations

### Security
- **Privileged Access**: Script creates privileged pods with extensive permissions
- **Host Access**: Node operations have full host filesystem access
- **Network Isolation**: Pod operations respect container network boundaries
- **Permission Requirements**: Requires cluster-admin or equivalent permissions

### Resource Management
- **Automatic Cleanup**: Debug pods are removed after execution by default
- **Resource Limits**: No built-in limits on debug pod resource usage
- **Namespace Isolation**: Debug pods can be created in separate namespaces
- **Concurrent Operations**: Supports multiple simultaneous debug sessions

### Limitations
- **Kubernetes Version**: Requires Kubernetes 1.16+ for debug pod features
- **Network Policies**: May be affected by strict network policies
- **Container Runtime**: Requires compatible CRI implementation
- **Node Access**: Some nodes may restrict privileged pod scheduling

## 🐛 Troubleshooting

### Common Issues

#### "Permission denied" errors
```bash
# Check cluster permissions
kubectl auth can-i create pods --all-namespaces
kubectl auth can-i create pods --subresource=exec
```

#### Debug pods stay in "Pending" state
```bash
# Check node resources and constraints
kubectl describe pod <debug-pod-name>

# Verify privileged pod policies
kubectl get podsecuritypolicy
```

#### Container runtime detection issues
```bash
# Specify runtime explicitly
./kube-dump.sh -l app=web --cri containerd

# Check available runtime sockets on nodes
./kube-dump.sh -L worker=true -E 'ls -la /var/run/ | grep -E "(containerd|crio|docker)"'
```

### Debug Mode
```bash
# Enable verbose output
export DEBUG=1
./kube-dump.sh -l app=web

# Keep debug pods for inspection
./kube-dump.sh -l app=web --no-cleanup
kubectl logs <debug-pod-name>
```

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request with detailed description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Check existing documentation and examples
- Review troubleshooting section above

---

**Note**: This tool creates privileged pods with extensive permissions. Always review and understand the security implications before use in production environments.