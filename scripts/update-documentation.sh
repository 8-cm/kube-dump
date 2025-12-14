#!/bin/bash
# Script to update README and generate code quality reports from CI pipeline

set -e

SHELLCHECK_STATUS="${1:-UNKNOWN}"
SHELLCHECK_ISSUES="${2:-0}"
TOTAL_CRITICAL="${3:-0}"
TOTAL_HIGH="${4:-0}"
TOTAL_MEDIUM="${5:-0}"
TOTAL_LOW="${6:-0}"

CURRENT_DATE=$(date +%Y-%m-%d)

echo "Updating README.md security dashboard..."

# Generate code quality report
{
  echo "# Code Quality Report - ShellCheck Analysis"
  echo ""
  echo "**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "**Script:** kube-dump.sh"
  echo ""

  if [ -s results/shellcheck-raw.txt ]; then
    ISSUE_COUNT=$(wc -l < results/shellcheck-raw.txt)
    echo "## Issues Found: $ISSUE_COUNT"
    echo ""
    echo '```'
    cat results/shellcheck-raw.txt
    echo '```'
    echo ""
    echo "### How to Fix ShellCheck Issues"
    echo ""
    echo "1. Review each issue in the report above"
    echo "2. Install ShellCheck locally: \`sudo apt-get install shellcheck\`"
    echo "3. Fix issues in kube-dump.sh"
    echo "4. Run: \`shellcheck kube-dump.sh\` to verify"
  else
    echo "## ✅ No Issues Found"
    echo ""
    echo "All ShellCheck validations passed successfully!"
  fi
} > docs/code-quality.md

echo "Code quality report generated at docs/code-quality.md"

# Update README security dashboard
cat > /tmp/update_readme.py << 'PYEOF'
import re
import os

with open('README.md', 'r') as f:
    content = f.read()

current_date = os.environ.get('CURRENT_DATE')
shellcheck_status = os.environ.get('SHELLCHECK_STATUS')
shellcheck_issues = os.environ.get('SHELLCHECK_ISSUES')
total_critical = os.environ.get('TOTAL_CRITICAL')
total_high = os.environ.get('TOTAL_HIGH')
total_medium = os.environ.get('TOTAL_MEDIUM')
total_low = os.environ.get('TOTAL_LOW')

dashboard = f"""<!-- SECURITY-DASHBOARD-START -->

## 🛡️ Security Status

| Component | Status | Last Updated |
|-----------|--------|--------------|
| **Container Security** | 🔴 CRITICAL ISSUES FOUND | {current_date} |
| **Code Quality** | {shellcheck_status} | Automated |

**Vulnerability Summary:** Critical: {total_critical}, High: {total_high}, Medium: {total_medium}, Low: {total_low}

📋 [View Detailed Security Reports](docs/security-reports.md) for complete vulnerability analysis and recommendations.
📄 [View Code Quality Report](docs/code-quality.md) for ShellCheck findings ({shellcheck_issues} issues).

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
TOTAL_CRITICAL="$TOTAL_CRITICAL" \
TOTAL_HIGH="$TOTAL_HIGH" \
TOTAL_MEDIUM="$TOTAL_MEDIUM" \
TOTAL_LOW="$TOTAL_LOW" \
python3 /tmp/update_readme.py

echo "Documentation update complete"
