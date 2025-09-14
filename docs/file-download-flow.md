# File Download Decision Flow

## File Download Process Overview

This sequence diagram illustrates the comprehensive file download process in kube-dump. It shows how the system creates discovery pods, tests their accessibility, executes file selection commands, downloads files with retry logic, and manages pod cleanup based on success or failure.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DisP as Discovery Pod
    participant FS as File System
    participant LocalFS as Local Storage

    Note over KD,LocalFS: File Download Process Flow

    KD->>KD: Check file download requested (-s/-S + -o)

    alt Output directory specified
        KD->>K8s: Create file discovery pods
        K8s->>DisP: Deploy discovery pods
        DisP->>KD: Pods ready

        loop For each discovery pod
            KD->>DisP: Test pod accessibility

            alt Pod accessible
                KD->>DisP: Execute select command (ignore exit code)
                DisP->>FS: Search for files
                FS->>DisP: Return file list

                alt Files found
                    loop For each file found
                        DisP->>DisP: Download with retry logic (max 3 attempts)

                        alt Download successful
                            DisP->>LocalFS: Save file locally
                            DisP->>FS: Remove file from node
                            DisP->>KD: File downloaded successfully

                        else Download failed after retries
                            DisP->>KD: Download failed
                            KD->>KD: Mark pod as failed
                        end
                    end

                else No files found
                    DisP->>KD: No files to download (mark as successful)
                end

            else Pod not accessible
                KD->>KD: Mark as failed pod, skip to next
            end

            DisP->>KD: Pod processing complete
        end

        KD->>K8s: Cleanup successful pods
        K8s->>DisP: Delete successful discovery pods
        KD->>KD: Keep failed pods for inspection
        KD->>KD: File download complete

    else No output directory
        KD->>KD: Skip file download
    end

    Note over KD,LocalFS: Download process completed
```

## File Selection Command Processing

This sequence diagram shows how kube-dump processes file selection commands within discovery pods. It demonstrates placeholder substitution, command decoding, execution, and the parsing of output to generate file lists for download operations.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant DisP as Discovery Pod
    participant CMD as Command Processor
    participant FS as File System

    Note over KD,FS: File Selection Command Processing

    KD->>DisP: Discovery pod created
    KD->>CMD: Apply placeholder substitution
    CMD->>CMD: Replace PLACEHOLDER_CHAR with original debug pod name

    alt Pod-targeted discovery
        CMD->>CMD: Use ENCODED_SELECT_COMMAND (from -s option)
    else Node-targeted discovery
        CMD->>CMD: Use ENCODED_NODE_SELECT_COMMAND (from -S option)
    end

    CMD->>CMD: Decode Base64 command
    KD->>DisP: Execute kubectl exec pod -- bash -c command
    DisP->>FS: Run decoded selection command
    FS->>DisP: Return command output
    DisP->>KD: Parse output as file list

    alt Command output empty
        KD->>KD: No files found (normal, not an error)
    else Files found in output
        loop For each file path
            KD->>KD: Create download path (OUTPUT_DIR/original_pod_name_filename)
            KD->>DisP: Attempt file download
        end
    end

    Note over KD,FS: File selection processing complete
```

## Pod Accessibility Test Logic

This sequence diagram demonstrates the pod accessibility testing mechanism used before attempting file operations. It shows how kube-dump validates pod connectivity and handles both successful and failed accessibility tests.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DisP as Discovery Pod
    participant Arrays as Pod Arrays

    Note over KD,Arrays: Pod Accessibility Validation

    KD->>K8s: Execute kubectl exec pod -- true
    K8s->>DisP: Test basic pod connectivity
    DisP->>K8s: Return command result
    K8s->>KD: Report execution status

    alt Command successful
        KD->>KD: Pod is accessible ✅
        KD->>DisP: Continue with file selection

        KD->>K8s: Execute select command with || true suffix
        K8s->>DisP: Run file selection command
        DisP->>K8s: Return output (exit code ignored)
        K8s->>KD: Capture command output
        KD->>KD: Process file list for downloads

    else Command failed
        KD->>KD: Pod not accessible ❌
        KD->>Arrays: Mark pod as failed
        Arrays->>Arrays: Add to failed_pods array
        KD->>KD: Skip file processing for this pod
        KD->>KD: Continue to next pod
    end

    Note over KD,Arrays: Accessibility test completed
