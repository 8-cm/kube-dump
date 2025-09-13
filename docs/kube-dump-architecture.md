# Kube-Dump Architecture Diagram

This comprehensive Mermaid diagram shows the complete architecture and workflow of the kube-dump.sh script, including all new features like kill switches, logging, and no-glyphs mode.

## Complete Architecture & Workflow

```mermaid
graph TB
    %% User Input & Configuration
    Start([User Starts kube-dump.sh]) --> Init[Initialize Variables]
    Init --> ParseArgs[Parse Command Arguments]
    
    %% Configuration Decision Points
    ParseArgs --> LogCheck{Output DirectorySpecified (-o)?}
    LogCheck -->|Yes| CreateLog[Create Log Filekube-dump-YYYY-MM-DD_epoch.log]
    LogCheck -->|No| ExecModeCheck
    CreateLog --> ExecModeCheck
    
    %% Execution Mode Selection
    ExecModeCheck{Execution Mode?}
    ExecModeCheck -->|Pod Mode(-l label)| PodFlow[Pod Execution Flow]
    ExecModeCheck -->|Node Mode(-L node-label)| NodeFlow[Node Execution Flow]
    ExecModeCheck -->|Mixed Mode(-l + -L)| MixedFlow[Mixed Execution Flow]
    
    %% Pod Flow
    PodFlow --> FindPods[Find Pods by Labelusing kubectl/oc]
    FindPods --> PrepPods[Prepare Target Podsvalidate running state]
    PrepPods --> CreatePodDebug[Create Debug Podsfor Pod Targets]
    
    %% Node Flow
    NodeFlow --> FindNodes[Find Nodes by Labelusing kubectl/oc]
    FindNodes --> CreateNodeDebug[Create Debug Podsfor Node Targets]
    
    %% Mixed Flow
    MixedFlow --> MixedPods[Process Pod Targets]
    MixedPods --> MixedNodes[Process Node Targets]
    MixedNodes --> MixedCreate[Create Debug Podsfor Both Types]
    
    %% Consolidation
    CreatePodDebug --> WaitReady
    CreateNodeDebug --> WaitReady
    MixedCreate --> WaitReady
    
    %% Kill Switch Decision
    WaitReady[Wait for Debug Pods Ready] --> KillSwitchCheck{Kill SwitchConfigured?}
    
    %% Kill Switch Flow
    KillSwitchCheck -->|Yes--kill-switch-abs/rel| CreateKillMonitors[Create Kill SwitchMonitor Pods]
    KillSwitchCheck -->|No| MonitorPhase
    
    CreateKillMonitors --> KillSwitchType{Kill Switch Type?}
    KillSwitchType -->|Absolute--kill-switch-abs| AbsMonitor[Monitor Available Spacevs Thresholde.g., 1GB, 500MB]
    KillSwitchType -->|Relative--kill-switch-rel| RelMonitor[Monitor Free Space %vs Thresholde.g., 10%]
    
    AbsMonitor --> StartBgMonitor[Start BackgroundKill Switch Monitoring]
    RelMonitor --> StartBgMonitor
    StartBgMonitor --> MonitorPhase
    
    %% Main Monitoring Phase
    MonitorPhase[📊 Debug Pods RunningMonitor Command Output] --> CleanupCheck{No-CleanupMode?}
    
    %% Kill Switch Background Process
    StartBgMonitor -.-> KillMonitorLoop{Monitor LoopCheck Every 5s}
    KillMonitorLoop -.-> KillThresholdCheck{ThresholdExceeded?}
    KillThresholdCheck -.->|Yes| KillDebugPods[🔴 Kill Debug PodsClean Monitor Pods]
    KillThresholdCheck -.->|No| KillMonitorLoop
    KillDebugPods -.-> KillComplete[Kill Switch Complete]
    
    %% Cleanup Decision
    CleanupCheck -->|--no-cleanup| NoCleanupFlow[Keep Debug Pods RunningShow Monitor Commands]
    CleanupCheck -->|Normal| UserWait[Wait for User InputPress Enter to cleanup]
    
    UserWait --> CleanupDebug[🧹 Cleanup Debug Pods]
    CleanupDebug --> CleanupKillSwitches[🧹 Cleanup Kill SwitchMonitor Pods]
    
    %% File Download Decision
    CleanupKillSwitches --> FileDownloadCheck{File DownloadRequested?}
    NoCleanupFlow --> FileDownloadCheck
    
    FileDownloadCheck -->|Yes-s/-S + -o| CreateDiscovery[Create File Discovery Pods]
    FileDownloadCheck -->|No| Complete
    
    %% File Discovery & Download Flow
    CreateDiscovery --> DiscoveryType{Discovery Type?}
    DiscoveryType -->|Pod Files-s command| PodDiscovery[Pod File DiscoveryExecute select commandwith placeholder substitution]
    DiscoveryType -->|Node Files-S command| NodeDiscovery[Node File DiscoveryExecute select commandwith placeholder substitution]
    DiscoveryType -->|Both| BothDiscovery[Both Pod & NodeDiscovery]
    
    PodDiscovery --> ExecuteSelect[Execute Select CommandsGet File Lists]
    NodeDiscovery --> ExecuteSelect
    BothDiscovery --> ExecuteSelect
    
    ExecuteSelect --> DownloadFiles[📥 Download Filesto Output Directory]
    DownloadFiles --> CleanupDiscovery[🧹 Cleanup SuccessfulDiscovery Pods]
    CleanupDiscovery --> Complete
    
    %% Completion
    Complete[🎉 Session CompleteClose Log File if Created]
    
    %% Styling for different component types
    classDef startEnd fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef decision fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef process fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef killswitch fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef monitor fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef cleanup fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    
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
        DebugPod[Debug Pods- Execute commands- Network capture- Custom commands]
        KillMonitor[Kill Switch Monitors- Storage monitoring- Threshold checking- Auto-termination]
        DiscoveryPod[Discovery Pods- File discovery- File download- Cleanup operations]
    end
    
    %% Storage & Logging
    subgraph "Storage & Logging"
        LogFile[Session Log Filekube-dump-YYYY-MM-DD_epoch.log]
        OutputDir[Output DirectoryDownloaded files]
        HostFS[Host FilesystemMonitored volumes]
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
    
    Note over Monitor: Monitor runs in backgroundchecking every 10 seconds
    
    loop Storage Monitoring
        Monitor->>HostFS: Check df -B1 /monitored/path
        HostFS-->>Monitor: Available: 2GB, Used: 8GB
        Note over Monitor: Available (2GB) > Threshold (1GB)Continue monitoring
    end
    
    Note over HostFS: Storage fills up
    
    Monitor->>HostFS: Check df -B1 /monitored/path
    HostFS-->>Monitor: Available: 800MB, Used: 9.2GB
    Note over Monitor: Available (800MB) < Threshold (1GB)TRIGGER KILL SWITCH
    
    Monitor->>Script: Exit with success (threshold exceeded)
    Script->>Debug: kubectl delete pod (terminate)
    Script->>Monitor: kubectl delete pod (cleanup)
    
    Note over User: Debug pod terminatedto prevent disk pressure
```

