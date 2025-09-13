# Kube-Dump Architecture Diagram

This comprehensive Mermaid diagram shows the complete architecture and workflow of the kube-dump.sh script, including all new features like kill switches, logging, and no-glyphs mode.

## Complete Architecture & Workflow

```mermaid
graph TB
    %% User Input & Configuration
    Start([User Starts kube-dump.sh]) --> Init[Initialize Variables]
    Init --> ParseArgs[Parse Command Arguments]
    
    %% Configuration Decision Points
    ParseArgs --> LogCheck{"Output Directory Specified?"}
    LogCheck -->|Yes| CreateLog[Create Log File]
    LogCheck -->|No| ExecModeCheck
    CreateLog --> ExecModeCheck
    
    %% Execution Mode Selection
    ExecModeCheck{Execution Mode?}
    ExecModeCheck -->|Pod Mode| PodFlow[Pod Execution Flow]
    ExecModeCheck -->|Node Mode| NodeFlow[Node Execution Flow]
    ExecModeCheck -->|Mixed Mode| MixedFlow[Mixed Execution Flow]
    
    %% Pod Flow
    PodFlow --> FindPods[Find Pods by Label]
    FindPods --> PrepPods[Prepare Target Pods]
    PrepPods --> CreatePodDebug[Create Pod Debug Pods]

    %% Node Flow
    NodeFlow --> FindNodes[Find Nodes by Label]
    FindNodes --> CreateNodeDebug[Create Node Debug Pods]
    
    %% Mixed Flow
    MixedFlow --> MixedPods[Process Pod Targets]
    MixedPods --> MixedNodes[Process Node Targets]
    MixedNodes --> MixedCreate[Create Mixed Debug Pods]
    
    %% Consolidation
    CreatePodDebug --> WaitReady
    CreateNodeDebug --> WaitReady
    MixedCreate --> WaitReady
    
    %% Kill Switch Decision
    WaitReady[Wait for Debug Pods Ready] --> KillSwitchCheck{Kill Switch Configured?}

    %% Kill Switch Flow
    KillSwitchCheck -->|Yes| CreateKillMonitors[Create Kill Switch Monitors]
    KillSwitchCheck -->|No| MonitorPhase
    
    CreateKillMonitors --> KillSwitchType{Kill Switch Type?}
    KillSwitchType -->|Absolute| AbsMonitor[Monitor Available Space]
    KillSwitchType -->|Relative| RelMonitor[Monitor Free Space %]

    AbsMonitor --> StartBgMonitor[Start Background Monitoring]
    RelMonitor --> StartBgMonitor
    StartBgMonitor --> MonitorPhase
    
    %% Main Monitoring Phase
    MonitorPhase[Debug Pods Running] --> CleanupCheck{No-Cleanup Mode?}

    %% Kill Switch Background Process
    StartBgMonitor -.-> KillMonitorLoop{Monitor Loop}
    KillMonitorLoop -.-> KillThresholdCheck{Threshold Exceeded?}
    KillThresholdCheck -.->|Yes| KillDebugPods[Kill Debug Pods]
    KillThresholdCheck -.->|No| KillMonitorLoop
    KillDebugPods -.-> KillComplete[Kill Switch Complete]
    
    %% Cleanup Decision
    CleanupCheck -->|No Cleanup Mode| NoCleanupFlow[Keep Debug Pods Running]
    CleanupCheck -->|Normal| UserWait[Wait for User Input]

    UserWait --> CleanupDebug[Cleanup Debug Pods]
    CleanupDebug --> CleanupKillSwitches[Cleanup Kill Switch Monitors]
    
    %% File Download Decision
    CleanupKillSwitches --> FileDownloadCheck{File Download Requested?}
    NoCleanupFlow --> FileDownloadCheck
    
    FileDownloadCheck -->|Yes| CreateDiscovery[Create File Discovery Pods]
    FileDownloadCheck -->|No| Complete
    
    %% File Discovery & Download Flow
    CreateDiscovery --> DiscoveryType{Discovery Type?}
    DiscoveryType -->|Pod Files| PodDiscovery[Pod File Discovery]
    DiscoveryType -->|Node Files| NodeDiscovery[Node File Discovery]
    DiscoveryType -->|Both| BothDiscovery[Both Pod & Node Discovery]

    PodDiscovery --> ExecuteSelect[Execute Select Commands]
    NodeDiscovery --> ExecuteSelect
    BothDiscovery --> ExecuteSelect
    
    ExecuteSelect --> DownloadFiles[Download Files]
    DownloadFiles --> CleanupDiscovery[Cleanup Successful Discovery Pods]
    CleanupDiscovery --> Complete

    %% Completion
    Complete[Session Complete]
    
    %% Styling for different component types
    classDef startEnd fill:#1e3a8a,stroke:#3b82f6,stroke-width:3px,color:#fff
    classDef decision fill:#f59e0b,stroke:#d97706,stroke-width:2px,color:#000
    classDef process fill:#059669,stroke:#10b981,stroke-width:2px,color:#fff
    classDef killswitch fill:#dc2626,stroke:#ef4444,stroke-width:2px,color:#fff
    classDef monitor fill:#7c3aed,stroke:#a855f7,stroke-width:2px,color:#fff
    classDef cleanup fill:#ea580c,stroke:#f97316,stroke-width:2px,color:#fff
    
    class Start,Complete startEnd
    class LogCheck,ExecModeCheck,KillSwitchCheck,KillSwitchType,CleanupCheck,FileDownloadCheck,DiscoveryType decision
    class Init,ParseArgs,FindPods,FindNodes,CreatePodDebug,CreateNodeDebug,WaitReady process
    class CreateKillMonitors,AbsMonitor,RelMonitor,StartBgMonitor,KillDebugPods killswitch
    class MonitorPhase,KillMonitorLoop,KillThresholdCheck monitor
    class CleanupDebug,CleanupKillSwitches,CleanupDiscovery cleanup
```

