# Custom Image Package Requirements

Exact package lists for building custom images for kube-dump.

## Table of Contents

1. [Debug/Discovery Pod Image](#debugdiscovery-pod-image)
2. [Kill Switch Monitor Image](#kill-switch-monitor-image)
3. [Complete Dockerfile Examples](#complete-dockerfile-examples)

---

## Debug/Discovery Pod Image

This image is used for:
- Debug pods (pod and node debugging)
- Discovery pods (file selection and download)

### Minimum Required Packages

| Command | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
|---------|------------------|-------------------------|----------------------|
| bash | `bash` | `bash` | `bash` |
| base64 | `coreutils` | `coreutils` | `coreutils` |
| cat | `coreutils` | `coreutils` | `coreutils` |
| echo | `coreutils` | `coreutils` | `coreutils` |
| date | `coreutils` | `coreutils` | `coreutils` |
| tail | `coreutils` | `coreutils` | `coreutils` |
| chmod | `coreutils` | `coreutils` | `coreutils` |
| mkdir | `coreutils` | `coreutils` | `coreutils` |
| nsenter | `util-linux` | `util-linux` | `util-linux` |
| sed | `sed` | `sed` | `sed` |
| tar | `tar` | `tar` | `tar` |

### Package Installation Commands

#### Alpine Linux (Minimal - 8 packages)
```dockerfile
RUN apk add --no-cache \
    bash \
    coreutils \
    util-linux \
    sed \
    tar
```

#### Debian/Ubuntu (Minimal - Already included in base)
```dockerfile
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    util-linux \
    sed \
    tar \
    && rm -rf /var/lib/apt/lists/*
```

#### RHEL/CentOS/Fedora (Minimal - Already included in base)
```dockerfile
RUN yum install -y \
    bash \
    coreutils \
    util-linux \
    sed \
    tar \
    && yum clean all
```

### Optional Packages for Enhanced Functionality

#### For --install-deps (CRI Tools Auto-Installation)

| Command | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
|---------|------------------|-------------------------|----------------------|
| curl | `curl` | `curl` | `curl` |
| wget | `wget` | `wget` | `wget` |

**Note:** Only need ONE of curl or wget.

```dockerfile
# Alpine - add curl OR wget
RUN apk add --no-cache curl
# OR
RUN apk add --no-cache wget

# Debian/Ubuntu
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# RHEL/Fedora
RUN yum install -y curl && yum clean all
```

#### For Network Debugging (Default tcpdump command)

| Tool | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
|------|------------------|-------------------------|----------------------|
| tcpdump | `tcpdump` | `tcpdump` | `tcpdump` |
| ip | `iproute2` | `iproute2` | `iproute2` |
| ss | `iproute2` | `iproute2` | `iproute2` |
| ping | `iputils` | `iputils-ping` | `iputils` |
| netstat | `net-tools` | `net-tools` | `net-tools` |

```dockerfile
# Alpine - network tools
RUN apk add --no-cache \
    tcpdump \
    iproute2 \
    iputils \
    net-tools

# Debian/Ubuntu - network tools
RUN apt-get update && apt-get install -y \
    tcpdump \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# RHEL/Fedora - network tools
RUN yum install -y \
    tcpdump \
    iproute2 \
    iputils \
    net-tools \
    && yum clean all
```

#### For Container Operations (CRI)

| Tool | Installation Method |
|------|---------------------|
| crictl | Use `--install-deps` flag (auto-downloads v1.28.0) |
| crictl | OR pre-install from https://github.com/kubernetes-sigs/cri-tools/releases |

**Auto-installation (requires curl/wget):**
```dockerfile
# Will be installed at runtime with --install-deps flag
# Requires curl or wget to be present
```

**Pre-installation:**
```dockerfile
RUN CRICTL_VERSION="v1.28.0" && \
    wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    tar zxvf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin && \
    rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
```

#### Useful Optional Tools

| Tool | Purpose | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
|------|---------|------------------|-------------------------|----------------------|
| jq | JSON parsing | `jq` | `jq` | `jq` |
| grep | Text search | `grep` | `grep` | `grep` |
| awk | Text processing | `gawk` | `gawk` | `gawk` |
| find | File search | `findutils` | `findutils` | `findutils` |

---

## Kill Switch Monitor Image

This image is used for disk usage monitoring pods.

### Required Packages

| Command | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) |
|---------|------------------|-------------------------|----------------------|
| bash | `bash` | `bash` | `bash` |
| cat | `coreutils` | `coreutils` | `coreutils` |
| echo | `coreutils` | `coreutils` | `coreutils` |
| date | `coreutils` | `coreutils` | `coreutils` |
| tail | `coreutils` | `coreutils` | `coreutils` |
| df | `coreutils` | `coreutils` | `coreutils` |

### Optional but Recommended

| Command | Package (Alpine) | Package (Debian/Ubuntu) | Package (RHEL/Fedora) | Required For |
|---------|------------------|-------------------------|-----------------------|--------------|
| bc | `bc` | `bc` | `bc` | Percentage thresholds (`--kill-switch-rel`) |
| awk | `gawk` | `gawk` | `gawk` | Calculations |

### Package Installation Commands

#### Alpine Linux (Minimal)
```dockerfile
FROM alpine:latest
RUN apk add --no-cache \
    bash \
    coreutils
```

#### Alpine Linux (With bc for percentage thresholds)
```dockerfile
FROM alpine:latest
RUN apk add --no-cache \
    bash \
    coreutils \
    bc \
    gawk
```

#### Ubuntu (Minimal - Already has required tools)
```dockerfile
FROM ubuntu:22.04
# bash and coreutils already included
```

#### Ubuntu (With bc for percentage thresholds)
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    bc \
    && rm -rf /var/lib/apt/lists/*
```

**Note:** kubectl/oc is NOT installed in the container. The monitor pod uses the cluster's service account to access the Kubernetes API.

---

## Complete Dockerfile Examples

### Example 1: Minimal Debug Image (Alpine)

**Size:** ~50MB
**Capabilities:** Basic debugging, file operations

```dockerfile
FROM alpine:3.19

# Install minimal required packages
RUN apk add --no-cache \
    bash \
    coreutils \
    util-linux \
    sed \
    tar \
    curl

WORKDIR /

CMD ["/bin/bash"]
```

**Usage:**
```bash
docker build -t my-minimal-debug:latest -f Dockerfile.minimal .
./kube-dump.sh -l app=nginx --image my-minimal-debug:latest
```

### Example 2: Full-Featured Debug Image (Alpine)

**Size:** ~150MB
**Capabilities:** Network debugging, CRI operations, file operations

```dockerfile
FROM alpine:3.19

# Install all useful packages
RUN apk add --no-cache \
    bash \
    coreutils \
    util-linux \
    sed \
    tar \
    curl \
    wget \
    tcpdump \
    iproute2 \
    iputils \
    net-tools \
    bind-tools \
    jq \
    grep \
    gawk \
    findutils

# Pre-install crictl (optional, can use --install-deps instead)
ARG CRICTL_VERSION=v1.28.0
RUN wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    tar zxf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin && \
    rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    chmod +x /usr/local/bin/crictl

WORKDIR /

CMD ["/bin/bash"]
```

**Usage:**
```bash
docker build -t my-debug:latest -f Dockerfile.full .
./kube-dump.sh -l app=nginx --image my-debug:latest
```

### Example 3: Debian-based Debug Image

**Size:** ~200MB
**Capabilities:** Full network debugging with Debian ecosystem

```dockerfile
FROM debian:12-slim

# Install all useful packages
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    util-linux \
    sed \
    tar \
    curl \
    wget \
    tcpdump \
    iproute2 \
    iputils-ping \
    net-tools \
    dnsutils \
    jq \
    gawk \
    findutils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pre-install crictl
ARG CRICTL_VERSION=v1.28.0
RUN wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    tar zxf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin && \
    rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    chmod +x /usr/local/bin/crictl

WORKDIR /

CMD ["/bin/bash"]
```

### Example 4: Kill Switch Monitor Image (Ubuntu)

**Size:** ~80MB with bc
**Capabilities:** Disk monitoring with percentage calculations

```dockerfile
FROM ubuntu:22.04

# Install required packages for kill switch monitoring
RUN apt-get update && apt-get install -y \
    bc \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /

CMD ["/bin/bash"]
```

**Usage:**
```bash
# Note: Cannot override kill switch monitor image via CLI
# It uses ubuntu:22.04 by default
# If you want custom image, modify kube-dump.sh:
# Change line with "image: ubuntu:22.04" in build_kill_switch_monitor_script
```

### Example 5: Ultra-Minimal (BusyBox)

**Size:** ~5MB (Not recommended - missing nsenter)
**Limitations:** No nsenter, limited functionality

```dockerfile
FROM busybox:latest

# BusyBox includes basic tools but LACKS nsenter
# NOT RECOMMENDED for kube-dump
# Only works for node-level debugging with -E/--node-execute

CMD ["/bin/sh"]
```

**Not recommended because:** BusyBox lacks `nsenter` which is critical for pod network namespace debugging.

---

## Package Comparison Table

| Feature | Minimal Alpine | Full Alpine | Debian/Ubuntu | nicolaka/netshoot |
|---------|----------------|-------------|---------------|-------------------|
| **Size** | ~50MB | ~150MB | ~200MB | ~400MB |
| **Pod debugging** | ✅ | ✅ | ✅ | ✅ |
| **Node debugging** | ✅ | ✅ | ✅ | ✅ |
| **Network capture** | ❌¹ | ✅ | ✅ | ✅ |
| **CRI operations** | ⚠️² | ✅ | ✅ | ✅ |
| **Advanced networking** | ❌ | ✅ | ✅ | ✅ |
| **File operations** | ✅ | ✅ | ✅ | ✅ |

¹ Add tcpdump package for network capture

² Use `--install-deps` flag or pre-install crictl

---

## Testing Your Custom Image

Test if your custom image has all required tools:

```bash
# Test required commands
docker run --rm your-image:tag /bin/sh -c '
  command -v bash && echo "✓ bash" || echo "✗ bash MISSING"
  command -v nsenter && echo "✓ nsenter" || echo "✗ nsenter MISSING"
  command -v base64 && echo "✓ base64" || echo "✗ base64 MISSING"
  command -v sed && echo "✓ sed" || echo "✗ sed MISSING"
  command -v tar && echo "✓ tar" || echo "✗ tar MISSING"
'

# Test optional commands
docker run --rm your-image:tag /bin/sh -c '
  command -v tcpdump && echo "✓ tcpdump" || echo "○ tcpdump (optional)"
  command -v curl && echo "✓ curl" || echo "○ curl (optional)"
  command -v crictl && echo "✓ crictl" || echo "○ crictl (optional)"
'

# Test with kube-dump
./kube-dump.sh -l app=test --image your-image:tag -e "echo test"
```

---

## Recommendations

### For Most Users
**Use nicolaka/netshoot** - It has everything and is well-maintained.

### For Size-Conscious Deployments
**Use Full Alpine example** (~150MB) - Good balance of size and features.

### For Maximum Compatibility
**Use Debian/Ubuntu example** (~200MB) - More packages available, better compatibility.

### For Kill Switch Monitors
**Use ubuntu:22.04 with bc** - Default choice, works perfectly.

---

## Quick Reference: Minimum Packages

### Debug/Discovery Pods
```
bash, coreutils, util-linux, sed, tar
Optional: curl/wget (for --install-deps)
Optional: tcpdump, iproute2 (for network debugging)
```

### Kill Switch Monitors
```
bash, coreutils
Optional: bc (for percentage thresholds)
```
