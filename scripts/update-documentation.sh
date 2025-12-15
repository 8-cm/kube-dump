#!/bin/bash
# Script to update README security dashboard from CI pipeline

set -e

SHELLCHECK_STATUS="${1:-UNKNOWN}"
SHELLCHECK_ISSUES="${2:-0}"
TOTAL_CRITICAL="${3:-0}"
TOTAL_HIGH="${4:-0}"
TOTAL_MEDIUM="${5:-0}"
TOTAL_LOW="${6:-0}"

CURRENT_DATE=$(date +%Y-%m-%d)

echo "Updating README.md security dashboard..."
echo "  SHELLCHECK_STATUS: $SHELLCHECK_STATUS"
echo "  SHELLCHECK_ISSUES: $SHELLCHECK_ISSUES"
echo "  TOTAL_CRITICAL: $TOTAL_CRITICAL"
echo "  TOTAL_HIGH: $TOTAL_HIGH"
echo "  TOTAL_MEDIUM: $TOTAL_MEDIUM"
echo "  TOTAL_LOW: $TOTAL_LOW"

# Determine container security status based on vulnerability counts
if [[ "$TOTAL_CRITICAL" -gt 0 ]]; then
  CONTAINER_STATUS="🔴 CRITICAL ISSUES FOUND"
elif [[ "$TOTAL_HIGH" -gt 0 ]]; then
  CONTAINER_STATUS="🟠 HIGH ISSUES FOUND"
elif [[ "$TOTAL_MEDIUM" -gt 0 ]]; then
  CONTAINER_STATUS="🟡 MEDIUM ISSUES FOUND"
elif [[ "$TOTAL_LOW" -gt 0 ]]; then
  CONTAINER_STATUS="🔵 LOW ISSUES FOUND"
else
  CONTAINER_STATUS="✅ NO ISSUES FOUND"
fi

# Update README security dashboard using Python
cat > /tmp/update_readme.py << 'PYEOF'
import re
import os

with open('README.md', 'r') as f:
    content = f.read()

current_date = os.environ.get('CURRENT_DATE')
shellcheck_status = os.environ.get('SHELLCHECK_STATUS')
shellcheck_issues = os.environ.get('SHELLCHECK_ISSUES')
container_status = os.environ.get('CONTAINER_STATUS')
total_critical = os.environ.get('TOTAL_CRITICAL')
total_high = os.environ.get('TOTAL_HIGH')
total_medium = os.environ.get('TOTAL_MEDIUM')
total_low = os.environ.get('TOTAL_LOW')

dashboard = f"""<!-- SECURITY-DASHBOARD-START -->

## 🛡️ Security Status

| Component | Status | Last Updated |
|-----------|--------|--------------|
| **Container Security** | {container_status} | {current_date} |
| **Code Quality (ShellCheck)** | {shellcheck_status} | {current_date} |

**Vulnerability Summary:** Critical: {total_critical}, High: {total_high}, Medium: {total_medium}, Low: {total_low}

**ShellCheck Issues:** {shellcheck_issues}

📋 [View Detailed Security Reports](docs/security-reports.md) for complete vulnerability analysis and recommendations.
📄 [View Code Quality Report](docs/code-quality.md) for ShellCheck findings.

<!-- SECURITY-DASHBOARD-END -->"""

pattern = r'<!-- SECURITY-DASHBOARD-START -->.*?<!-- SECURITY-DASHBOARD-END -->'
content = re.sub(pattern, dashboard, content, flags=re.DOTALL)

with open('README.md', 'w') as f:
    f.write(content)

print("README.md updated successfully")
PYEOF

CURRENT_DATE="$CURRENT_DATE" \
SHELLCHECK_STATUS="$SHELLCHECK_STATUS" \
SHELLCHECK_ISSUES="$SHELLCHECK_ISSUES" \
CONTAINER_STATUS="$CONTAINER_STATUS" \
TOTAL_CRITICAL="$TOTAL_CRITICAL" \
TOTAL_HIGH="$TOTAL_HIGH" \
TOTAL_MEDIUM="$TOTAL_MEDIUM" \
TOTAL_LOW="$TOTAL_LOW" \
python3 /tmp/update_readme.py

echo "Documentation update complete"
