#!/bin/bash
# Add nftables rules for PXE port redirection
# Safe to run multiple times - removes existing table first
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

# Remove existing table if present (idempotent)
nft delete table inet pxe_redirect 2>/dev/null || true

# Add the rules
nft -f "$SCRIPT_DIR/pxe-redirect.nft"

echo "nftables PXE redirect rules installed"
