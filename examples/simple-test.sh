#!/bin/bash
# Simple test script for --import-file feature
#
# Usage:
#   ./kube-dump.sh -l app=web -e '%f' --import-file ./examples/simple-test.sh
#
# %f is auto-written to temp file, executed, then cleaned up!

echo "================================"
echo "  Import File Test - SUCCESS!"
echo "================================"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo "Test completed successfully."
