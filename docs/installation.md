# Installation Guide

## Prerequisites

### Cluster Requirements
- Kubernetes cluster (v1.16+) or OpenShift cluster
- Cluster access with appropriate permissions (see [Permissions](#permissions))
- Container runtime: containerd, CRI-O, or Docker

### Client Requirements
- `kubectl` (v1.16+) or `oc` (OpenShift CLI) installed and configured
- `bash` shell (v4.0+)
- `jq` for JSON processing (installed automatically if missing)
- Internet access for downloading debug container images

### Permissions

The user running kube-dump must have permissions to:

#### Required Permissions
- **Pod Management**: Create, list, delete pods in target namespaces
- **Privileged Access**: Create privileged pods with host access
- **Network Access**: Access pod network namespaces
- **File System Access**: Mount host file systems in containers
- **Logs Access**: Read pod logs for monitoring

#### RBAC Configuration
Example ClusterRole for kube-dump:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-dump-user
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["create", "delete", "get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-dump-user-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-dump-user
subjects:
- kind: User
  name: your-username
  apiGroup: rbac.authorization.k8s.io
```

## Installation

### Quick Setup
```bash
# Clone repository
git clone <repository-url>
cd kube-dump

# Make executable
chmod +x kube-dump.sh

# Verify installation
./kube-dump.sh --version
```

### Container Runtime Configuration

kube-dump automatically detects container runtimes, but you can specify manually:

#### Containerd
```bash
./kube-dump.sh -l app=web --cri-runtime containerd --cri-socket /run/containerd/containerd.sock
```

#### CRI-O
```bash
./kube-dump.sh -l app=web --cri-runtime crio --cri-socket /var/run/crio/crio.sock
```

#### Docker
```bash
./kube-dump.sh -l app=web --cri-runtime docker --cri-socket /var/run/docker.sock
```

## Configuration

### Environment Variables
- `DEBUG=1` - Enable verbose debugging output
- `KUBE_CLI` - Override CLI detection (kubectl/oc)
- `DEBUG_IMAGE` - Override default debug container image

### Default Settings
- **Debug Image**: `nicolaka/netshoot:latest`
- **Command**: `tcpdump -i any -w /tmp/dump.pcap`
- **Namespace**: `default`
- **Runtime Detection**: Automatic
- **Cleanup**: Enabled (use `--no-cleanup` to disable)

## Verification

### Test Basic Functionality
```bash
# Test with default settings
./kube-dump.sh -l dumpme=yes --dry-run

# Test cluster access
kubectl auth can-i create pods --all-namespaces
```

### Test Container Runtime Access
```bash
# Check runtime detection
./kube-dump.sh -l app=test --cri-runtime auto
```

### Validate Permissions
```bash
# Create a test pod to verify permissions
kubectl run kube-dump-test --image=nicolaka/netshoot --restart=Never --rm -it -- echo "Permission test successful"
```

## Troubleshooting Installation

### Permission Issues
```bash
# Check current user permissions
kubectl auth can-i '*' '*' --all-namespaces

# Check specific permissions needed by kube-dump
kubectl auth can-i create pods
kubectl auth can-i create pods --subresource=exec
```

### Runtime Detection Issues
```bash
# List available runtimes on nodes
kubectl get nodes -o wide

# Check runtime sockets
kubectl debug node/node-name -it --image=nicolaka/netshoot -- find /host -name "*.sock" | grep -E "(containerd|crio|docker)"
```

### Network/Image Access
```bash
# Test image pull
kubectl run image-test --image=nicolaka/netshoot --restart=Never --rm -it -- echo "Image accessible"

# Check node image cache
kubectl get nodes -o yaml | grep -E "(container-runtime|kubelet)"
```

## Next Steps

- Review [Command Reference](command-reference.md) for all available options
- Try [Examples](examples.md) for common use cases
- Understand [Architecture](kube-dump-architecture.md) for advanced usage

---

Need help? Check the [Troubleshooting](README.md#troubleshooting) section or open an issue.