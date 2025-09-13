# Kube-Dump Script Workflow Diagram

```mermaid
flowchart TD
    %% Styling definitions
    classDef initProcess fill:#E1F5FE,stroke:#0288D1,stroke-width:3px,color:#000
    classDef validationProcess fill:#F3E5F5,stroke:#7B1FA2,stroke-width:3px,color:#000
    classDef discoveryProcess fill:#E8F5E8,stroke:#388E3C,stroke-width:3px,color:#000
    classDef debugPodProcess fill:#FFF3E0,stroke:#F57C00,stroke-width:3px,color:#000
    classDef executionProcess fill:#FFEBEE,stroke:#D32F2F,stroke-width:3px,color:#000
    classDef fileProcess fill:#F1F8E9,stroke:#689F38,stroke-width:3px,color:#000
    classDef cleanupProcess fill:#FCE4EC,stroke:#C2185B,stroke-width:3px,color:#000
    classDef decision fill:#FFF8E1,stroke:#FFA000,stroke-width:2px,color:#000
    classDef dataStore fill:#E0F2F1,stroke:#00695C,stroke-width:2px,color:#000
    classDef terminal fill:#ECEFF1,stroke:#37474F,stroke-width:2px,color:#000
    classDef error fill:#FFCDD2,stroke:#D32F2F,stroke-width:2px,color:#000

    %% Main Flow Start
    START([🚀 Start kube-dump.sh]):::terminal
    
    %% PHASE 1: Initialization
    INIT["🔧 Initialize Variables"]:::initProcess

    DETECT["🔍 Detect Kube CLI"]:::initProcess

    PARSE["📋 Parse Arguments"]:::initProcess
    
    %% Argument validation decision
    NO_ARGS{No arguments provided?}:::decision
    USAGE[📖 Show Usage & Exit]:::terminal
    
    %% PHASE 2: Validation
    VALIDATE["✅ Validate Arguments"]:::validationProcess
    
    MODE_CHECK{Execution Mode?}:::decision
    
    CLUSTER_VAL["🔐 Validate Cluster Access"]:::validationProcess
    
    %% PHASE 3: Target Discovery
    POD_SELECT["📦 Select Target Pods"]:::discoveryProcess
    
    NODE_SELECT["🖥️ Select Target Nodes"]:::discoveryProcess
    
    PREPARE_PODS["🎯 Prepare Target Pods"]:::discoveryProcess
    
    %% PHASE 4: Debug Pod Creation
    POD_DEBUG["🚀 Create Pod Debug Pods"]:::debugPodProcess
    
    NODE_DEBUG["🚀 Create Node Debug Pods"]:::debugPodProcess
    
    WAIT_READY["⏳ Wait for Debug Pods Ready"]:::debugPodProcess
    
    %% PHASE 5: Execution Monitoring
    MONITOR["📊 Monitor Execution"]:::executionProcess
    
    %% PHASE 6: Cleanup Decision
    NO_CLEANUP_FLAG{"--no-cleanup flag set?"}:::decision
    
    USER_INPUT["⏸️ Wait for User Input"]:::executionProcess
    
    %% PHASE 7: Cleanup
    CLEANUP_DEBUG["🧾 Cleanup Debug Pods"]:::cleanupProcess
    
    %% PHASE 8: File Operations
    FILE_DOWNLOAD_CHECK{"File download requested?"}:::decision
    
    CREATE_DISCOVERY["🔍 Create Discovery Pods"]:::fileProcess
    
    WAIT_DISCOVERY["⏳ Wait Discovery Pods Ready"]:::fileProcess
    
    DOWNLOAD_FILES["📥 Download Files"]:::fileProcess
    
    CLEANUP_DISCOVERY["🧾 Cleanup Discovery Pods"]:::fileProcess
    
    %% Terminal states
    COMPLETE["🎉 Complete!"]:::terminal
    NO_CLEANUP_COMPLETE["🔧 Debug pods still running"]:::terminal
    ERROR[❌ Error Exit]:::error
    
    %% Data stores
    POD_NAMES[("POD_NAMES[]")]:::dataStore
    NODE_NAMES[("NODE_NAMES[]")]:::dataStore
    TARGET_PODS[("TARGET_PODS[]")]:::dataStore
    TARGET_NODES[("TARGET_NODES[]")]:::dataStore
    DEBUG_POD_NAMES[("DEBUG_POD_NAMES[]")]:::dataStore
    DISCOVERY_POD_INFO[("DISCOVERY_POD_INFO[]")]:::dataStore
    
    %% CRI Configuration Subprocess
    CRI_CONFIG["⚙️ CRI Configuration"]:::initProcess
    
    %% Debug Script Generation
    POD_SCRIPT["📜 Generate Pod Debug Script"]:::debugPodProcess
    
    NODE_SCRIPT["📜 Generate Node Debug Script"]:::debugPodProcess

    %% Main flow connections
    START --> INIT
    INIT --> DETECT
    DETECT --> PARSE
    PARSE --> NO_ARGS
    NO_ARGS -->|Yes| USAGE
    NO_ARGS -->|No| VALIDATE
    VALIDATE --> MODE_CHECK
    MODE_CHECK -->|Pod Mode| POD_SELECT
    MODE_CHECK -->|Node Mode| NODE_SELECT
    MODE_CHECK -->|Mixed Mode| POD_SELECT
    MODE_CHECK -->|Mixed Mode| NODE_SELECT
    
    %% Validation phase
    VALIDATE --> CLUSTER_VAL
    CLUSTER_VAL -->|Failed| ERROR
    
    %% Pod discovery flow
    POD_SELECT --> POD_NAMES
    POD_NAMES --> PREPARE_PODS
    PREPARE_PODS --> TARGET_PODS
    TARGET_PODS --> POD_DEBUG
    
    %% Node discovery flow  
    NODE_SELECT --> NODE_NAMES
    NODE_NAMES --> TARGET_NODES
    TARGET_NODES --> NODE_DEBUG
    
    %% Debug pod creation
    POD_DEBUG --> POD_SCRIPT
    POD_SCRIPT --> CRI_CONFIG
    NODE_DEBUG --> NODE_SCRIPT
    
    CRI_CONFIG --> DEBUG_POD_NAMES
    POD_DEBUG --> DEBUG_POD_NAMES
    NODE_DEBUG --> DEBUG_POD_NAMES
    DEBUG_POD_NAMES --> WAIT_READY
    
    WAIT_READY -->|Success| MONITOR
    WAIT_READY -->|Failed| ERROR
    
    %% Execution monitoring
    MONITOR --> NO_CLEANUP_FLAG
    NO_CLEANUP_FLAG -->|Yes| FILE_DOWNLOAD_CHECK
    NO_CLEANUP_FLAG -->|No| USER_INPUT
    USER_INPUT --> CLEANUP_DEBUG
    CLEANUP_DEBUG --> FILE_DOWNLOAD_CHECK
    
    %% File operations
    FILE_DOWNLOAD_CHECK -->|No| COMPLETE
    FILE_DOWNLOAD_CHECK -->|Yes| CREATE_DISCOVERY
    CREATE_DISCOVERY --> DISCOVERY_POD_INFO
    DISCOVERY_POD_INFO --> WAIT_DISCOVERY
    WAIT_DISCOVERY -->|Success| DOWNLOAD_FILES
    WAIT_DISCOVERY -->|Failed| ERROR
    DOWNLOAD_FILES --> CLEANUP_DISCOVERY
    CLEANUP_DISCOVERY --> COMPLETE
    
    %% No cleanup path
    FILE_DOWNLOAD_CHECK -->|Yes + No Cleanup| CREATE_DISCOVERY
    CLEANUP_DISCOVERY -->|No Cleanup Mode| NO_CLEANUP_COMPLETE
    FILE_DOWNLOAD_CHECK -->|No + No Cleanup| NO_CLEANUP_COMPLETE

    %% Error handling
    POD_SELECT -->|Failed| ERROR
    NODE_SELECT -->|Failed| ERROR
    PREPARE_PODS -->|Failed| ERROR
    POD_DEBUG -->|Failed| ERROR
    NODE_DEBUG -->|Failed| ERROR
    CREATE_DISCOVERY -->|Failed| ERROR

    %% Legend Section
    subgraph LEGEND [" 📋 LEGEND "]
        direction TB
        L1[🔧 Initialization Process]:::initProcess
        L2[✅ Validation Process]:::validationProcess  
        L3[🔍 Discovery Process]:::discoveryProcess
        L4[🚀 Debug Pod Process]:::debugPodProcess
        L5[📊 Execution Process]:::executionProcess
        L6[📥 File Operations]:::fileProcess
        L7[🧹 Cleanup Process]:::cleanupProcess
        L8{Decision Point}:::decision
        L9[(Data Store)]:::dataStore
        L10([Terminal State]):::terminal
        L11[❌ Error State]:::error
    end
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