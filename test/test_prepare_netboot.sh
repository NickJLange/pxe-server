#!/bin/bash
set -euo pipefail

# Test: prepare-netboot.sh creates correct directory structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_BUILD_DIR="$PROJECT_DIR/test_build_$$"

cleanup() {
    rm -rf "$TEST_BUILD_DIR"
}
trap cleanup EXIT

# Run prepare-netboot with test build dir
cd "$PROJECT_DIR"
BUILD_DIR="$TEST_BUILD_DIR" ./prepare-netboot.sh > /dev/null 2>&1

# Verify BIOS boot files
[[ -f "$TEST_BUILD_DIR/tftp/pxelinux.0" ]] || { echo "Missing pxelinux.0"; exit 1; }
[[ -f "$TEST_BUILD_DIR/tftp/ldlinux.c32" ]] || { echo "Missing ldlinux.c32"; exit 1; }
[[ -f "$TEST_BUILD_DIR/tftp/pxelinux.cfg/default" ]] || { echo "Missing pxelinux.cfg/default"; exit 1; }

# Verify UEFI boot files
[[ -f "$TEST_BUILD_DIR/tftp/bootx64.efi" ]] || { echo "Missing bootx64.efi"; exit 1; }
[[ -f "$TEST_BUILD_DIR/tftp/grubx64.efi" ]] || { echo "Missing grubx64.efi"; exit 1; }
[[ -f "$TEST_BUILD_DIR/tftp/grub/grub.cfg" ]] || { echo "Missing grub/grub.cfg"; exit 1; }

# Verify kernel and initrd
[[ -f "$TEST_BUILD_DIR/tftp/linux" ]] || { echo "Missing linux kernel"; exit 1; }
[[ -f "$TEST_BUILD_DIR/tftp/initrd" ]] || { echo "Missing initrd"; exit 1; }

# Verify HTTP directory
[[ -d "$TEST_BUILD_DIR/http" ]] || { echo "Missing http directory"; exit 1; }

# Verify file sizes (should be non-empty)
[[ -s "$TEST_BUILD_DIR/tftp/linux" ]] || { echo "linux kernel is empty"; exit 1; }
[[ -s "$TEST_BUILD_DIR/tftp/initrd" ]] || { echo "initrd is empty"; exit 1; }

exit 0
