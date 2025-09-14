# Pod Lifecycle Management

## Table of Contents

1. [Complete Pod Lifecycle Overview](#complete-pod-lifecycle-overview)
   - [Comprehensive Analysis and Architecture](#comprehensive-analysis-and-architecture)
   - [System Integration Patterns](#system-integration-patterns)
   - [Resource Management Strategy](#resource-management-strategy)
2. [Debug Pod Creation and Management](#debug-pod-creation-and-management)
   - [Pod Creation Architecture](#pod-creation-architecture)
   - [Deployment Strategies](#deployment-strategies)
   - [Resource Allocation Patterns](#resource-allocation-patterns)
3. [Kill Switch Monitor Pod Lifecycle](#kill-switch-monitor-pod-lifecycle)
   - [Protection System Architecture](#protection-system-architecture)
   - [Monitoring Algorithms](#monitoring-algorithms)
   - [Automatic Response Mechanisms](#automatic-response-mechanisms)
4. [Discovery Pod Lifecycle (File Downloads)](#discovery-pod-lifecycle-file-downloads)
   - [File Operation Architecture](#file-operation-architecture)
   - [Download Strategies](#download-strategies)
   - [Error Handling and Recovery](#error-handling-and-recovery)
5. [Pod State Transitions](#pod-state-transitions)
   - [State Management System](#state-management-system)
   - [Transition Triggers](#transition-triggers)
   - [Lifecycle Events](#lifecycle-events)
6. [Pod Resource Management](#pod-resource-management)
   - [Resource Tracking Architecture](#resource-tracking-architecture)
   - [Memory Management](#memory-management)
   - [Cleanup Coordination](#cleanup-coordination)
7. [Pod Cleanup Strategies](#pod-cleanup-strategies)
   - [Cleanup Decision Matrix](#cleanup-decision-matrix)
   - [Strategy Implementation](#strategy-implementation)
   - [Recovery Mechanisms](#recovery-mechanisms)

## Complete Pod Lifecycle Overview

This sequence diagram shows the complete lifecycle of kube-dump operations, from initialization through cleanup. It illustrates the interactions between the user, the kube-dump script, debug pods, kill switch monitors, and discovery pods throughout the entire debugging session.

```mermaid
sequenceDiagram
    participant U as User
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DP as Debug Pods
    participant KS as Kill Switch Monitors
    participant DisP as Discovery Pods

    Note over U,DisP: Pod Lifecycle Management - Complete Flow

    U->>KD: Execute kube-dump command
    KD->>K8s: Create debug pods
    K8s->>DP: Deploy debug pods to nodes

    KD->>K8s: Create kill switch monitor pods
    K8s->>KS: Deploy monitor pods

    DP->>KD: Debug pods ready
    KS->>KD: Monitor pods ready

    Note over DP,KS: Background Operations Active

    par Debug Pod Execution
        DP->>DP: Execute debug commands
    and Kill Switch Monitoring
        KS->>KS: Monitor storage thresholds
    end

    alt Manual Cleanup (User Input)
        U->>KD: Press Enter to stop
        KD->>KS: Stop kill switch monitoring
        KD->>K8s: Delete debug pods
        K8s->>DP: Terminate debug pods
        KD->>K8s: Delete monitor pods
        K8s->>KS: Terminate monitor pods

        opt File Downloads Requested
            KD->>K8s: Create discovery pods
            K8s->>DisP: Deploy discovery pods
            DisP->>DisP: Download files
            KD->>K8s: Delete successful discovery pods
            KD->>K8s: Keep failed discovery pods
        end

        KD->>U: Complete - all cleaned

    else Kill Switch Triggered
        KS->>K8s: Delete debug pod (threshold exceeded)
        K8s->>DP: Terminate debug pod
        KS->>KS: Monitor pod exits
        KD->>K8s: Manual cleanup of monitors
        K8s->>KS: Terminate monitor pods
        KD->>U: Kill switch cleanup complete

    else No-Cleanup Mode
        KD->>U: Debug pods kept running

        opt File Downloads Requested
            KD->>K8s: Create discovery pods
            K8s->>DisP: Deploy discovery pods
            DisP->>DisP: Download files
            KD->>K8s: Delete successful discovery pods
            KD->>K8s: Keep failed discovery pods
        end

        KD->>U: End - pods still running
    end
```

### Comprehensive Analysis and Architecture

#### **Pod Lifecycle Orchestration Framework**

The complete pod lifecycle management in kube-dump represents a sophisticated orchestration system that coordinates multiple pod types with distinct purposes while maintaining operational safety and resource efficiency. This framework manages three primary pod categories: debug pods, kill switch monitor pods, and discovery pods, each with specialized roles in the debugging ecosystem.

#### **Multi-Pod Coordination Strategy**

**1. Debug Pod Coordination**
- **Primary Function**: Execute debugging commands within target environments
- **Lifecycle Span**: From initialization through manual or automatic cleanup
- **Resource Characteristics**: Privileged access, namespace sharing, volume mounting
- **Coordination Points**: Synchronized with kill switch monitors for protection

**2. Kill Switch Monitor Coordination**
- **Primary Function**: Continuous monitoring and protection against resource exhaustion
- **Lifecycle Span**: Parallel to debug pods with automatic termination capability
- **Resource Characteristics**: Lightweight monitoring containers with kubectl access
- **Coordination Points**: Real-time communication with debug pods for protective actions

**3. Discovery Pod Coordination**
- **Primary Function**: File discovery, selection, and download operations
- **Lifecycle Span**: Post-debug phase or parallel execution in no-cleanup mode
- **Resource Characteristics**: File system access, download capabilities, retry mechanisms
- **Coordination Points**: Sequential execution after debug completion or parallel operation

### System Integration Patterns

#### **Kubernetes API Integration**
- **Resource Creation Patterns**: Batch creation of related pod resources with dependency management
- **State Synchronization**: Real-time monitoring of pod states across all categories
- **Event Handling**: Comprehensive event handling for pod lifecycle events
- **Error Recovery**: Automatic recovery mechanisms for failed pod operations

#### **Container Runtime Integration**
- **CRI Compatibility**: Seamless integration with containerd, CRI-O, and Docker runtimes
- **Namespace Management**: Sophisticated namespace sharing and isolation strategies
- **Volume Coordination**: Complex volume mounting strategies for different pod types
- **Security Context Management**: Dynamic security context configuration based on pod purpose

### Resource Management Strategy

#### **Resource Allocation Patterns**
- **Memory Management**: Intelligent memory allocation based on pod type and expected workload
- **CPU Scheduling**: Optimized CPU resource allocation with priority-based scheduling
- **Storage Coordination**: Efficient storage allocation and cleanup coordination
- **Network Resource Management**: Careful network resource allocation to avoid conflicts

#### **Cleanup Coordination Mechanisms**
- **Dependency-Aware Cleanup**: Ensures proper cleanup order respecting pod dependencies
- **Failure Recovery**: Robust cleanup mechanisms even in failure scenarios
- **Resource Leak Prevention**: Comprehensive tracking and cleanup of all allocated resources
- **Orphan Resource Detection**: Automatic detection and cleanup of orphaned resources

## Debug Pod Creation and Management

This sequence diagram demonstrates how kube-dump creates and manages debug pods based on execution mode (pod-targeted, node-targeted, or mixed). It shows the interaction between the kube-dump script, Kubernetes API, and target resources during debug pod initialization.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant TP as Target Pods
    participant TN as Target Nodes
    participant DP as Debug Pods

    Note over KD,DP: Debug Pod Creation Process

    KD->>KD: Analyze execution mode

    alt Pod-targeted Mode
        KD->>K8s: List target pods by selector
        K8s->>TP: Retrieve pod details
        TP->>KD: Return pod info (name, container, node, namespace)

        loop For each target pod
            KD->>KD: Generate debug pod name (debug-{epoch}-{node}-{hash})
            KD->>K8s: Create pod manifest
            Note right of KD: Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Target PID namespace<br/>- Network namespace shared<br/>- Privileged: true
            KD->>K8s: Apply debug pod manifest
            K8s->>DP: Deploy pod to target node
            KD->>KD: Add to DEBUG_POD_NAMES array
        end

    else Node-targeted Mode
        KD->>K8s: List target nodes by selector
        K8s->>TN: Retrieve node details
        TN->>KD: Return node info (name)

        loop For each target node
            KD->>KD: Generate debug pod name (node-debug-{epoch}-{node})
            KD->>K8s: Create node debug manifest
            Note right of KD: Node Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true
            KD->>K8s: Apply node debug manifest
            K8s->>DP: Deploy pod to node
            KD->>KD: Add to DEBUG_POD_NAMES array
        end

    else Mixed Mode
        Note over KD,DP: Execute both pod and node flows
        KD->>KD: Create both pod-targeted and node-targeted debug pods
    end

    KD->>KD: Apply placeholder substitution to commands

    loop Wait for all pods
        KD->>K8s: Check pod readiness
        K8s->>DP: Query pod status
        DP->>KD: Report pod status

        alt Pods not ready
            KD->>KD: Continue waiting
        else All pods ready
            KD->>KD: Debug pods active
        end
    end

    DP->>KD: All debug pods ready for execution
```

## Kill Switch Monitor Pod Lifecycle

This sequence diagram illustrates the kill switch monitoring system that protects against resource exhaustion. It shows how monitor pods continuously check storage thresholds and automatically terminate debug pods when limits are exceeded, ensuring system stability during debugging operations.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant KS as Kill Switch Monitor
    participant DP as Debug Pod
    participant BM as Background Monitor

    Note over KD,BM: Kill Switch Protection System

    KD->>KD: Kill switch configured

    loop For each debug pod
        KD->>K8s: Create monitor pod (ks-node-hash)
        K8s->>KS: Deploy monitor pod
        KS->>KS: Install bc calculator
        KS->>KS: Initialize storage monitoring loop

        Note over KS: Monitor starts background process

        loop Continuous monitoring every 10 seconds
            KS->>KS: Check storage usage
            KS->>KS: Calculate threshold exceeded?

            alt Threshold not exceeded
                KS->>KS: Continue monitoring
                Note right of KS: Normal operation

            else Threshold exceeded
                Note over KS,DP: KILL SWITCH ACTIVATED
                KS->>K8s: Execute kill command
                K8s->>DP: Delete debug pod
                DP->>K8s: Pod terminating
                K8s->>KS: Confirm deletion
                KS->>KS: Log kill success
                KS->>KS: Monitor pod exits
                break
            end
        end
    end

    par Background monitoring
        BM->>BM: Detect monitor pod exits
        BM->>KD: Report monitor pod status
        KD->>KD: Clean up monitor pod entries
    end

    Note over KD,BM: Automatic cleanup complete
```

## Discovery Pod Lifecycle (File Downloads)

This sequence diagram shows the file download process using discovery pods. It demonstrates how kube-dump creates specialized pods for file operations, executes file selection commands, downloads files with retry logic, and manages pod cleanup based on operation success.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DisP as Discovery Pod
    participant FS as File System
    participant LocalFS as Local Storage

    Note over KD,LocalFS: File Download Operations

    KD->>KD: File download phase initiated

    alt Pod Discovery Mode
        loop For each original debug pod
            KD->>K8s: Create fd-{epoch}-{node}-{hash}
            Note right of KD: Pod Discovery Spec:<br/>- Same node as debug pod<br/>- Host networking and PID<br/>- Privileged access<br/>- Mount /host read-write
            K8s->>DisP: Deploy pod discovery pod
        end

    else Node Discovery Mode
        loop For each target node
            KD->>K8s: Create nfd-{epoch}-{node}
            Note right of KD: Node Discovery Spec:<br/>- Target node<br/>- Host networking and PID<br/>- Privileged access<br/>- Mount /host read-write
            K8s->>DisP: Deploy node discovery pod
        end
    end

    DisP->>KD: Discovery pods active

    loop For each discovery pod
        KD->>DisP: Execute file selection commands
        DisP->>FS: Search for files (placeholder substitution)
        FS->>DisP: Return file list

        loop For each file found
            DisP->>DisP: Download file with retry (max 3 attempts)

            alt Download successful
                DisP->>LocalFS: Save file locally
                DisP->>FS: Remove file from node
                DisP->>KD: Download success
                KD->>KD: Add to successful_pods array

            else Download failed (after retries)
                DisP->>KD: Download failed
                KD->>KD: Add to failed_pods array
            end
        end

        alt Pod had successful downloads
            KD->>KD: Mark pod for deletion
            KD->>K8s: Delete successful discovery pod
            K8s->>DisP: Terminate pod

        else Pod had failures
            KD->>KD: Keep pod for inspection
            Note right of KD: Failed pods remain<br/>for debugging
        end
    end

    KD->>KD: Discovery phase complete
    Note over KD: Failed pods display info for manual inspection
```

## Pod State Transitions

This sequence diagram illustrates the various state transitions that pods undergo during their lifecycle in the kube-dump system. It shows how pods progress from creation through execution to termination, including the different triggers for state changes.

```mermaid
sequenceDiagram
    participant K8s as Kubernetes Scheduler
    participant Node as Kubernetes Node
    participant Pod as Pod Instance
    participant KD as kube-dump.sh
    participant KS as Kill Switch

    Note over K8s,KS: Pod State Lifecycle Transitions

    K8s->>Pod: Create pod
    Note right of Pod: State: Pending

    K8s->>Node: Schedule pod to node
    Node->>Pod: Start scheduling
    Note right of Pod: State: ContainerCreating

    Node->>Pod: Container image pulled & started
    Note right of Pod: State: Running

    par Normal Operations
        Pod->>Pod: Execute debug commands
        Pod->>Pod: Monitor storage (kill switch pods)
        Pod->>Pod: Handle file downloads (discovery pods)
    end

    alt Manual Cleanup Trigger
        KD->>Pod: Request termination
        Note right of Pod: User pressed Enter
        Pod->>Pod: State: Terminating
        Pod->>K8s: Graceful shutdown
        Pod->>Pod: File cleanup & resource release
        K8s->>Pod: Pod deleted
        Note right of Pod: State: [Terminated]

    else Kill Switch Trigger
        KS->>Pod: Force termination
        Note right of Pod: Storage threshold exceeded
        Pod->>Pod: State: Terminating
        Pod->>K8s: Graceful shutdown
        Pod->>Pod: File cleanup & resource release
        K8s->>Pod: Pod deleted
        Note right of Pod: State: [Terminated]

    else No-cleanup Timeout
        KD->>Pod: Timeout termination
        Note right of Pod: Timeout reached
        Pod->>Pod: State: Terminating
        Pod->>K8s: Graceful shutdown
        K8s->>Pod: Pod deleted
        Note right of Pod: State: [Terminated]

    else Container Crash
        Pod->>Pod: Container failure
        Note right of Pod: State: Failed
        K8s->>Pod: Garbage collection
        Note right of Pod: State: [Terminated]
    end

    Note over K8s,KS: Pod lifecycle complete
```

## Pod Resource Management

This sequence diagram demonstrates how kube-dump manages pod resources through internal arrays and data structures. It shows the lifecycle of resource tracking from creation through cleanup, including the interaction between different operation types and pod states.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant Arrays as Resource Arrays
    participant Ops as Operations Engine
    participant PS as Pod States

    Note over KD,PS: Resource Management System

    KD->>Arrays: Initialize resource arrays
    Note right of Arrays: DEBUG_POD_NAMES[]<br/>KILL_SWITCH_MONITOR_PODS[]<br/>DISCOVERY_POD_NAMES[]<br/>DISCOVERY_POD_INFO[]

    par Pod Creation Operations
        Ops->>Arrays: Add to DEBUG_POD_NAMES[]
        Ops->>Arrays: Add to KILL_SWITCH_MONITOR_PODS[]
        Ops->>Arrays: Add to DISCOVERY_POD_NAMES[]
        Ops->>Arrays: Add to DISCOVERY_POD_INFO[]
    end

    Arrays->>PS: Update pod states
    Note right of PS: Active Debug Pods<br/>Active Monitor Pods<br/>Active Discovery Pods<br/>Failed Discovery Pods

    par Monitoring Operations
        Ops->>Arrays: Query DEBUG_POD_NAMES[]
        Arrays->>PS: Report Active Debug Pods
        Ops->>Arrays: Query KILL_SWITCH_MONITOR_PODS[]
        Arrays->>PS: Report Active Monitor Pods
    end

    par File Operations
        Ops->>Arrays: Access DISCOVERY_POD_NAMES[]
        Arrays->>PS: Report Active Discovery Pods
        Ops->>Arrays: Access DISCOVERY_POD_INFO[]
        Arrays->>PS: Report Failed Discovery Pods
    end

    par Cleanup Operations
        Ops->>Arrays: Remove from DEBUG_POD_NAMES[]
        Arrays->>PS: Update Active Debug Pods
        Ops->>Arrays: Remove from KILL_SWITCH_MONITOR_PODS[]
        Arrays->>PS: Update Active Monitor Pods
        Ops->>Arrays: Remove from DISCOVERY_POD_NAMES[]
        Arrays->>PS: Update Active Discovery Pods
    end

    PS->>KD: Resource management complete
    Note over KD,PS: All pod resources tracked and managed
```

## Pod Cleanup Strategies

This sequence diagram illustrates the various cleanup strategies available in kube-dump based on different termination scenarios. It shows how the system handles manual cleanup, no-cleanup mode, and kill switch activation, including the conditional file download operations.

```mermaid
sequenceDiagram
    participant U as User
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DP as Debug Pods
    participant KS as Kill Switch Monitors
    participant DisP as Discovery Pods

    Note over U,DisP: Cleanup Strategy Selection

    KD->>KD: Determine cleanup type

    alt Manual Cleanup
        U->>KD: Press Enter to stop
        KD->>KS: Stop kill switch monitoring
        KD->>K8s: Delete debug pods array
        K8s->>DP: Terminate all debug pods
        KD->>K8s: Delete monitor pods array
        K8s->>KS: Terminate all monitor pods

        opt File downloads requested
            KD->>K8s: Create discovery pods
            K8s->>DisP: Deploy discovery pods
            DisP->>DisP: Download files
            KD->>K8s: Delete successful discovery pods
            K8s->>DisP: Terminate successful pods
            Note right of KD: Keep failed pods for inspection
        end

        KD->>U: Complete cleanup

    else No-Cleanup Mode
        Note over KD: --no-cleanup flag set

        alt File downloads requested
            KD->>KD: Keep debug pods running
            KD->>K8s: Create discovery pods
            K8s->>DisP: Deploy discovery pods
            DisP->>DisP: Download files
            KD->>K8s: Delete successful discovery pods
            K8s->>DisP: Terminate successful pods
            KD->>U: Partial cleanup complete (debug pods kept)
        else No file downloads
            KD->>U: End - all pods kept running
        end

    else Kill Switch Activation
        KS->>K8s: Individual pod killed (threshold exceeded)
        K8s->>DP: Terminate specific debug pod
        KS->>KS: Monitor pod exits
        KD->>KD: Remove from monitor array
        KD->>U: Kill switch cleanup for specific pod
    end

    Note over U,DisP: Cleanup strategy completed
```