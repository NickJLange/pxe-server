#!/bin/bash
# Remove nftables rules for PXE port redirection
# Safe to run multiple times
set -euo pipefail

if nft delete table inet pxe_redirect 2>/dev/null; then
    echo "nftables PXE redirect rules removed"
else
    echo "No PXE redirect rules found (already clean)"
fi