```

## File Download Retry Mechanism

This sequence diagram illustrates the robust retry mechanism used for file downloads. It shows how kube-dump handles download failures with exponential backoff, tracks attempt counts, and manages both successful and failed download scenarios.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant DisP as Discovery Pod
    participant LocalFS as Local Storage
    participant FS as Node Filesystem
    participant Arrays as File Arrays

    Note over KD,Arrays: File Download with Retry Logic

    KD->>KD: Initialize (attempt=1, max_attempts=3, download_success=false)

    loop While attempt <= max_attempts AND not successful
        alt Retry attempt (attempt > 1)
            KD->>KD: Sleep 1 second (brief pause for recovery)
        end

        KD->>K8s: Execute kubectl cp pod:file local_file
        K8s->>DisP: Access source file
        DisP->>FS: Read file content
        FS->>DisP: Return file data
        DisP->>K8s: Stream file content
        K8s->>LocalFS: Save to local file
        LocalFS->>KD: Report download status

        alt Download successful
            KD->>KD: download_success = true

            alt First attempt success
                KD->>KD: Log: ✅ filename
            else Later attempt success
                KD->>KD: Log: ✅ filename (succeeded on attempt N)
            end

            KD->>Arrays: Add to downloaded_files array
        else Download failed
            KD->>KD: attempt++

            alt Last attempt
                KD->>KD: Log: ❌ Failed: filename (after 3 attempts)
                KD->>KD: Mark pod_had_failure = true
            else More attempts remaining
                KD->>KD: Log: ⚠️ Retrying filename (attempt X/3)
            end
        end
    end

    alt Any downloads successful
        KD->>K8s: Remove downloaded files from node filesystem
        K8s->>DisP: Delete source files
        DisP->>FS: Remove files from node
    end

    KD->>KD: File processing complete
    Note over KD,Arrays: Download retry mechanism completed
```

## Discovery Pod Creation Process

This sequence diagram shows how kube-dump creates specialized discovery pods for file operations. It illustrates the decision process between pod-targeted and node-targeted discovery, the manifest creation process, and the initialization of discovery pod arrays.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant K8s as Kubernetes API
    participant OrigDP as Original Debug Pods
    participant DisP as Discovery Pods
    participant Arrays as Discovery Arrays

    Note over KD,Arrays: Discovery Pod Creation Process

    KD->>KD: Determine discovery pod requirements

    alt Pod commands specified (-s)
        loop For each original debug pod
            KD->>OrigDP: Get pod info (name, container, node, namespace)
            OrigDP->>KD: Return pod details
            KD->>KD: Create discovery pod name (fd-{epoch}-{node}-{hash})

            KD->>K8s: Apply pod discovery manifest
            Note right of KD: Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Command: tail -f /dev/null<br/>- Mount /host (read-write)

            K8s->>DisP: Deploy pod discovery pod
            KD->>Arrays: Add to DISCOVERY_POD_INFO (pod:node:pod:original)
        end

    else Node commands specified (-S)
        loop For each node debug pod
            KD->>OrigDP: Get node name
            OrigDP->>KD: Return node details
            KD->>KD: Create node discovery pod name (nfd-{epoch}-{node})

            KD->>K8s: Apply node discovery manifest
            Note right of KD: Node Pod Spec:<br/>- Image: DEBUG_IMAGE<br/>- Host networking: true<br/>- Host PID: true<br/>- Privileged: true<br/>- Command: tail -f /dev/null<br/>- Mount /host (read-write)

            K8s->>DisP: Deploy node discovery pod
            KD->>Arrays: Add to DISCOVERY_POD_INFO (pod:node:node:original)
        end

    else Both pod and node commands
        Note over KD,DisP: Create both pod and node discovery pods
        KD->>KD: Execute both creation flows
    end

    loop Wait for all discovery pods
        KD->>K8s: Check pod readiness
        K8s->>DisP: Query pod status
        DisP->>K8s: Report ready status
        K8s->>KD: All discovery pods ready
    end

    DisP->>KD: Discovery pods active and ready for file operations
    Note over KD,Arrays: Discovery pod creation completed
```

## File Download Success/Failure Tracking

This sequence diagram illustrates how kube-dump tracks the success and failure of file download operations across all discovery pods. It shows the categorization process, cleanup decisions, and the final reporting of failed pods for manual inspection.

```mermaid
sequenceDiagram
    participant KD as kube-dump.sh
    participant Arrays as Tracking Arrays
    participant DisP as Discovery Pod
    participant K8s as Kubernetes API

    Note over KD,K8s: File Download Success/Failure Tracking

    KD->>Arrays: Initialize arrays (successful_pods=[], failed_pods=[])

    loop Process each discovery pod
        KD->>KD: Set pod_had_failure = false
        KD->>DisP: Process all files in pod

        loop For each file download
            DisP->>KD: Report download result

            alt Download failed
                KD->>KD: pod_had_failure = true
            end
        end

        alt Any download failed
            KD->>Arrays: Add to failed_pods array
            Arrays->>Arrays: Track failed pod for inspection

        else All downloads successful
            alt Pod was accessible
                KD->>Arrays: Add to successful_pods array
                Arrays->>Arrays: Track successful pod for cleanup
            else Pod was not accessible
                KD->>Arrays: Add to failed_pods array
                Arrays->>Arrays: Track inaccessible pod
            end
        end

        KD->>KD: Continue to next pod
    end

    KD->>KD: Processing complete

    KD->>K8s: Delete successful pods
    K8s->>DisP: kubectl delete pods successful_pods...
    DisP->>K8s: Successful pods terminated

    KD->>KD: Keep failed pods running
    KD->>KD: Display failed pods for inspection (🔍 pod-name)

    Note over KD,K8s: Success/failure tracking completed
```
