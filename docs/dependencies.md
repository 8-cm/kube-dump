# Dependencies

Complete list of all dependencies required to run kube-dump.

## Table of Contents

1. [Host System Requirements](#host-system-requirements)
2. [Container Image Requirements](#container-image-requirements)
3. [Optional Dependencies](#optional-dependencies)
4. [Kubernetes/OpenShift Requirements](#kubernetes-openshift-requirements)

## Host System Requirements

### Required on the Host Running kube-dump.sh

These tools must be installed on the machine where you execute `kube-dump.sh`:

#### Kubernetes CLI (Required - One of)
- **kubectl** (Kubernetes CLI) - Any recent version
- **oc** (OpenShift CLI) - Version 4.x or higher

The script automatically detects which CLI is available.

#### Core UNIX Utilities (Required)
These are standard on all Linux/macOS systems:

- **bash** (version 4.0+) - Shell interpreter
- **grep** - Text pattern matching
- **sed** - Stream editor
- **cut** - Text column extraction
- **tr** - Character translation
- **awk** - Text processing
- **date** - Date/time operations
- **echo** - Output text
- **cat** - Concatenate files
- **mkdir** - Create directories
- **base64** - Base64 encoding/decoding
- **mktemp** - Create temporary files/directories

#### Hashing Utilities (Required - One of)
Used for generating unique pod names:

- **md5sum** (Linux standard), OR
- **md5** (macOS standard), OR
- **cksum** (fallback, universally available)

The script tries md5sum first, then md5, then falls back to cksum.

#### Optional Host Utilities
- **curl** or **wget** - For crictl installation when using `--install-deps`
- **jq** - JSON parsing (not required, script has fallbacks)

## Container Image Requirements

### Default Debug Image: nicolaka/netshoot

The default image (`nicolaka/netshoot`) includes all necessary tools.

**📦 For building custom images, see [Custom Images Guide](custom-images.md)** for exact package lists and Dockerfile examples.

If using a custom image via `--image`, it must contain:

#### Required Tools in Debug/Discovery Pods

**Essential Commands:**
- **bash** or **sh** - Shell interpreter
- **base64** - Command decoding
- **nsenter** - Namespace operations (for pod debugging)
- **grep**, **sed**, **cut**, **tr** - Text processing
- **cat**, **echo** - Basic I/O
- **date** - Timestamp generation
- **tail** - Keep pods alive

**For Network Debugging:**
- **tcpdump** - Default network capture tool
- **ip** - Network configuration
- **ss** or **netstat** - Network statistics
- **ping** - Connectivity testing

**For CRI Operations (with --install-deps or pre-installed):**
- **crictl** - Container runtime CLI (auto-installed if `--install-deps` used)
- **curl** OR **wget** - For crictl download (if using `--install-deps`)
- **tar** - Extract crictl archive

### Kill Switch Monitor Image: ubuntu:22.04

Used for kill switch monitor pods. Requires:

**Essential:**
- **bash** - Shell interpreter
- **df** - Disk usage reporting
- **kubectl** or **oc** - Pod termination (inherits from host via service account)

**Recommended:**
- **bc** - Floating-point calculations for percentage thresholds
  - Without `bc`, only absolute thresholds (`--kill-switch-abs`) work
  - Relative thresholds (`--kill-switch-rel`) require `bc`

## Optional Dependencies

### Feature-Specific Dependencies

#### 1. Kill Switch Auto-Detection
**Requirement:** Access to kubelet configz endpoint

```bash
kubectl get --raw "/api/v1/nodes/{node-name}/proxy/configz"
```

**Used for:** Auto-detecting kubelet eviction thresholds
**Fallback:** Uses 10% if detection fails
**Required permissions:** Read access to node proxy endpoints

#### 2. Relative Kill Switch Thresholds
**Requirement:** `bc` calculator in kill switch monitor pods

**Usage:** For percentage-based thresholds like `--kill-switch-rel 10%`
**Image:** ubuntu:22.04 (used for kill switch monitors)
**Fallback:** Use absolute thresholds (`--kill-switch-abs 1GB`) instead

#### 3. CRI Tools Auto-Installation
**Requirements when using `--install-deps`:**
- **curl** OR **wget** - Download crictl
- **tar** - Extract archive
- **Internet access** - Download from github.com

**Downloads:** crictl v1.28.0 from:
```
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz
```

**Alternative:** Pre-install crictl in custom debug image

#### 4. Verbose Logging
**Requirement:** `-o/--output` directory path

**Usage:** `--verbose` flag requires output directory
**Storage:** Logs saved to `OUTPUT_DIR/debug/*.{stdout,stderr}.log`
**No fallback:** Verbose mode disabled without output directory

## Kubernetes/OpenShift Requirements

### RBAC Permissions Required

The user/service account running kube-dump needs:

#### Pod Operations
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-dump-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "create", "delete"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

#### Node Access (for kill switch auto-detection)
```yaml
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy"]
  verbs: ["get"]
```

### Pod Security Standards

**Requirements:**
- **Namespace must allow privileged pods** for debug operations
- Recommended: `pod-security.kubernetes.io/enforce: privileged`

**Example:**
```bash
kubectl label namespace argocd pod-security.kubernetes.io/enforce=privileged
```

### Cluster Configuration

**Supported:**
- Kubernetes 1.20+
- OpenShift 4.x+
- Container runtimes: containerd, CRI-O, Docker (via cri-dockerd)

**Network:**
- Host network access for debug pods
- Access to container runtime sockets on nodes

## Summary Tables

### Required on Host

| Tool | Purpose | Fallback |
|------|---------|----------|
| kubectl/oc | Kubernetes operations | None - required |
| bash | Script execution | None - required |
| grep/sed/cut/tr | Text processing | None - required |
| base64 | Command encoding | None - required |
| md5sum/md5/cksum | Pod name hashing | Tries all three |

### Required in Debug Containers

| Tool | Purpose | Default Image | Custom Image |
|------|---------|---------------|--------------|
| bash/sh | Script execution | ✅ | Required |
| nsenter | Namespace operations | ✅ | Required |
| tcpdump | Network capture | ✅ | Optional¹ |
| crictl | Container operations | ✅² | Optional³ |

¹ Only if using network capture features
² Pre-installed in nicolaka/netshoot
³ Auto-installed with `--install-deps` or must be pre-installed

### Optional Dependencies

| Feature | Requires | Without It |
|---------|----------|------------|
| Kill switch auto-detect | Node proxy access | Falls back to 10% |
| Relative kill switch | `bc` in ubuntu:22.04 | Use absolute thresholds |
| CRI tools install | curl/wget + internet | Pre-install crictl |
| Verbose logging | `-o` output directory | No verbose logs |

## Verification Commands

Check if you have all required host dependencies:

```bash
# Check Kubernetes CLI
kubectl version --client || oc version --client

# Check core utilities
for cmd in bash grep sed cut tr awk date base64 cat mkdir; do
  command -v $cmd && echo "✓ $cmd" || echo "✗ $cmd MISSING"
done

# Check hashing utilities (need at least one)
command -v md5sum || command -v md5 || command -v cksum

# Check optional utilities
for cmd in curl wget jq; do
  command -v $cmd && echo "✓ $cmd (optional)" || echo "○ $cmd (optional, not found)"
done
```

Check Kubernetes cluster requirements:

```bash
# Check cluster access
kubectl cluster-info

# Check if you can create privileged pods
kubectl auth can-i create pods --as=system:serviceaccount:default:default

# Check pod exec permissions
kubectl auth can-i create pods/exec --as=system:serviceaccount:default:default

# Check node proxy access (for kill switch auto-detection)
kubectl auth can-i get nodes/proxy --as=system:serviceaccount:default:default
```

## Container Runtime Socket Paths

Default socket paths for different runtimes:

| Runtime | Socket Path | Used By |
|---------|-------------|---------|
| containerd | `/run/containerd/containerd.sock` | crictl |
| CRI-O | `/run/crio/crio.sock` | crictl |
| Docker | `/var/run/cri-dockerd.sock` | crictl |

Override with `--cri-socket` if using non-standard paths.
