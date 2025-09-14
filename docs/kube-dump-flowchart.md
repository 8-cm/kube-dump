# Kube-Dump Script Workflow Diagram

This comprehensive sequence diagram illustrates the complete kube-dump.sh script workflow from startup through completion. It demonstrates the interaction between the user, script components, Kubernetes API, and various processes throughout all execution phases including initialization, validation, target discovery, debug pod creation, monitoring, cleanup, and file operations.

```mermaid
sequenceDiagram
    participant User as User
    participant KD as kube-dump.sh
    participant CLI as Kubernetes CLI
    participant K8s as Kubernetes API
    participant CRI as CRI Runtime
    participant DP as Debug Pods
    participant Discovery as Discovery Pods
    participant DS as Data Stores

    Note over User,DS: Kube-Dump Complete Script Workflow

    User->>KD: 🚀 Start kube-dump.sh with arguments

    Note over KD,DS: PHASE 1: Initialization

    KD->>KD: 🔧 Initialize variables (labels, commands, arrays, CRI settings)
    KD->>CLI: 🔍 Detect Kubernetes CLI (oc or kubectl)
    CLI->>KD: Return detected CLI tool
    KD->>KD: 📋 Parse and validate arguments

    alt No arguments provided
        KD->>User: 📖 Show usage and exit
    else Arguments provided
        Note over KD,DS: PHASE 2: Validation
        KD->>KD: ✅ Validate arguments and set execution mode
        KD->>K8s: 🔐 Validate cluster access and permissions
        K8s->>KD: Confirm cluster connectivity

        Note over KD,DS: PHASE 3: Target Discovery

        alt Pod Mode
            KD->>CLI: 📦 Select target pods by label selector
            CLI->>K8s: Query pods matching selector
            K8s->>DS: Store POD_NAMES[] results
            KD->>DS: 🎯 Prepare target pods (verify Running status, build TARGET_PODS[])

        else Node Mode
            KD->>CLI: 🖥️ Select target nodes by label selector
            CLI->>K8s: Query nodes matching selector
            K8s->>DS: Store NODE_NAMES[] results
            KD->>DS: Build TARGET_NODES[] array

        else Mixed Mode
            KD->>CLI: Handle both pod and node selection
            CLI->>K8s: Query both pods and nodes
            K8s->>DS: Store both POD_NAMES[] and NODE_NAMES[]
        end

        Note over KD,DS: PHASE 4: Debug Pod Creation

        alt Pod Debug Creation
            KD->>K8s: 🚀 Create pod debug pods (privileged netshoot containers)
            KD->>CRI: ⚙️ Configure CRI runtime (containerd/crio/docker)
            KD->>KD: 📜 Generate pod debug scripts with nsenter
            K8s->>DP: Deploy debug pods with host filesystem mounts

        else Node Debug Creation
            KD->>K8s: 🚀 Create node debug pods (host networking + PID)
            KD->>KD: 📜 Generate node debug scripts
            K8s->>DP: Deploy node debug pods with host access
        end

        KD->>DS: Store DEBUG_POD_NAMES[] array
        KD->>DP: ⏳ Wait for debug pods ready (timeout 60s)
        DP->>KD: All pods running and ready

        Note over KD,DS: PHASE 5: Execution Monitoring

        KD->>DP: Start debug command execution
        KD->>User: 📊 Show monitoring commands and manual cleanup instructions

        Note over KD,DS: PHASE 6: Cleanup Decision

        alt --no-cleanup flag set
            alt File download requested
                Note over KD,DS: PHASE 8: File Operations (No Cleanup Mode)
                KD->>K8s: 🔍 Create discovery pods (Ubuntu + tail -f)
                K8s->>Discovery: Deploy discovery pods with host filesystem access
                KD->>DS: Store DISCOVERY_POD_INFO[] metadata
                KD->>Discovery: ⏳ Wait for discovery pods ready (timeout 120s)
                Discovery->>Discovery: 📥 Execute file selection and download with retry
                KD->>K8s: 🧹 Cleanup successful discovery pods only
                KD->>User: 🔧 Debug pods still running - use kubectl logs to monitor
            else No file download
                KD->>User: 🔧 Debug pods still running - use kubectl logs to monitor
            end

        else Standard cleanup mode
            KD->>User: ⏸️ Wait for user input (Press Enter to cleanup)
            User->>KD: User presses Enter

            Note over KD,DS: PHASE 7: Cleanup
            KD->>K8s: 🧹 Delete all debug pods (ignore not found errors)
            K8s->>DP: Terminate debug pods

            alt File download requested
                Note over KD,DS: PHASE 8: File Operations
                KD->>K8s: 🔍 Create discovery pods
                K8s->>Discovery: Deploy discovery pods
                Discovery->>Discovery: 📥 Download files with placeholder substitution
                KD->>K8s: 🧹 Delete successful discovery pods, keep failed for inspection
                KD->>User: 🎉 Complete - all operations finished
            else No file download
                KD->>User: 🎉 Complete - all operations finished
            end
        end
    end

    Note over User,DS: Script execution completed successfully
```

## Key Features Visualized:

### 🎯 **Execution Modes**
- **Pod Mode**: Target pods by label selector, execute in container network namespace
- **Node Mode**: Target nodes by label selector, execute directly on host
- **Mixed Mode**: Both pod and node targeting simultaneously

### 🔧 **CRI Runtime Support**
- **Containerd**: Default runtime with `/run/containerd/containerd.sock`
- **CRI-O**: Alternative runtime with `/run/crio/crio.sock` 
- **Docker**: Legacy support with `/var/run/cri-dockerd.sock`
- **Custom Socket**: User-specified CRI socket path

### 📦 **Debug Pod Architecture**
- **Privileged Access**: Required for network namespace entry and host filesystem access
- **Host Networking**: Enables access to host network interfaces and processes
- **Host PID Namespace**: Allows nsenter to access target container processes
- **Volume Mounts**: Host filesystem mounted at `/host` for complete access

### 🔍 **Target Discovery Process**
- **Label Selectors**: Flexible pod and node selection via Kubernetes labels
- **Namespace Handling**: Support for cross-namespace operations
- **Container Selection**: Automatic first container selection (shared network namespace)
- **Status Filtering**: Only Running pods are included in operations

### ⚙️ **Command Execution**
- **Default Command**: `tcpdump -i any -nn -s 0` for network capture
- **Custom Commands**: User-specified commands with full shell support
- **Placeholder Substitution**: Dynamic hostname replacement using configurable character
- **Network Namespace Entry**: `nsenter -n -t $PID` for pod network access

### 📥 **File Operations**
- **Discovery Pods**: Separate pods for file discovery and download
- **Select Commands**: Custom commands to identify files for download
- **Placeholder Support**: Hostname substitution in file paths
- **Cleanup Strategy**: Remove successful discovery pods, keep failed for inspection

### 🧹 **Cleanup Management**
- **Default Behavior**: User confirmation before cleanup
- **No-Cleanup Mode**: `--no-cleanup` flag keeps debug pods running
- **Selective Cleanup**: File discovery pods cleaned based on success/failure
- **Manual Override**: Commands provided for manual cleanup

This comprehensive flowchart captures the complete execution flow of the kube-dump.sh script, showing how it handles different execution modes, manages privileged debugging containers, and provides flexible file download capabilities while maintaining proper cleanup procedures.