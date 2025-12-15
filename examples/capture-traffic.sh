#!/bin/bash
# Network capture script with podname parameter
# Captures network traffic and names the file with the pod name
#
# Usage:
#   ./kube-dump.sh -l app=web -e '%f %t 30 any' -f ./examples/capture-traffic.sh \
#     -s 'ls /host/tmp/*.pcap 2>/dev/null'
#
# Arguments:
#   $1 = target name (pod or node name from %t)
#   $2 = duration in seconds (default: 30)
#   $3 = interface (default: any)
#
# Output files are written to /host/tmp/ so they persist on the node
# and can be discovered by the -s selection command.

TARGET_NAME="${1:-unknown}"
DURATION="${2:-30}"  # Default 30 seconds
INTERFACE="${3:-any}"
OUTPUT_FILE="/host/tmp/${TARGET_NAME}-capture.pcap"

echo "=== Network Capture Script ==="
echo "Target: ${TARGET_NAME}"
echo "Duration: ${DURATION} seconds"
echo "Interface: ${INTERFACE}"
echo "Output: ${OUTPUT_FILE}"
echo ""

echo "Starting tcpdump (capturing for ${DURATION} seconds)..."
timeout "${DURATION}" tcpdump -i "${INTERFACE}" -nn -s 0 -w "${OUTPUT_FILE}" 2>&1

echo ""
echo "Capture complete!"
ls -lh "${OUTPUT_FILE}" 2>/dev/null || echo "Warning: Output file not created"
