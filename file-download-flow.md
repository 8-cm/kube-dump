# File Download Decision Flow

## File Download Process Overview

```mermaid
graph TD
    A[File Download Requested?<br/>-s or -S options + -o directory] --> B{Output Directory<br/>Specified?}
    B -->|No| C[Skip File Download]
    B -->|Yes| D[Create File Discovery Pods]
    
    D --> E[Wait for Discovery Pods Ready]
    E --> F[For Each Discovery Pod]
    F --> G[Test Pod Accessibility]
    
    G --> H{Pod Accessible?}
    H -->|No| I[❌ Mark as Failed Pod<br/>Skip to next pod]
    H -->|Yes| J[Execute Select Command<br/>Ignore exit code]
    
    J --> K{Files Found?}
    K -->|No| L[📂 No files to download<br/>Mark as Successful]
    K -->|Yes| M[Download Each File<br/>with Retry Logic]
    
    M --> N[For Each File Found]
    N --> O[Download with 3 Attempts]
    O --> P{Download<br/>Successful?}
    
    P -->|Yes| Q[✅ File Downloaded]
    P -->|No| R[❌ Download Failed<br/>after 3 attempts]
    
    Q --> S[Remove File from Node]
    R --> T[Mark Pod as Failed]
    
    S --> U[Continue to Next File]
    T --> U
    U --> V{More Files?}
    V -->|Yes| N
    V -->|No| W[Pod Processing Complete]
    
    L --> W
    I --> W
    W --> X{More Discovery<br/>Pods?}
    X -->|Yes| F
    X -->|No| Y[Cleanup Successful Pods]
    
    Y --> Z[Keep Failed Pods for Inspection]
    Z --> AA[File Download Complete]
    
    style A fill:#fff2cc
    style H fill:#fff2cc
    style K fill:#fff2cc
    style P fill:#fff2cc
    style V fill:#fff2cc
    style X fill:#fff2cc
    style I fill:#f8cecc
    style R fill:#f8cecc
    style T fill:#f8cecc
    style L fill:#e8f5e8
    style Q fill:#e8f5e8
    style Y fill:#d5e8d4
    style AA fill:#e1f5fe
```

## File Selection Command Processing

```mermaid
graph TD
    A[Discovery Pod Created] --> B[Apply Placeholder Substitution]
    B --> C[Replace PLACEHOLDER_CHAR<br/>with original debug pod name]
    
    C --> D{Pod Type?}
    D -->|pod| E[Use ENCODED_SELECT_COMMAND<br/>from -s option]
    D -->|node| F[Use ENCODED_NODE_SELECT_COMMAND<br/>from -S option]
    
    E --> G[Decode Base64 Command]
    F --> G
    G --> H[Execute: kubectl exec pod -- bash -c command]
    H --> I[Parse Output as File List]
    
    I --> J{Command Output<br/>Empty?}
    J -->|Yes| K[No Files Found<br/>This is normal, not an error]
    J -->|No| L[Process Each File Path]
    
    L --> M[Create Download Path:<br/>OUTPUT_DIR/original_pod_name_filename]
    M --> N[Attempt File Download]
    
    style B fill:#fff3e0
    style C fill:#fff3e0
    style D fill:#fff2cc
    style J fill:#fff2cc
    style K fill:#e8f5e8
    style N fill:#d5e8d4
```

## Pod Accessibility Test Logic

```mermaid
graph TD
    A[Start Pod Accessibility Test] --> B[Execute: kubectl exec pod -- true]
    B --> C{Command<br/>Successful?}
    
    C -->|Yes| D[✅ Pod is Accessible]
    C -->|No| E[❌ Pod Not Accessible]
    
    D --> F[Continue with File Selection]
    E --> G[Mark Pod as Failed]
    G --> H[Add to failed_pods array]
    H --> I[Skip File Processing]
    I --> J[Continue to Next Pod]
    
    F --> K[Execute Select Command<br/>with || true suffix]
    K --> L[Capture Output<br/>Exit code ignored]
    
    style C fill:#fff2cc
    style D fill:#e8f5e8
    style E fill:#f8cecc
    style K fill:#fff3e0
```

## File Download Retry Mechanism

