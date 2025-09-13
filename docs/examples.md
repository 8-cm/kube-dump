# Examples

Comprehensive examples for common kube-dump usage scenarios and advanced use cases.

## 🚀 Quick Start Examples

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

## 🖥️ Node-Level Operations

### Monitor Worker Nodes
```bash
# Monitor worker nodes
./kube-dump.sh -L node-role.kubernetes.io/worker

# Custom node command
./kube-dump.sh -L worker=true -E 'ss -tuln'

# Network diagnostics on control plane
./kube-dump.sh -L node-role.kubernetes.io/control-plane=true -E 'netstat -i'
```

## 📦 File Operations

### Generate and Download Files
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

## 🔀 Cross-Namespace Operations

### Debug Across Namespaces
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

## 🔧 Advanced Scenarios

### Include Nodes Hosting Pods
```bash
# Include nodes hosting selected pods
./kube-dump.sh -l app=database --include-nodes \
  -e 'tcpdump -i any port 5432' \
  -E 'tcpdump -i any port 5432'
```

### Custom Container Runtime
```bash
# Custom container runtime
./kube-dump.sh -l app=web --cri crio -e 'ss -tuln'

# Custom CRI socket path
./kube-dump.sh -l app=web --cri-socket /var/run/podman/podman.sock
```

### Keep Debug Pods for Inspection
```bash
# Keep debug pods for manual inspection
./kube-dump.sh -l app=api --no-cleanup \
  -e 'tcpdump -i any -w capture.pcap'
```

## 🛡️ Kill Switch Protection

### Absolute Threshold
```bash
# Use kill switch to prevent disk pressure (absolute threshold)
./kube-dump.sh -l app=database \
  --kill-switch-abs 1GB --pod-volume /tmp \
  -e 'tcpdump -i any -w /tmp/%.pcap'
```

### Relative Threshold
```bash
# Use kill switch with relative threshold on nodes
./kube-dump.sh -L worker=true \
  --kill-switch-rel 5% --node-volume /var \
  -E 'tcpdump -i eth0 -w /var/%.pcap'
```

## 📱 Text-Only Output

### Terminal Compatibility
```bash
# Text-only output without emojis
./kube-dump.sh -l app=web --no-glyphs \
  -e 'tcpdump -i any -c 100'
```

## 🎯 Real-World Scenarios

### Database Performance Investigation
```bash
# Comprehensive database debugging
./kube-dump.sh \
  -l app=postgresql \
  -n database \
  --include-nodes \
  -e 'tcpdump -i any port 5432 -w pod-%.pcap -c 2000' \
  -E 'tcpdump -i any port 5432 -w node-%.pcap -c 2000' \
  -s 'ls *.pcap' \
  -S 'ls *.pcap' \
  --kill-switch-abs 500MB \
  --pod-volume /tmp \
  --node-volume /var \
  -o ./database-investigation-$(date +%Y%m%d)
```

### Microservices Communication Analysis
```bash
# Trace communication between services
./kube-dump.sh \
  -l 'tier in (frontend,backend,api)' \
  -n production \
  -e 'tcpdump -i any -n -s 0 -c 1000 -w service-%.pcap' \
  -s 'ls *.pcap' \
  --kill-switch-rel 10% \
  --pod-volume /tmp \
  -o ./service-communication
```

### Security Incident Response
```bash
# Safe incident investigation
./kube-dump.sh \
  -l app=suspicious-app \
  -n security-incident \
  --to-namespace forensics \
  -e 'tcpdump -i any -w incident-%.pcap -c 5000' \
  -s 'ls *.pcap' \
  --kill-switch-abs 100MB \
  --pod-volume /tmp \
  --no-glyphs \
  -o ./incident-$(date +%Y%m%d-%H%M%S)
```

### Load Testing Analysis
```bash
# Monitor during load tests
./kube-dump.sh \
  -l app=load-target \
  -L 'node-role.kubernetes.io/worker' \
  -e 'tcpdump -i any -c 10000 -w load-pod-%.pcap' \
  -E 'tcpdump -i any -c 10000 -w load-node-%.pcap' \
  -s 'ls *.pcap' \
  -S 'ls *.pcap' \
  --kill-switch-rel 15% \
  --pod-volume /tmp \
  --node-volume /var \
  -o ./load-test-$(date +%Y%m%d)
```

## 🔍 Troubleshooting Scenarios

### Network Connectivity Issues
```bash
# Diagnose pod connectivity
./kube-dump.sh -l app=failing-service \
  -e 'ping -c 10 external-service.com && traceroute external-service.com' \
  -o ./connectivity-debug
```

### DNS Resolution Problems
```bash
# Check DNS resolution
./kube-dump.sh -l app=dns-issues \
  -e 'nslookup kubernetes.default.svc.cluster.local && cat /etc/resolv.conf' \
  -o ./dns-debug
```

### Container Runtime Issues
```bash
# Investigate container runtime
./kube-dump.sh -L worker=true \
  --cri containerd \
  -E 'crictl ps && crictl images' \
  -o ./runtime-debug
```

## 🚀 Performance Optimization

### High-Performance Capture
```bash
# Optimized for high-traffic environments
./kube-dump.sh -l app=high-traffic \
  -e 'tcpdump -i any -c 50000 -s 128 -w fast-%.pcap' \
  --kill-switch-abs 2GB \
  --pod-volume /tmp \
  -o ./performance-capture
```

### Minimal Resource Usage
```bash
# Lightweight monitoring
./kube-dump.sh -l app=resource-constrained \
  -e 'ss -tuln > connections.txt && ps aux > processes.txt' \
  -s 'ls *.txt' \
  -o ./lightweight-monitoring
```

## 🔐 Security-Focused Examples

### Compliance Audit
```bash
# Security compliance check
./kube-dump.sh -l security-audit=true \
  --to-namespace audit \
  -e 'netstat -tuln > network-audit.txt && ps aux > process-audit.txt' \
  -s 'ls *-audit.txt' \
  --no-cleanup \
  -o ./compliance-audit-$(date +%Y%m%d)
```

### Network Policy Testing
```bash
# Test network policies
./kube-dump.sh -l test-network-policy=true \
  -e 'timeout 30 tcpdump -i any -c 100 -w policy-test-%.pcap' \
  -s 'ls *.pcap' \
  -o ./network-policy-test
```

## 📊 Monitoring and Metrics

### Continuous Monitoring Setup
```bash
# Long-running monitoring with rotation
./kube-dump.sh -l monitor=continuous \
  -e 'tcpdump -i any -G 300 -w monitor-%.pcap' \
  --kill-switch-rel 20% \
  --pod-volume /tmp \
  -s 'ls monitor-*.pcap' \
  -o ./continuous-monitoring
```

### Metrics Collection
```bash
# Collect system metrics
./kube-dump.sh -L monitoring=true \
  -E 'top -b -n 1 > cpu-%.txt && free -m > memory-%.txt && df -h > disk-%.txt' \
  -S 'ls *.txt' \
  -o ./system-metrics
```

---

**💡 Pro Tips**:
- Use `--kill-switch-*` options in production to prevent disk pressure
- Always specify `-o` for file collection and logging
- Use `--no-glyphs` in CI/CD environments
- Test commands with `--no-cleanup` first for debugging
- Combine multiple targeting methods for comprehensive analysis