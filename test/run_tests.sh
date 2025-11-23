#!/bin/bash
# Test runner for kube-dump.sh with coverage analysis
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATS_CORE="$SCRIPT_DIR/bats-core/bin/bats"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  kube-dump.sh Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if bats-core is installed
if [[ ! -f "$BATS_CORE" ]]; then
  echo -e "${RED}Error: bats-core not found${NC}"
  echo "Please run the following to install test dependencies:"
  echo "  cd test && git clone https://github.com/bats-core/bats-core.git"
  exit 1
fi

# Clean up any previous test runs
echo -e "${YELLOW}Cleaning up previous test runs...${NC}"
rm -rf "$SCRIPT_DIR/tmp"/*
mkdir -p "$SCRIPT_DIR/tmp"

# Run tests with verbose output if requested
VERBOSE="${VERBOSE:-0}"
FILTER="${FILTER:-}"

if [[ -n "$FILTER" ]]; then
  echo -e "${YELLOW}Running tests matching: $FILTER${NC}"
  echo ""
fi

# Test files to run
TEST_FILES=(
  "$SCRIPT_DIR/test_utility_functions.bats"
  "$SCRIPT_DIR/test_pod_operations.bats"
  "$SCRIPT_DIR/test_node_operations.bats"
  "$SCRIPT_DIR/test_file_operations.bats"
  "$SCRIPT_DIR/test_kill_switch.bats"
  "$SCRIPT_DIR/test_file_monitor.bats"
  "$SCRIPT_DIR/test_missing_functions.bats"
  "$SCRIPT_DIR/test_integration.bats"
)

# Run each test file
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

for test_file in "${TEST_FILES[@]}"; do
  if [[ ! -f "$test_file" ]]; then
    echo -e "${YELLOW}Warning: Test file not found: $test_file${NC}"
    continue
  fi

  echo -e "${BLUE}Running: $(basename "$test_file")${NC}"

  if [[ "$VERBOSE" -eq 1 ]]; then
    BATS_ARGS="--verbose-run"
  else
    BATS_ARGS=""
  fi

  if [[ -n "$FILTER" ]]; then
    BATS_ARGS="$BATS_ARGS --filter $FILTER"
  fi

  # Run tests and capture results
  if "$BATS_CORE" $BATS_ARGS "$test_file" 2>&1; then
    echo -e "${GREEN}✓ Passed${NC}"
  else
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
      echo -e "${GREEN}✓ Passed${NC}"
    else
      echo -e "${RED}✗ Failed (exit code: $exit_code)${NC}"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
  fi
  echo ""
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  echo -e "Failed: $FAILED_TESTS"
  exit 1
fi
