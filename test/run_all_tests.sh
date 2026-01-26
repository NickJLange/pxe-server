#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASSED=0
FAILED=0

run_test() {
    local test_script="$1"
    local test_name
    test_name="$(basename "$test_script" .sh)"
    
    echo -n "Running $test_name... "
    if bash "$test_script" 2>&1; then
        echo "PASSED"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED"
        FAILED=$((FAILED + 1))
    fi
}

echo "=== PXE Server Tests ==="
echo ""

for test_script in "$SCRIPT_DIR"/test_*.sh; do
    if [[ -f "$test_script" ]]; then
        run_test "$test_script"
    fi
done

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
