# kube-dump Documentation

Complete documentation for the kube-dump Kubernetes debugging tool.

## Getting Started

- [Installation](installation.md) - Prerequisites, setup, and requirements
- [Quick Start Examples](examples.md) - Common usage patterns and real-world scenarios
- [Command Reference](command-reference.md) - Complete CLI options and parameters

## Technical Architecture

- [Architecture & Function Call Flow](architecture.md) - Complete technical architecture, function hierarchy, execution flow, and component interactions

## Configuration & Customization

- [Custom Container Images](custom-images.md) - Configure debug pod images for specific needs
- [Dependencies](dependencies.md) - Required tools, container runtimes, and system dependencies

## Quality & Compliance

- [Code Quality](code-quality.md) - ShellCheck code quality findings

---

## Quick Usage Examples

### Network Debugging
```bash
# Capture traffic from all nginx pods
./kube-dump.sh -l app=nginx

# Monitor specific port on multiple pods
./kube-dump.sh -l app=web -c "tcpdump -i any port 8080"
```

### Log Collection
```bash
# Collect application logs from multiple pods
./kube-dump.sh -l app=myapp -o /tmp/logs -s "find /app/logs -name '*.log'"

# Node-level system logs
./kube-dump.sh -L node-type=worker -o /tmp/node-logs -S "find /var/log -name '*.log'"
```

### System Analysis
```bash
# Check disk usage across database pods
./kube-dump.sh -l tier=database -c "df -h"

# Network connections on worker nodes
./kube-dump.sh -L node-type=worker -c "ss -tuln"
```

### File Operations
```bash
# Generate and download config dumps
./kube-dump.sh -l app=web -o /tmp/configs -s "cp /etc/app/config.yaml /tmp/config-backup.yaml"

# Collect performance data
./kube-dump.sh -l app=api -o /tmp/perf -s "top -b -n 1 > /tmp/performance.txt"
```

## Advanced Features

### Kill Switch Protection
Automatically terminate debug pods when disk usage exceeds thresholds:

```bash
# Absolute threshold (1GB free space minimum)
./kube-dump.sh -l app=web --kill-switch-abs 1GB

# Relative threshold (10% free space minimum)
./kube-dump.sh -l app=web --kill-switch-rel 10
```

### Mixed Mode Operations
Target both pods and nodes simultaneously:

```bash
# Debug pods and their hosting nodes
./kube-dump.sh -l app=nginx -L node-type=worker --include-nodes
```

### Runtime Flexibility
Works with different container runtimes:

```bash
# Specify runtime explicitly
./kube-dump.sh -l app=web --cri-runtime containerd --cri-socket /run/containerd/containerd.sock
```

## Troubleshooting

### Common Issues

**Permission Denied**
- Ensure cluster-admin privileges or appropriate RBAC permissions
- Check if privileged pod creation is allowed in the target namespace

**Pod Creation Failures**
- Verify node resources (CPU, memory, storage)
- Check node taints and tolerations
- Ensure container runtime is accessible

**File Download Issues**
- Confirm output directory exists and is writable
- Check file paths exist in target pods/nodes
- Verify network connectivity between pods and kubectl client

**Kill Switch Not Working**
- Ensure volume paths are correctly specified
- Check if `bc` calculator is available in debug pods
- Verify threshold values are reasonable for the environment

### Debug Mode
Enable verbose logging for troubleshooting:

```bash
# Enable debug output
export DEBUG=1
./kube-dump.sh -l app=web
```

## Contributing

- Report issues and feature requests in the GitHub repository
- Review [Architecture](architecture.md) before making changes
- Follow the existing code style and patterns
- Update documentation for new features

---

For quick reference, use `./kube-dump.sh -h` to see all available options.
