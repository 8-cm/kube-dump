# Usage Examples

Real-world examples and use cases for kube-dump.

## Network Debugging

### Basic Network Capture
```bash
# Capture traffic from all pods with default label
./kube-dump.sh

# Target specific application pods
./kube-dump.sh -l app=nginx -n production

# Capture specific port traffic
./kube-dump.sh -l app=web -e "tcpdump -i any port 8080 -w /tmp/port8080.pcap"
```

### Multi-Pod Network Analysis
```bash
# Capture from multiple microservices
./kube-dump.sh -l tier=frontend,version=v2

# Monitor inter-service communication
./kube-dump.sh -l app=api -e "tcpdump -i any host 10.96.0.1 -w /tmp/api-traffic.pcap"
```

### Network Troubleshooting
```bash
# Check network connectivity
./kube-dump.sh -l app=web -e "ping -c 5 8.8.8.8"

# Analyze network interfaces
./kube-dump.sh -l app=web -e "ip addr show"

# Monitor DNS resolution
./kube-dump.sh -l app=web -e "nslookup kubernetes.default.svc.cluster.local"
```

## Log Collection

### Application Logs
```bash
# Collect application logs
./kube-dump.sh -l app=myapp -o /tmp/logs -s "find /app/logs -name '*.log'"

# Collect specific log files with timestamps
./kube-dump.sh -l app=web -o /tmp/debug -s "cp /var/log/app.log /tmp/app-$(date +%Y%m%d-%H%M%S).log"

# Collect multiple log types
./kube-dump.sh -l app=api -o /tmp/logs -s "tar czf /tmp/logs-PLACEHOLDER_CHAR.tar.gz /app/logs/ /var/log/app/"
```

### System-Level Logs
```bash
# Node system logs
./kube-dump.sh -L node-type=worker -o /tmp/node-logs -S "journalctl -u kubelet --no-pager > /tmp/kubelet-PLACEHOLDER_CHAR.log"

# Container runtime logs
./kube-dump.sh -L node-type=worker -o /tmp/runtime -S "journalctl -u containerd --no-pager > /tmp/containerd-PLACEHOLDER_CHAR.log"
```

## System Analysis

### Resource Monitoring
```bash
# Check disk usage across pods
./kube-dump.sh -l tier=database -e "df -h"

# Memory analysis
./kube-dump.sh -l app=web -e "free -m && ps aux --sort=-%mem | head -10"

# CPU information
./kube-dump.sh -L node-type=worker -e "lscpu && top -b -n 1"
```

### Performance Analysis
```bash
# Network performance
./kube-dump.sh -l app=web -e "ss -tuln && netstat -i"

# Process monitoring
./kube-dump.sh -l app=api -e "top -b -n 3 -d 1 > /tmp/performance.txt" -o /tmp/perf

# I/O statistics
./kube-dump.sh -l tier=database -e "iostat -x 1 5 > /tmp/iostat.txt" -o /tmp/io
```

### Security Auditing
```bash
# Check running processes
./kube-dump.sh -l app=web -e "ps aux && ls -la /proc/*/exe 2>/dev/null"

# Network connections
./kube-dump.sh -l app=api -e "netstat -antlp && ss -tulpn"

# File permissions audit
./kube-dump.sh -l app=web -e "find /app -type f -perm /u+s,g+s 2>/dev/null" -o /tmp/audit
```

## Advanced Operations

### Comprehensive ArgoCD Debugging Example
```bash
# Full debugging session targeting all ArgoCD components across multiple nodes
# This example demonstrates:
# - Multiple pod label selectors (-l)
# - Multiple node label selectors (-L)
# - Import file scripts with arguments (-f, -e, -E)
# - File collection from both pods and nodes (-s, -S)
# - Kill switch protection (--kill-switch-rel)
# - Custom image with resource limits
# - Download verification with hash checking

bash kube-dump.sh \
  -l "app.kubernetes.io/name=argocd-server" \
  -l "app.kubernetes.io/name=argocd-repo-server" \
  -l "app.kubernetes.io/name=argocd-application-controller" \
  -l "app.kubernetes.io/name=argocd-applicationset-controller" \
  -l "app.kubernetes.io/name=argocd-dex-server" \
  -l "app.kubernetes.io/name=argocd-notifications-controller" \
  -l "app.kubernetes.io/name=argocd-redis" \
  -L "kubernetes.io/hostname=k8s-node-00" \
  -L "kubernetes.io/hostname=k8s-node-01" \
  -L "kubernetes.io/hostname=k8s-node-02" \
  -n "argocd" \
  --to-namespace="argocd" \
  --cri="containerd" \
  --cri-socket="/run/containerd/containerd.sock" \
  -f "./examples/capture-traffic.sh" \
  -e "%f %t 30 any" \
  --nsenter-params="n,m" \
  -f "./examples/diagnostics.sh" \
  -E "%f %t" \
  -s "ls /host/tmp/*.pcap /host/tmp/diag-*/*.txt 2>/dev/null" \
  -S "ls /host/tmp/*.pcap /host/tmp/diag-*/*.txt 2>/dev/null" \
  -o "./argocd-dump" \
  --download-verification="hash" \
  -I "%" \
  --include-nodes \
  --install-deps \
  --kill-switch-rel="10%" \
  --pod-volume="/host/tmp" \
  --node-volume="/host/tmp" \
  --workdir-pod="/host/tmp" \
  --workdir-node="/host/tmp" \
  --image="nicolaka/netshoot" \
  --cpu-limit="50m" \
  --memory-limit="56Mi" \
  --service-account="default" \
  --no-glyphs \
  --verbose
```