## Key Components & Data Flows

```mermaid
graph LR
    %% Core Components
    subgraph "Core Components"
        CLI[kubectl/oc CLI]
        Script[kube-dump.sh]
        K8sCluster[Kubernetes Cluster]
    end
    
    %% Pod Types
    subgraph "Pod Types Created"
        DebugPod[Debug Pods<br/>- Execute commands<br/>- Network capture<br/>- Custom commands]
        KillMonitor[Kill Switch Monitors<br/>- Storage monitoring<br/>- Threshold checking<br/>- Auto-termination]
        DiscoveryPod[Discovery Pods<br/>- File discovery<br/>- File download<br/>- Cleanup operations]
    end
    
    %% Storage & Logging
    subgraph "Storage & Logging"
        LogFile[Session Log File<br/>kube-dump-YYYY-MM-DD_epoch.log]
        OutputDir[Output Directory<br/>Downloaded files]
        HostFS[Host Filesystem<br/>Monitored volumes]
    end
    
    %% Data Flows
    Script -->|Creates & Manages| DebugPod
    Script -->|Creates & Monitors| KillMonitor
    Script -->|Creates for Downloads| DiscoveryPod
    
    DebugPod -->|Accesses| HostFS
    KillMonitor -->|Monitors| HostFS
    DiscoveryPod -->|Downloads from| HostFS
    
    Script -->|Writes to| LogFile
    DiscoveryPod -->|Downloads to| OutputDir
    
    DebugPod -.->|Terminated by| KillMonitor
    
    CLI -->|Manages| K8sCluster
    Script -->|Uses| CLI
    K8sCluster -->|Hosts| DebugPod
    K8sCluster -->|Hosts| KillMonitor
    K8sCluster -->|Hosts| DiscoveryPod
```

## Kill Switch Architecture Detail

