# kube-dump

A powerful Kubernetes debugging tool that enables network capture, command execution, and file operations across multiple pods and nodes simultaneously through privileged debug pods.

## Quick Start

```bash
# Clone and setup
git clone <repository-url> && cd kube-dump && chmod +x kube-dump.sh

# Basic network capture on labeled pods
./kube-dump.sh -l app=nginx

# Capture from all pods with default label and save files
./kube-dump.sh -e 'tcpdump -i any -w capture.pcap -c 100' -s '*.pcap' -o ./captures
```

## Use Cases

| Scenario | Command |
|----------|---------|
| 🔍 **Network troubleshooting** | `./kube-dump.sh -l app=web -e 'tcpdump -i any port 80'` |
| 🖥️ **Node-level debugging** | `./kube-dump.sh -L worker=true -E 'ss -tuln'` |
| 📦 **Generate and collect files** | `./kube-dump.sh -l app=api -e 'netstat > report.txt' -s '*.txt' -o ./reports` |
| ⚡ **Mixed pod and node operations** | `./kube-dump.sh -l app=db --include-nodes -e 'tcpdump port 5432' -E 'tcpdump port 5432'` |

## Key Features

- 🎯 **Multi-target execution**: Run commands on multiple pods/nodes simultaneously
- 🏷️ **Label-based targeting**: Use Kubernetes labels to select resources
- 📦 **Automatic file collection**: Generate and download files from debug sessions
- 🛡️ **Kill switch protection**: Prevent disk pressure with usage thresholds
- 🔧 **Runtime flexibility**: Support for containerd, crio, docker
- 🚀 **Auto-cleanup**: Clean up debug pods after execution

## Documentation

📖 **[Complete Documentation](docs/)** | 🏗️ **[Architecture](docs/kube-dump-architecture.md)** | 🔒 **[Security Reports](docs/security-reports.md)**

## Installation Requirements

- Kubernetes 1.16+ with cluster-admin permissions
- `kubectl` or `oc` CLI configured
- Ability to create privileged pods and access container runtimes

---

<!-- SHELLCHECK-RESULTS-START -->
## 🔍 Code Quality - Shellcheck Analysis

**Status:** ✅ PASSED
**Issues Found:** 0
**Last Updated:** 2025-09-12 18:00:00 UTC
**Commit:** [`34d5771`](https://github.com/8-cm/kube-dump/commit/34d5771)

🎉 **Excellent!** No shellcheck issues found. The script follows shell scripting best practices.

---
*This section is automatically updated by the [Shellcheck Analysis workflow](.github/workflows/shellcheck.yml)*
<!-- SHELLCHECK-RESULTS-END -->

<!-- TRIVY-SECURITY-START -->
## 🛡️ Security Analysis - Trivy Scanning

**Overall Status:** ✅ NO CRITICAL ISSUES
**Critical Issues:** 0
**High Severity:** 0
**Medium Severity:** 0
**Low Severity:** 0
**Config Issues:** 0
**Filesystem Vulns:** 0
**Last Updated:** 2025-09-12 18:30:00 UTC
**Commit:** [`34d5771`](https://github.com/8-cm/kube-dump/commit/34d5771)

🎉 **Great!** No critical or high severity vulnerabilities found in container images and filesystem.

### Scanning Coverage
- **🖼️ Container Images**: All images used in kube-dump.sh
- **📋 SBOM Analysis**: Software Bill of Materials vulnerability checking
- **📁 Filesystem**: Local files and configurations
- **⚙️ Configuration**: Security misconfigurations

---
*This section is automatically updated by the [Security Scanning workflow](.github/workflows/security-trivy.yml)*
<!-- TRIVY-SECURITY-END -->

---

**⚠️ Security Notice**: This tool creates privileged pods with extensive permissions. Review security implications before production use.