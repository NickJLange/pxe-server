#!/bin/bash
set -euo pipefail

# Test: UBUNTU_VERSION variable is respected

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check that prepare-netboot.sh uses UBUNTU_VERSION
if ! grep -q 'UBUNTU_VERSION' "$PROJECT_DIR/prepare-netboot.sh"; then
    echo "prepare-netboot.sh doesn't reference UBUNTU_VERSION"
    exit 1
fi

# Check default version is 25.10
if ! grep -q 'UBUNTU_VERSION:=25.10' "$PROJECT_DIR/prepare-netboot.sh"; then
    echo "Default UBUNTU_VERSION is not 25.10"
    exit 1
fi

# Check Makefile passes UBUNTU_VERSION
if ! grep -q 'UBUNTU_VERSION' "$PROJECT_DIR/Makefile"; then
    echo "Makefile doesn't reference UBUNTU_VERSION"
    exit 1
fi

exit 0