## File Download Workflow Detail

```mermaid
graph TB
    StartDownload[File Download Phase] --> CreateDiscoveryPods[Create Discovery Pods]
    
    subgraph "Discovery Pod Creation"
        CreateDiscoveryPods --> PodDiscoveryCreate[Pod Discovery Podsfor -s commands]
        CreateDiscoveryPods --> NodeDiscoveryCreate[Node Discovery Podsfor -S commands]
    end
    
    PodDiscoveryCreate --> WaitDiscoveryReady[Wait for Discovery Pods Ready]
    NodeDiscoveryCreate --> WaitDiscoveryReady
    
    WaitDiscoveryReady --> ExecuteCommands[Execute Select Commandswith Placeholder Substitution]
    
    subgraph "File Discovery Process"
        ExecuteCommands --> ParseFileList[Parse File Listsfrom Command Output]
        ParseFileList --> DownloadLoop{For Each File}
        DownloadLoop --> DownloadFile[kubectl cp namespace/pod:file local-output]
        DownloadFile --> RemoveFromHost[Remove Downloaded Filefrom Host Filesystem]
        RemoveFromHost --> NextFile{More Files?}
        NextFile -->|Yes| DownloadLoop
        NextFile -->|No| CleanupSuccess[Cleanup SuccessfulDiscovery Pods]
    end
    
    CleanupSuccess --> KeepFailedPods[Keep Failed Discovery Podsfor Inspection]
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