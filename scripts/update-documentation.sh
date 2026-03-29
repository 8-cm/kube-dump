#!/bin/bash
# Updates README ShellCheck status badge

set -e

SHELLCHECK_STATUS="${1:-UNKNOWN}"
SHELLCHECK_ISSUES="${2:-0}"
CURRENT_DATE=$(date +%Y-%m-%d)

SHELLCHECK_STATUS="$SHELLCHECK_STATUS" \
SHELLCHECK_ISSUES="$SHELLCHECK_ISSUES" \
CURRENT_DATE="$CURRENT_DATE" \
python3 - << 'PYEOF'
import re, os

status = os.environ['SHELLCHECK_STATUS']
issues = os.environ['SHELLCHECK_ISSUES']
date = os.environ['CURRENT_DATE']

dashboard = f"""<!-- SECURITY-DASHBOARD-START -->

## Code Quality

**ShellCheck:** {status} | **Issues:** {issues} | **Last updated:** {date}

📄 [View Code Quality Report](docs/code-quality.md)

<!-- SECURITY-DASHBOARD-END -->"""

with open('README.md', 'r') as f:
    content = f.read()

content = re.sub(r'<!-- SECURITY-DASHBOARD-START -->.*?<!-- SECURITY-DASHBOARD-END -->', dashboard, content, flags=re.DOTALL)

with open('README.md', 'w') as f:
    f.write(content)
PYEOF