```mermaid
graph TD
    A[Start File Download] --> B[Initialize:<br/>- attempt = 1<br/>- max_attempts = 3<br/>- download_success = false]
    
    B --> C{attempt <= max_attempts<br/>AND not successful?}
    C -->|No| D[Max Attempts Reached]
    C -->|Yes| E{attempt > 1?}
    
    E -->|Yes| F[Sleep 1 second<br/>Brief pause for recovery]
    E -->|No| G[Execute Download:<br/>kubectl cp pod:file local_file]
    
    F --> G
    G --> H{Download<br/>Successful?}
    
    H -->|Yes| I[download_success = true]
    H -->|No| J[attempt++]
    
    I --> K{First Attempt?}
    K -->|Yes| L[✅ filename]
    K -->|No| M[✅ filename<br/>(succeeded on attempt N)]
    
    J --> N{Last Attempt?}
    N -->|Yes| O[❌ Failed: filename<br/>(after 3 attempts)]
    N -->|No| P[⚠️ Retrying filename<br/>(attempt X/3)]
    
    L --> Q[Add to downloaded_files array]
    M --> Q
    P --> R[Continue to Next Attempt]
    O --> S[Mark pod_had_failure = true]
    
    D --> T{Any Downloads<br/>Successful?}
    T -->|Yes| U[Remove Downloaded Files<br/>from Node Filesystem]
    T -->|No| V[No Cleanup Needed]
    
    Q --> U
    R --> C
    S --> C
    U --> W[File Processing Complete]
    V --> W
    
    style C fill:#fff2cc
    style E fill:#fff2cc
    style H fill:#fff2cc
    style K fill:#fff2cc
    style N fill:#fff2cc
    style T fill:#fff2cc
    style I fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
    style O fill:#f8cecc
    style P fill:#fff3e0
```

## Discovery Pod Creation Process

```mermaid
graph TD
    A[Create File Discovery Pods] --> B{Pod or Node<br/>Select Commands?}
    B -->|Pod commands (-s)| C[Create Pod Discovery Pods]
    B -->|Node commands (-S)| D[Create Node Discovery Pods]
    B -->|Both| E[Create Both Types]
    
    C --> F[For Each Original Debug Pod]
    F --> G[Get Pod Info:<br/>name, container, node, namespace]
    G --> H[Create Discovery Pod Name:<br/>fd-{epoch}-{node}-{hash}]
    H --> I[Apply Pod Discovery Manifest]
    
    D --> J[For Each Node Debug Pod]
    J --> K[Get Node Name]
    K --> L[Create Node Discovery Pod Name:<br/>nfd-{epoch}-{node}]
    L --> M[Apply Node Discovery Manifest]
    
    I --> N[Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Command: tail -f /dev/null]
    
    M --> O[Node Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Command: tail -f /dev/null]
    
    N --> P[Mount /host (read-write)]
    O --> P
    P --> Q[Add to DISCOVERY_POD_INFO array<br/>Format: pod:node:type:original]
    Q --> R[Wait for All Discovery Pods Ready]
    
    style B fill:#fff2cc
    style I fill:#d5e8d4
    style M fill:#d5e8d4
    style R fill:#e1f5fe
```

## File Download Success/Failure Tracking

```mermaid
graph TD
    A[Initialize Arrays:<br/>successful_pods=()<br/>failed_pods=()] --> B[Process Each Discovery Pod]
    
    B --> C[pod_had_failure = false]
    C --> D[Process All Files in Pod]
    D --> E{Any Download<br/>Failed?}
    
    E -->|Yes| F[pod_had_failure = true]
    E -->|No| G[All Downloads Successful]
    
    F --> H[Add to failed_pods array]
    G --> I{Pod Was<br/>Accessible?}
    
    I -->|Yes| J[Add to successful_pods array]
    I -->|No| H
    
    H --> K[Continue to Next Pod]
    J --> K
    K --> L{More Pods?}
    
    L -->|Yes| B
    L -->|No| M[Processing Complete]
    
    M --> N[Delete Successful Pods:<br/>kubectl delete pods successful_pods...]
    N --> O[Keep Failed Pods Running]
    O --> P[Display Failed Pods for Inspection:<br/>🔍 pod-name]
    
    style E fill:#fff2cc
    style I fill:#fff2cc
    style L fill:#fff2cc
    style G fill:#e8f5e8
    style J fill:#e8f5e8
    style F fill:#f8cecc
    style H fill:#f8cecc
    style N fill:#d5e8d4
    style O fill:#fff3e0
```