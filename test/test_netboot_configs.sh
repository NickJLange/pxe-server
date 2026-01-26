#!/bin/bash
set -euo pipefail

# Test: Downloaded configs contain expected content

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Skip if build dir doesn't exist (prepare-netboot not run)
if [[ ! -d "$BUILD_DIR/tftp" ]]; then
    echo "Skipping: run 'make prepare-netboot' first"
    exit 0
fi

# Check pxelinux.cfg/default references kernel and initrd
if ! grep -q "KERNEL linux" "$BUILD_DIR/tftp/pxelinux.cfg/default"; then
    echo "pxelinux.cfg/default missing KERNEL directive"
    exit 1
fi

if ! grep -q "INITRD initrd" "$BUILD_DIR/tftp/pxelinux.cfg/default"; then
    echo "pxelinux.cfg/default missing INITRD directive"
    exit 1
fi

# Check grub.cfg references kernel and initrd
if ! grep -q "linux.*linux" "$BUILD_DIR/tftp/grub/grub.cfg"; then
    echo "grub.cfg missing linux directive"
    exit 1
fi

if ! grep -q "initrd.*initrd" "$BUILD_DIR/tftp/grub/grub.cfg"; then
    echo "grub.cfg missing initrd directive"
    exit 1
fi

exit 0
