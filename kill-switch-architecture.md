# Kill Switch Monitoring Architecture

## Kill Switch Architecture Overview

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Control Plane"
            KC[Kube-dump Controller<br/>Main Process]
        end
        
        subgraph "Node A"
            DP1[Debug Pod 1<br/>nicolaka/netshoot<br/>Running tcpdump/commands]
            KM1[Kill Switch Monitor 1<br/>ubuntu:22.04<br/>Storage monitoring]
            VOL1[Volume Mount<br/>/tmp or /var]
            
            KM1 -.->|monitors| VOL1
            KM1 -.->|can kill| DP1
        end
        
        subgraph "Node B"
            DP2[Debug Pod 2<br/>nicolaka/netshoot<br/>Running tcpdump/commands]
            KM2[Kill Switch Monitor 2<br/>ubuntu:22.04<br/>Storage monitoring]
            VOL2[Volume Mount<br/>/tmp or /var]
            
            KM2 -.->|monitors| VOL2
            KM2 -.->|can kill| DP2
        end
        
        subgraph "Node C"
            DP3[Node Debug Pod<br/>nicolaka/netshoot<br/>Host networking]
            KM3[Kill Switch Monitor 3<br/>ubuntu:22.04<br/>Storage monitoring]
            VOL3[Node Volume<br/>/var or custom]
            
            KM3 -.->|monitors| VOL3
            KM3 -.->|can kill| DP3
        end
    end
    
    KC -->|creates & manages| DP1
    KC -->|creates & manages| DP2
    KC -->|creates & manages| DP3
    KC -->|creates| KM1
    KC -->|creates| KM2
    KC -->|creates| KM3
    
    style KC fill:#e1f5fe
    style DP1 fill:#e8f5e8
    style DP2 fill:#e8f5e8
    style DP3 fill:#f3e5f5
    style KM1 fill:#fff3e0
    style KM2 fill:#fff3e0
    style KM3 fill:#fff3e0
    style VOL1 fill:#ffebee
    style VOL2 fill:#ffebee
    style VOL3 fill:#ffebee
```

## Kill Switch Monitor Pod Creation Flow

```mermaid
graph TD
    A[Kill Switch Configured?] -->|Yes| B[For Each Debug Pod]
    A -->|No| Z[Skip Kill Switch Setup]
    
    B --> C[Get Debug Pod's Node Name]
    C --> D[Determine Volume Path]
    D --> E{Pod Type?}
    
    E -->|Contains 'node-debug'| F[Use NODE_VOLUME path]
    E -->|Regular debug pod| G[Use POD_VOLUME path]
    
    F --> H[Create Monitor Pod Name:<br/>ks-{node}-{pod-hash}]
    G --> H
    
    H --> I[Create Kill Switch Monitor Pod]
    I --> J[Pod Specifications:<br/>- Image: ubuntu:22.04<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Node selector: target node]
    
    J --> K[Mount Host Root Filesystem<br/>as /host (read-only)]
    K --> L[Generate Monitor Script<br/>with Storage Calculations]
    L --> M[Deploy Monitor Pod]
    M --> N[Add to Monitor Pods Array]
    N --> O[Continue with Next Debug Pod]
    O --> P[All Monitors Created]
    P --> Q[Start Background Monitoring Process]
    
    style A fill:#fff2cc
    style E fill:#fff2cc
    style I fill:#d5e8d4
    style Q fill:#e1f5fe
```

## Kill Switch Monitoring Script Logic

```mermaid
graph TD
    A[Monitor Script Starts] --> B[Install bc if needed<br/>for calculations]
    B --> C[Main Monitoring Loop]
    
    C --> D[Get Current Usage:<br/>df command on volume]
    D --> E{Threshold Type?}
    
    E -->|Absolute| F[Calculate Used Space<br/>in bytes]
    E -->|Relative| G[Calculate Free Space<br/>percentage]
    
    F --> H{Used > Absolute<br/>Threshold?}
    G --> I{Free < Relative<br/>Threshold?}
    
    H -->|Yes| J[🔴 THRESHOLD EXCEEDED]
    H -->|No| K[✅ Within limits]
    I -->|Yes| J
    I -->|No| K
    
    J --> L[Log Threshold Violation]
    L --> M[Execute Kill Command:<br/>kubectl delete pod]
    M --> N[Wait for Pod Deletion]
    N --> O[Log Successful Kill]
    O --> P[Monitor Script Exits]
    
    K --> Q[Sleep 10 seconds]
    Q --> C
    
    style A fill:#e1f5fe
    style J fill:#f8cecc
    style M fill:#ffebee
    style P fill:#d5e8d4
    style E fill:#fff2cc
    style H fill:#fff2cc
    style I fill:#fff2cc
```

## Storage Threshold Calculation Examples

```mermaid
graph LR
    subgraph "Absolute Thresholds"
        A1[--kill-switch-abs 1GB] --> B1[Convert to bytes:<br/>1,073,741,824]
        A2[--kill-switch-abs 500MB] --> B2[Convert to bytes:<br/>524,288,000]
        
        B1 --> C1[Compare with df output:<br/>Used space in bytes]
        B2 --> C1
    end
    
    subgraph "Relative Thresholds"
        A3[--kill-switch-rel 10%] --> B3[Calculate free space:<br/>Available / Total * 100]
        A4[--kill-switch-rel 5%] --> B3
        
        B3 --> C2[Compare with threshold:<br/>Free% < Threshold%]
    end
    
    subgraph "Volume Monitoring"
        D1[Pod Volume:<br/>--pod-volume /tmp] --> E1[Monitor /host/tmp<br/>from monitor pod]
        D2[Node Volume:<br/>--node-volume /var] --> E2[Monitor /host/var<br/>from monitor pod]
    end
    
    style A1 fill:#e8f5e8
    style A2 fill:#e8f5e8
    style A3 fill:#f3e5f5
    style A4 fill:#f3e5f5
    style D1 fill:#fff3e0
    style D2 fill:#fff3e0
```

## Monitor Pod YAML Structure

```mermaid
graph TD
    A[Monitor Pod Manifest] --> B[Metadata]
    A --> C[Spec Configuration]
    
    B --> B1[Name: ks-{node}-{hash}]
    B --> B2[Namespace: debug namespace]
    B --> B3[Labels:<br/>- app: kill-switch-monitor<br/>- target-pod: debug pod name]
    
    C --> C1[RestartPolicy: Never]
    C --> C2[HostNetwork: true]
    C --> C3[HostPID: true]
    C --> C4[NodeSelector:<br/>kubernetes.io/hostname: target node]
    
    C --> D[Container Spec]
    D --> D1[Image: ubuntu:22.04]
    D --> D2[Command: /bin/bash -c]
    D --> D3[Args: Generated monitor script]
    D --> D4[SecurityContext: privileged: true]
    
    C --> E[Volume Mounts]
    E --> E1[Name: host-root]
    E --> E2[MountPath: /host]
    E --> E3[ReadOnly: true]
    
    C --> F[Volumes]
    F --> F1[HostPath: /]
    F --> F2[Type: Directory]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#fff3e0
    style E fill:#ffebee
    style F fill:#e0f2f1
```