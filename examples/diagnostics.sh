#!/bin/bash
# Diagnostics script for --import-file feature
#
# Usage:
#   ./kube-dump.sh -l app=web -e '%f %p' --import-file ./examples/diagnostics.sh
#
# Arguments: $1 = podname (from %p)

POD_NAME="${1:-unknown}"
OUT="/tmp/diag-${POD_NAME}-$(date +%s)"

echo "=== Diagnostics for $POD_NAME ==="
mkdir -p "$OUT"

ip addr > "$OUT/ip.txt" 2>&1
ip route > "$OUT/routes.txt" 2>&1
ss -tunapl > "$OUT/sockets.txt" 2>&1
cat /etc/resolv.conf > "$OUT/dns.txt" 2>&1
env | sort > "$OUT/env.txt" 2>&1

echo "Saved to: $OUT"
ls -la "$OUT"
