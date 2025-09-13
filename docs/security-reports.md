# Security & Code Quality Reports

This page contains automated security analysis and code quality reports for kube-dump.

## Overview

kube-dump undergoes continuous security scanning and code quality analysis:

- **🛡️ Container Security**: Vulnerability scanning of all container images used
- **📋 SBOM Analysis**: Software Bill of Materials for supply chain security
- **📁 Repository Security**: Static analysis of repository files and configurations
- **🔍 Code Quality**: Shell script analysis with ShellCheck

## Security Analysis Pipeline

Our security pipeline runs automatically on:
- Every push to master/main branch
- Pull requests to master/main branch
- Scheduled scans every 14 days
- Manual workflow dispatch

## Report Sections

Security scan results will appear below when the automated workflows complete their analysis.

---

<!-- TRIVY-SECURITY-START -->
## 🛡️ Security Analysis - Trivy Scanning

*Security scan results will appear here automatically when the pipeline runs.*

<!-- TRIVY-SECURITY-END -->

---

<!-- SHELLCHECK-RESULTS-START -->
## 🔍 Code Quality - Shellcheck Analysis

**Status:** ✅ PASSED  
**Issues Found:** 0  
**Last Updated:** 2025-09-13 19:07:13 UTC  
**Commit:** [`9bc12bf`](https://github.com/8-cm/kube-dump/commit/9bc12bf6e0a7104f254c00e33092324a00b9f93f)  

🎉 **Excellent!** No shellcheck issues found. The script follows shell scripting best practices.

---
*This section is automatically updated by the [Shellcheck Analysis workflow](.github/workflows/shellcheck.yml)*
<!-- SHELLCHECK-RESULTS-END -->


---

## Manual Security Review

### Container Images
kube-dump uses the following container images:
- **nicolaka/netshoot:latest** - Default debug container image
- User-configurable with `--image` parameter

### Privilege Requirements
kube-dump requires elevated privileges to:
- Create privileged pods with host access
- Mount host filesystems for file operations
- Access container runtime sockets for namespace operations
- Execute commands in pod network namespaces

### Security Best Practices

#### RBAC Configuration
Implement least-privilege RBAC:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-dump-user
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["create", "delete", "get", "list", "watch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
```

#### Network Policies
Consider implementing network policies to restrict debug pod communications:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: kube-dump-debug-pods
spec:
  podSelector:
    matchLabels:
      app: kube-dump-debug
  policyTypes:
  - Ingress
  - Egress
  egress:
  - {} # Allow all egress for debugging
```

#### Resource Limits
Apply resource limits to debug pods to prevent resource exhaustion:
```bash
# Example with resource constraints
./kube-dump.sh -l app=web --resource-limits "cpu=500m,memory=512Mi"
```

### Security Considerations

#### Data Exposure
- Debug pods have privileged access to host systems
- Network captures may contain sensitive data
- Downloaded files should be handled securely
- Log files may contain authentication tokens or secrets

#### Access Control
- Limit kube-dump usage to authorized personnel
- Use namespaced RBAC where possible
- Monitor debug pod creation and execution
- Implement session logging and audit trails

#### Kill Switch Protection
Always use kill switches in production environments:
```bash
# Recommended for production use
./kube-dump.sh -l app=prod --kill-switch-abs 1GB --kill-switch-rel 10
```

## Compliance & Auditing

### SOC 2 Considerations
- All debug operations are logged when using `-o` flag
- Kill switches provide automatic termination controls
- RBAC integration supports access control requirements
- Pod lifecycle management ensures resource cleanup

### GDPR & Data Privacy
- Network captures may contain personal data
- File downloads should be reviewed for sensitive content
- Session logs contain execution details and timestamps
- Implement data retention policies for debug outputs

## Vulnerability Disclosure

If you discover a security vulnerability in kube-dump:

1. **Do not** create a public GitHub issue
2. Email security details to: [security-contact-email]
3. Include steps to reproduce the vulnerability
4. Allow reasonable time for response and remediation

## Security Updates

- Subscribe to repository releases for security updates
- Monitor container image updates for nicolaka/netshoot
- Review security scan results after each update
- Test security controls in staging environments

---

*This page is automatically updated by the security scanning workflows. Last manual review: [Date]*