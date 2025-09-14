# Kill Switch Architecture

## Table of Contents

1. [Kill Switch Architecture Detail](#kill-switch-architecture-detail)
   - [System Architecture Overview](#system-architecture-overview)
   - [Component Integration Framework](#component-integration-framework)
   - [Protection Mechanisms](#protection-mechanisms)
2. [Kill Switch Monitoring Script Logic](#kill-switch-monitoring-script-logic)
   - [Monitoring Algorithm Architecture](#monitoring-algorithm-architecture)
   - [Threshold Calculation Systems](#threshold-calculation-systems)
   - [Decision Engine Implementation](#decision-engine-implementation)
3. [Storage Threshold Calculation Examples](#storage-threshold-calculation-examples)
   - [Calculation Methodologies](#calculation-methodologies)
   - [Implementation Strategies](#implementation-strategies)
   - [Performance Optimization](#performance-optimization)
4. [Kill Switch Configuration Examples](#kill-switch-configuration-examples)
   - [Configuration Patterns](#configuration-patterns)
   - [Best Practices](#best-practices)
   - [Troubleshooting Guide](#troubleshooting-guide)
5. [Safety and Recovery Mechanisms](#safety-and-recovery-mechanisms)
   - [Fail-Safe Design](#fail-safe-design)
   - [Recovery Strategies](#recovery-strategies)
   - [Monitoring and Alerting](#monitoring-and-alerting)

## Kill Switch Architecture Detail

This sequence diagram illustrates the kill switch monitoring architecture deployed across a Kubernetes cluster. It shows how the kube-dump controller creates and manages debug pods alongside their corresponding kill switch monitor pods, which continuously monitor storage usage and can terminate debug pods when thresholds are exceeded.

```mermaid
sequenceDiagram
    participant KC as Kube-dump Controller
    participant K8s as Kubernetes API
    participant NodeA as Node A
    participant NodeB as Node B
    participant NodeC as Node C
    participant DP1 as Debug Pod 1 (NodeA)
    participant DP2 as Debug Pod 2 (NodeB)
    participant DP3 as Node Debug Pod (NodeC)
    participant KM1 as Kill Switch Monitor 1
    participant KM2 as Kill Switch Monitor 2
    participant KM3 as Kill Switch Monitor 3
    participant VOL1 as Volume /tmp (NodeA)
    participant VOL2 as Volume /var (NodeB)
    participant VOL3 as Node Volume (NodeC)

    Note over KC,VOL3: Kill Switch Architecture Deployment

    KC->>K8s: Create debug pods
    K8s->>NodeA: Deploy Debug Pod 1 (nicolaka/netshoot)
    K8s->>NodeB: Deploy Debug Pod 2 (nicolaka/netshoot)
    K8s->>NodeC: Deploy Node Debug Pod (host networking)

    DP1->>NodeA: Start tcpdump/commands
    DP2->>NodeB: Start tcpdump/commands
    DP3->>NodeC: Start host-level debugging

    KC->>K8s: Create kill switch monitors
    K8s->>NodeA: Deploy Kill Switch Monitor 1 (ubuntu:22.04)
    K8s->>NodeB: Deploy Kill Switch Monitor 2 (ubuntu:22.04)
    K8s->>NodeC: Deploy Kill Switch Monitor 3 (ubuntu:22.04)

    par Continuous Monitoring
        KM1->>VOL1: Monitor /tmp volume usage
        KM1->>KM1: Check storage thresholds
        KM2->>VOL2: Monitor /var volume usage
        KM2->>KM2: Check storage thresholds
        KM3->>VOL3: Monitor node volume usage
        KM3->>KM3: Check storage thresholds
    end

    alt Threshold Exceeded on Node A
        KM1->>K8s: kubectl delete pod DP1
        K8s->>DP1: Terminate debug pod
        DP1->>NodeA: Debug pod terminated
    else Threshold Exceeded on Node B
        KM2->>K8s: kubectl delete pod DP2
        K8s->>DP2: Terminate debug pod
        DP2->>NodeB: Debug pod terminated
    else Threshold Exceeded on Node C
        KM3->>K8s: kubectl delete pod DP3
        K8s->>DP3: Terminate debug pod
        DP3->>NodeC: Debug pod terminated
    end

    Note over KC,VOL3: Kill switch protection active across all nodes
```

## Kill Switch Monitor Pod Creation Flow

This sequence diagram demonstrates the kill switch monitor pod creation process. It shows how kube-dump analyzes each debug pod, determines the appropriate volume monitoring configuration, generates monitor pods with the correct specifications, and initiates the background monitoring process.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DP as Debug Pod
    participant KM as Kill Switch Monitor
    participant Arrays as Monitor Arrays

    Note over KD,Arrays: Kill Switch Monitor Creation Process

    KD->>KD: Check kill switch configured?

    alt Kill switch enabled
        loop For each debug pod
            KD->>DP: Get debug pod's node name
            DP->>KD: Return node information
            KD->>KD: Determine volume path

            alt Pod contains 'node-debug'
                KD->>KD: Use NODE_VOLUME path
            else Regular debug pod
                KD->>KD: Use POD_VOLUME path
            end

            KD->>KD: Create monitor pod name (ks-{node}-{pod-hash})
            KD->>K8s: Create kill switch monitor pod manifest

            Note right of KD: Pod Specifications:<br/>- Image: ubuntu:22.04<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Node selector: target node

            KD->>K8s: Mount host root filesystem as /host (read-only)
            KD->>K8s: Generate monitor script with storage calculations
            K8s->>KM: Deploy monitor pod to target node
            KD->>Arrays: Add to monitor pods array
            KD->>KD: Continue with next debug pod
        end

        KD->>KD: All monitors created
        KD->>KM: Start background monitoring process
        KM->>KM: Begin continuous storage monitoring

    else Kill switch disabled
        KD->>KD: Skip kill switch setup
    end

    Note over KD,Arrays: Kill switch monitors active and ready
```

### System Architecture Overview

#### **Multi-Layered Protection Framework**

The kill switch architecture implements a comprehensive multi-layered protection system designed to prevent resource exhaustion during debugging operations. This sophisticated framework operates on multiple levels: cluster-wide coordination, node-level monitoring, and pod-specific protection mechanisms.

#### **Component Integration Framework**

**1. Controller Layer Architecture**
- **Kube-dump Controller**: Central orchestration component managing debug pod lifecycle and kill switch deployment
- **Resource Discovery**: Intelligent identification of target nodes and debug pod placement strategies
- **Monitor Pod Coordination**: Systematic deployment of kill switch monitors aligned with debug pod placement
- **State Management**: Comprehensive tracking of all protection components across the cluster

**2. Node-Level Monitor Architecture**
- **Dedicated Monitor Pods**: Specialized lightweight containers running on each target node
- **Host Integration**: Direct host filesystem and process access for accurate resource monitoring
- **Isolation Strategy**: Separate monitor pods prevent resource conflicts with debug operations
- **Communication Channels**: Secure communication with Kubernetes API for protective actions

**3. Storage Protection Framework**
- **Dual Threshold Support**: Both absolute (GB) and relative (percentage) threshold configurations
- **Volume-Specific Monitoring**: Targeted monitoring of specific filesystem paths and volumes
- **Real-time Calculation**: Continuous storage usage calculation with configurable intervals
- **Predictive Analysis**: Optional trend analysis for proactive protection

### Protection Mechanisms

#### **Automatic Response Systems**
- **Threshold Violation Detection**: Immediate detection of storage threshold breaches
- **Graduated Response**: Configurable response levels from warnings to immediate termination
- **Pod Selection Logic**: Intelligent selection of debug pods for termination based on resource usage
- **Cleanup Coordination**: Automatic cleanup of terminated debug pods and associated resources

#### **Safety and Reliability Features**
- **Monitor Redundancy**: Optional redundant monitor deployment for critical environments
- **Fail-Safe Design**: Default-safe behavior when monitor pods encounter errors
- **Recovery Mechanisms**: Automatic recovery from monitor pod failures with state preservation
- **Audit Trail**: Comprehensive logging of all protection actions for post-incident analysis

## Kill Switch Monitoring Script Logic

This sequence diagram shows the internal logic of the kill switch monitoring script running inside each monitor pod. It demonstrates the continuous monitoring loop, threshold calculations, decision-making process, and the kill action execution when storage limits are exceeded.

```mermaid
sequenceDiagram
    participant KM as Kill Switch Monitor
    participant BC as bc Calculator
    participant FS as File System
    participant K8s as Kubectl Command
    participant DP as Target Debug Pod

    Note over KM,DP: Kill Switch Monitoring Script Execution

    KM->>KM: Monitor script starts
    KM->>BC: Install bc if needed (for calculations)
    BC->>KM: Calculator ready

    loop Main monitoring loop
        KM->>FS: Get current usage (df command on volume)
        FS->>KM: Return volume usage statistics

        KM->>KM: Determine threshold type

        alt Absolute threshold
            KM->>BC: Calculate used space in bytes
            BC->>KM: Return byte calculation
            KM->>KM: Check: Used > Absolute threshold?

        else Relative threshold
            KM->>BC: Calculate free space percentage
            BC->>KM: Return percentage calculation
            KM->>KM: Check: Free < Relative threshold?
        end

        alt Threshold exceeded
            KM->>KM: 🔴 THRESHOLD EXCEEDED
            KM->>KM: Log threshold violation
            KM->>K8s: Execute kill command (kubectl delete pod)
            K8s->>DP: Delete target debug pod
            DP->>K8s: Pod deletion initiated
            K8s->>KM: Confirm pod deletion
            KM->>KM: Wait for pod deletion completion
            KM->>KM: Log successful kill
            KM->>KM: Monitor script exits
            break
        else Within limits
            KM->>KM: ✅ Within limits
            KM->>KM: Sleep 10 seconds
        end
    end

    Note over KM,DP: Monitoring completed (pod terminated or script ended)
```

## Storage Threshold Calculation Examples

This sequence diagram illustrates how different storage threshold types are processed and calculated by the kill switch monitoring system. It shows the conversion process for absolute thresholds, percentage calculations for relative thresholds, and volume path monitoring configurations.

```mermaid
sequenceDiagram
    participant User as User Input
    participant KM as Kill Switch Monitor
    participant Conv as Unit Converter
    participant Calc as Calculator
    participant FS as File System

    Note over User,FS: Storage Threshold Processing Examples

    par Absolute Threshold Processing
        User->>KM: --kill-switch-abs 1GB
        KM->>Conv: Convert 1GB to bytes
        Conv->>KM: Return 1,073,741,824 bytes
        KM->>FS: Get df output (used space in bytes)
        FS->>KM: Return current usage
        KM->>Calc: Compare used > 1,073,741,824?
        Calc->>KM: Return comparison result

    and
        User->>KM: --kill-switch-abs 500MB
        KM->>Conv: Convert 500MB to bytes
        Conv->>KM: Return 524,288,000 bytes
        KM->>FS: Get df output (used space in bytes)
        FS->>KM: Return current usage
        KM->>Calc: Compare used > 524,288,000?
        Calc->>KM: Return comparison result
    end

    par Relative Threshold Processing
        User->>KM: --kill-switch-rel 10%
        KM->>FS: Get df output (available and total space)
        FS->>KM: Return volume statistics
        KM->>Calc: Calculate free space (Available / Total * 100)
        Calc->>KM: Return percentage
        KM->>Calc: Compare free% < 10%?
        Calc->>KM: Return comparison result

    and
        User->>KM: --kill-switch-rel 5%
        KM->>FS: Get df output (available and total space)
        FS->>KM: Return volume statistics
        KM->>Calc: Calculate free space (Available / Total * 100)
        Calc->>KM: Return percentage
        KM->>Calc: Compare free% < 5%?
        Calc->>KM: Return comparison result
    end

    par Volume Monitoring Configuration
        User->>KM: --pod-volume /tmp (for pod debugging)
        KM->>FS: Monitor /host/tmp from monitor pod
        FS->>KM: Report /tmp volume statistics

    and
        User->>KM: --node-volume /var (for node debugging)
        KM->>FS: Monitor /host/var from monitor pod
        FS->>KM: Report /var volume statistics
    end

    Note over User,FS: Threshold calculations and volume monitoring active
```

## Monitor Pod YAML Structure

This sequence diagram shows the systematic construction of a kill switch monitor pod manifest. It demonstrates how kube-dump builds each section of the YAML configuration, from metadata and specifications to container settings and volume mounts, ensuring proper privileges and node targeting.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant Manifest as Pod Manifest Builder
    participant Meta as Metadata Section
    participant Spec as Spec Configuration
    participant Container as Container Section
    participant Volumes as Volume Section

    Note over KD,Volumes: Monitor Pod YAML Construction Process

    KD->>Manifest: Create monitor pod manifest

    Manifest->>Meta: Build metadata section
    Meta->>Meta: Set name (ks-{node}-{hash})
    Meta->>Meta: Set namespace (debug namespace)
    Meta->>Meta: Add labels (app: kill-switch-monitor, target-pod: debug pod name)
    Meta->>Manifest: Return metadata configuration

    Manifest->>Spec: Build spec configuration
    Spec->>Spec: Set restartPolicy: Never
    Spec->>Spec: Set hostNetwork: true
    Spec->>Spec: Set hostPID: true
    Spec->>Spec: Set nodeSelector (kubernetes.io/hostname: target node)

    Spec->>Container: Build container specification
    Container->>Container: Set image: ubuntu:22.04
    Container->>Container: Set command: /bin/bash -c
    Container->>Container: Set args: generated monitor script
    Container->>Container: Set securityContext: privileged: true
    Container->>Spec: Return container configuration

    Spec->>Volumes: Build volume mounts and volumes
    Volumes->>Volumes: Create volume mount (name: host-root, mountPath: /host, readOnly: true)
    Volumes->>Volumes: Create volume (hostPath: /, type: Directory)
    Volumes->>Spec: Return volume configuration

    Spec->>Manifest: Return complete spec configuration
    Manifest->>KD: Return complete monitor pod manifest

    KD->>KD: Deploy monitor pod with generated manifest

    Note over KD,Volumes: Monitor pod YAML structure complete and deployed
```