**What this does:**
1. Targets all 7 ArgoCD components via pod labels
2. Targets 3 specific nodes via node labels
3. Captures network traffic for 30 seconds on all interfaces using `capture-traffic.sh`
4. Runs diagnostics (ip, routes, sockets, dns, env) using `diagnostics.sh`
5. Collects resulting `.pcap` and diagnostic files from `/host/tmp/`
6. Verifies downloads with hash checking
7. Protects against disk fill with 10% relative kill switch
8. Uses minimal resources (50m CPU, 56Mi memory)

### Mixed Mode Debugging
```bash
# Debug both pods and their nodes
./kube-dump.sh -l app=web -L node-type=worker --include-nodes

# Different commands for pods vs nodes
./kube-dump.sh -l app=web -e "tcpdump -i any port 8080" -L node-type=worker -E "ss -tulpn | grep 8080"

# Collect files from both pods and nodes
./kube-dump.sh -l app=web -s "cp /app/config.yaml /tmp/config-PLACEHOLDER_CHAR.yaml" \
                -L node-type=worker -S "cp /etc/kubernetes/kubelet/config.yaml /tmp/kubelet-config-PLACEHOLDER_CHAR.yaml" \
                -o /tmp/configs
```

### Kill Switch Protection
```bash
# Protect with absolute disk threshold
./kube-dump.sh -l app=web --kill-switch-abs 1GB -e "dd if=/dev/zero of=/tmp/testfile bs=1M count=100"

# Protect with relative threshold
./kube-dump.sh -l app=web --kill-switch-rel 10 -o /tmp/safe-debug

# Monitor custom volume
./kube-dump.sh -l app=database --kill-switch-abs 500MB --pod-volume /data
```

### Container Runtime Specific
```bash
# Debug with containerd
./kube-dump.sh -l app=web --cri containerd --install-deps \
                -e "crictl ps && crictl images"

# Debug with CRI-O
./kube-dump.sh -l app=web --cri crio --cri-socket /var/run/crio/crio.sock \
                -e "crictl --runtime-endpoint unix:///var/run/crio/crio.sock ps"
```

## Configuration Management

### Config File Analysis
```bash
# Collect Kubernetes configs
./kube-dump.sh -L role=master -o /tmp/configs -S "cp -r /etc/kubernetes /tmp/k8s-config-PLACEHOLDER_CHAR"

# Application configuration
./kube-dump.sh -l app=web -o /tmp/app-configs -s "tar czf /tmp/app-config-PLACEHOLDER_CHAR.tar.gz /etc/app/"

# Environment variables
./kube-dump.sh -l app=api -e "env | sort > /tmp/env-vars.txt" -o /tmp/env
```

### Backup Operations
```bash
# Database dumps
./kube-dump.sh -l app=postgres -e "pg_dump -U postgres mydb > /tmp/backup-$(date +%Y%m%d).sql" -o /tmp/backups

# Configuration backups
./kube-dump.sh -l app=web -s "cp -r /app/config /tmp/config-backup-PLACEHOLDER_CHAR" -o /tmp/backups

# Certificate collection
./kube-dump.sh -L role=master -S "cp -r /etc/ssl/certs /tmp/certs-PLACEHOLDER_CHAR" -o /tmp/security
```

## Troubleshooting Scenarios

### Application Issues
```bash
# Debug application startup issues
./kube-dump.sh -l app=failing-app -e "ps aux && ls -la /app && cat /app/logs/startup.log"

# Check connectivity between services
./kube-dump.sh -l app=frontend -e "nc -zv backend-service 8080"

# Analyze application dependencies
./kube-dump.sh -l app=web -e "ldd /app/binary && strace -e /app/binary --check-deps"
```

### Network Issues
```bash
# Debug DNS issues
./kube-dump.sh -l app=web -e "nslookup api-service && cat /etc/resolv.conf"

# Check service mesh connectivity
./kube-dump.sh -l app=web -e "curl -v http://istio-proxy:15000/stats"

# Analyze iptables rules (node-level)
./kube-dump.sh -L node-type=worker -e "iptables -L -n && iptables -t nat -L -n"
```

### Storage Issues
```bash
# Check volume mounts
./kube-dump.sh -l app=database -e "mount | grep -E '(nfs|ceph)' && df -h"

# Analyze file system performance
./kube-dump.sh -l app=web -e "iostat -x 1 3 && lsof +D /app/data"

# Check storage permissions
./kube-dump.sh -l app=web -e "ls -la /app/data && id && whoami"
```

## No-Cleanup Mode

### Long-Running Debug Sessions
```bash
# Keep pods running for manual analysis
./kube-dump.sh -l app=web --no-cleanup

# Monitor continuously
./kube-dump.sh -l app=api --no-cleanup -e "while true; do date; ps aux | head -20; sleep 30; done"
```

### Interactive Debugging
```bash
# Create persistent debug environment
./kube-dump.sh -l app=web --no-cleanup -e "sleep infinity"

# Then connect manually:
# kubectl exec -it debug-pod-name -- /bin/bash
```

## Best Practices

### Resource Management
```bash
# Use kill switches for production
./kube-dump.sh -l app=production --kill-switch-rel 15 -o /tmp/prod-debug

# Limit scope with specific labels
./kube-dump.sh -l "app=web,version=v1.2,env!=test"

# Use appropriate namespaces
./kube-dump.sh -l app=web -n production -N debug-namespace
```

### Security Considerations
```bash
# Avoid exposing sensitive data
./kube-dump.sh -l app=web -s "find /app/logs -name '*.log' -exec grep -l 'ERROR' {} \;"

# Use read-only operations when possible
./kube-dump.sh -l app=web -e "find /app -type f -readable"

# Clean up after debugging
# (automatic with default behavior, manual with --no-cleanup)
```

---

For more advanced scenarios, see the [Architecture](kube-dump-architecture.md) documentation.