#!/bin/bash
# Analyze test coverage for kube-dump.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBE_DUMP_SCRIPT="$SCRIPT_DIR/../kube-dump.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Coverage Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Extract all function definitions from kube-dump.sh
echo -e "${YELLOW}Extracting functions from kube-dump.sh...${NC}"
functions=$(grep -E '^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' "$KUBE_DUMP_SCRIPT" | \
           sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\).*/\1/' | \
           sort -u)

total_functions=$(echo "$functions" | wc -l | tr -d ' ')
echo -e "Found ${BLUE}${total_functions}${NC} functions"
echo ""

# Check which functions have tests
tested_functions=0
untested_functions=0
untested_list=()

echo -e "${YELLOW}Checking test coverage...${NC}"
echo ""

for func in $functions; do
  # Search for function name in test files
  if grep -r -l "$func" "$SCRIPT_DIR"/*.bats &>/dev/null; then
    tested_functions=$((tested_functions + 1))
    echo -e "${GREEN}✓${NC} $func"
  else
    untested_functions=$((untested_functions + 1))
    untested_list+=("$func")
    echo -e "${RED}✗${NC} $func"
  fi
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Coverage Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

coverage_percent=$(awk "BEGIN {printf \"%.1f\", ($tested_functions / $total_functions) * 100}")

echo -e "Total functions:    ${BLUE}${total_functions}${NC}"
echo -e "Tested functions:   ${GREEN}${tested_functions}${NC}"
echo -e "Untested functions: ${RED}${untested_functions}${NC}"
echo -e "Coverage:           ${BLUE}${coverage_percent}%${NC}"
echo ""

if [[ ${#untested_list[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Untested functions:${NC}"
  for func in "${untested_list[@]}"; do
    echo -e "  - $func"
  done
  echo ""
fi

# Check coverage goal
if (( $(echo "$coverage_percent >= 100.0" | bc -l) )); then
  echo -e "${GREEN}🎉 100% test coverage achieved!${NC}"
  exit 0
elif (( $(echo "$coverage_percent >= 90.0" | bc -l) )); then
  echo -e "${GREEN}✓ Good coverage (>90%)${NC}"
  exit 0
elif (( $(echo "$coverage_percent >= 80.0" | bc -l) )); then
  echo -e "${YELLOW}⚠ Acceptable coverage (>80%)${NC}"
  exit 0
else
  echo -e "${RED}✗ Low coverage (<80%)${NC}"
  exit 1
fi
