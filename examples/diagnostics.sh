#!/bin/bash
# Diagnostics script for --import-file feature
#
# Usage:
#   ./kube-dump.sh -l app=web -f ./examples/diagnostics.sh -e '%f %t'
#
# Arguments:
#   $1 = script path (from %f)
#   $2 = target name - pod or node (from %t)
#
# IMPORTANT: Output files must be written to /host/tmp/ (not /tmp/) when using
# --pod-volume or --node-volume mounts, so they persist on the host filesystem
# and can be collected by the -s/-S download commands.

TARGET_NAME="${2:-unknown}"
OUT="/host/tmp/diag-${TARGET_NAME}-$(date +%s)"

echo "=== Diagnostics for $TARGET_NAME ==="
mkdir -p "$OUT"

ip addr > "$OUT/ip.txt" 2>&1
ip route > "$OUT/routes.txt" 2>&1
ss -tunapl > "$OUT/sockets.txt" 2>&1
cat /etc/resolv.conf > "$OUT/dns.txt" 2>&1
env | sort > "$OUT/env.txt" 2>&1

echo "Saved to: $OUT"
ls -la "$OUT"