```mermaid
sequenceDiagram
    participant User
    participant Script as kube-dump.sh
    participant Debug as Debug Pod
    participant Monitor as Kill Switch Monitor
    participant HostFS as Host Filesystem
    
    User->>Script: Start with --kill-switch-abs 1GB
    Script->>Debug: Create debug pod
    Script->>Monitor: Create kill switch monitor pod
    
    Note over Monitor: Monitor runs in background<br/>checking every 10 seconds
    
    loop Storage Monitoring
        Monitor->>HostFS: Check df -B1 /monitored/path
        HostFS-->>Monitor: Available: 2GB, Used: 8GB
        Note over Monitor: Available (2GB) > Threshold (1GB)<br/>Continue monitoring
    end
    
    Note over HostFS: Storage fills up
    
    Monitor->>HostFS: Check df -B1 /monitored/path
    HostFS-->>Monitor: Available: 800MB, Used: 9.2GB
    Note over Monitor: Available (800MB) < Threshold (1GB)<br/>TRIGGER KILL SWITCH
    
    Monitor->>Script: Exit with success (threshold exceeded)
    Script->>Debug: kubectl delete pod (terminate)
    Script->>Monitor: kubectl delete pod (cleanup)
    
    Note over User: Debug pod terminated<br/>to prevent disk pressure
```

## File Download Workflow Detail

```mermaid
graph TB
    StartDownload[File Download Phase] --> CreateDiscoveryPods[Create Discovery Pods]
    
    subgraph "Discovery Pod Creation"
        CreateDiscoveryPods --> PodDiscoveryCreate[Pod Discovery Pods<br/>for -s commands]
        CreateDiscoveryPods --> NodeDiscoveryCreate[Node Discovery Pods<br/>for -S commands]
    end
    
    PodDiscoveryCreate --> WaitDiscoveryReady[Wait for Discovery Pods Ready]
    NodeDiscoveryCreate --> WaitDiscoveryReady
    
    WaitDiscoveryReady --> ExecuteCommands[Execute Select Commands<br/>with Placeholder Substitution]
    
    subgraph "File Discovery Process"
        ExecuteCommands --> ParseFileList[Parse File Lists<br/>from Command Output]
        ParseFileList --> DownloadLoop{For Each File}
        DownloadLoop --> DownloadFile[kubectl cp namespace/pod:file local-output]
        DownloadFile --> RemoveFromHost[Remove Downloaded File<br/>from Host Filesystem]
        RemoveFromHost --> NextFile{More Files?}
        NextFile -->|Yes| DownloadLoop
        NextFile -->|No| CleanupSuccess[Cleanup Successful<br/>Discovery Pods]
    end
    
    CleanupSuccess --> KeepFailedPods[Keep Failed Discovery Pods<br/>for Inspection]
    KeepFailedPods --> DownloadComplete[File Download Complete]
    
    %% Error Handling
    DownloadFile -->|Failed| TrackFailure[Track Failed Downloads]
    TrackFailure --> NextFile
```

## Feature Matrix

| Feature | Flag | Description | Integration Points |
|---------|------|-------------|-------------------|
| **Kill Switch (Absolute)** | `--kill-switch-abs` | Monitor absolute disk usage (e.g., 1GB, 500MB) | Creates monitor pods, background monitoring, auto-termination |
| **Kill Switch (Relative)** | `--kill-switch-rel` | Monitor relative disk usage (e.g., 10%) | Creates monitor pods, percentage calculations, auto-termination |
| **Volume Monitoring** | `--pod-volume`, `--node-volume` | Specify paths to monitor for kill switches | Volume mount points, df command targets |
| **No Glyphs Mode** | `--no-glyphs` | Replace emojis with text labels | Message formatting, logging output |
| **Session Logging** | `-o` (triggers logging) | Log all session activity | File creation, message logging, session archival |
| **Mixed Mode** | `-l` + `-L` | Execute on both pods and nodes | Dual pod creation, parallel monitoring |
| **File Download** | `-s`, `-S`, `-o` | Download files created during debug | Discovery pods, file transfer, cleanup |
| **No Cleanup** | `--no-cleanup` | Keep debug pods running | Skip cleanup phase, show monitoring commands |

This diagram provides a complete view of the kube-dump.sh architecture, showing how the new kill switch and logging features integrate seamlessly with the existing pod/node debugging capabilities.