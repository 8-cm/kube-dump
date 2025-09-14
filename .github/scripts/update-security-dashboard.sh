#!/bin/bash
# ===============================================================================
# Security Dashboard Update Script
# ===============================================================================
# Description:
#   Safely updates the README.md security dashboard section with current security
#   status from multiple workflows. Uses file locking to prevent race conditions
#   when multiple workflows run simultaneously.
#
# Usage:
#   ./update-security-dashboard.sh <component> <status>
#
# Parameters:
#   component: Either "container" or "code-quality"
#   status: The security status (e.g., "✅ PASSED", "⚠️ ISSUES FOUND")
#
# Features:
#   - File locking to prevent concurrent modifications
#   - Atomic updates to prevent corrupted README.md
#   - Status preservation across workflow runs
#   - Automatic fallback to default values when data is missing
# ===============================================================================

set -euo pipefail

# Check parameters
if [ $# -ne 2 ]; then
    echo "Usage: $0 <component> <status>"
    echo "Components: container, code-quality"
    exit 1
fi

COMPONENT="$1"
STATUS="$2"
LOCKFILE="/tmp/readme-update.lock"
TIMEOUT=60

# Function to acquire lock with timeout
acquire_lock() {
    local count=0
    while [ $count -lt $TIMEOUT ]; do
        if mkdir "$LOCKFILE" 2>/dev/null; then
            echo "Lock acquired"
            return 0
        fi
        echo "Waiting for lock... ($count/$TIMEOUT)"
        sleep 1
        ((count++))
    done
    echo "Failed to acquire lock after $TIMEOUT seconds"
    exit 1
}

# Function to release lock
release_lock() {
    if [ -d "$LOCKFILE" ]; then
        rmdir "$LOCKFILE"
        echo "Lock released"
    fi
}

# Ensure lock is released on exit
trap release_lock EXIT

echo "Updating security dashboard for component: $COMPONENT with status: $STATUS"

# Acquire lock
acquire_lock

# Create backup
cp README.md README.md.bak

# Read current status from security-reports.md if available
get_container_status() {
    if [ -f "docs/security-reports.md" ] && grep -q "Container Security" docs/security-reports.md 2>/dev/null; then
        grep -A 10 "Container Security" docs/security-reports.md | grep "Status:" | head -1 | sed 's/.*Status: *//' | sed 's/ .*//' || echo "🔄 Scanning"
    else
        echo "🔄 Scanning"
    fi
}

get_code_quality_status() {
    if [ -f "docs/security-reports.md" ] && grep -q "Code Quality" docs/security-reports.md 2>/dev/null; then
        grep -A 10 "Code Quality" docs/security-reports.md | grep "Status:" | head -1 | sed 's/.*Status: *//' | sed 's/ .*//' || echo "🔄 Analyzing"
    else
        echo "🔄 Analyzing"
    fi
}

# Get current statuses
if [ "$COMPONENT" = "container" ]; then
    CONTAINER_STATUS="$STATUS"
    CODE_QUALITY_STATUS=$(get_code_quality_status)
elif [ "$COMPONENT" = "code-quality" ]; then
    CONTAINER_STATUS=$(get_container_status)
    CODE_QUALITY_STATUS="$STATUS"
else
    echo "Invalid component: $COMPONENT"
    exit 1
fi

echo "Container Security Status: $CONTAINER_STATUS"
echo "Code Quality Status: $CODE_QUALITY_STATUS"

# Create new README content with security dashboard
{
    # Keep everything before the security dashboard
    sed '/<!-- SECURITY-DASHBOARD-START -->/q' README.md | sed '$d' 2>/dev/null || cat README.md
    echo "<!-- SECURITY-DASHBOARD-START -->"
    echo ""
    echo "## 🛡️ Security Status"
    echo ""
    echo "| Component | Status | Last Updated |"
    echo "|-----------|--------|--------------|"
    echo "| **Container Security** | $CONTAINER_STATUS | Automated |"
    echo "| **Code Quality** | $CODE_QUALITY_STATUS | Automated |"
    echo ""
    echo "**Vulnerability Summary:** Automated security scanning in progress"
    echo ""
    echo "📋 [View Detailed Security Reports](docs/security-reports.md) for complete vulnerability analysis and recommendations."
    echo ""
    echo "<!-- SECURITY-DASHBOARD-END -->"

    # Keep everything after the security dashboard
    sed -n '/<!-- SECURITY-DASHBOARD-END -->/,$p' README.md.bak | tail -n +2 2>/dev/null || echo ""
} > README.md.new

# Replace old README with new one atomically
mv README.md.new README.md

echo "README.md security dashboard updated successfully!"
echo "Component '$COMPONENT' status set to: $STATUS"