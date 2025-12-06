#!/bin/bash
# Network capture script with podname parameter
# Captures network traffic and names the file with the pod name
#
# Usage:
#   ./kube-dump.sh -l app=web -e 'echo %f | base64 -d | bash -s %p' --import-file ./examples/capture-traffic.sh

POD_NAME="${1:-unknown}"
DURATION="${2:-30}"  # Default 30 seconds
INTERFACE="${3:-any}"
OUTPUT_FILE="/tmp/${POD_NAME}-capture.pcap"

echo "=== Network Capture Script ==="
echo "Pod: ${POD_NAME}"
echo "Duration: ${DURATION} seconds"
echo "Interface: ${INTERFACE}"
echo "Output: ${OUTPUT_FILE}"
echo ""

echo "Starting tcpdump (capturing for ${DURATION} seconds)..."
timeout "${DURATION}" tcpdump -i "${INTERFACE}" -nn -s 0 -w "${OUTPUT_FILE}" 2>&1

echo ""
echo "Capture complete!"
ls -lh "${OUTPUT_FILE}" 2>/dev/null || echo "Warning: Output file not created"
