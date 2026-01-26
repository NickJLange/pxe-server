#!/bin/bash
set -euo pipefail

# Fetch Ubuntu netboot files from official mirror
# Usage: ./prepare-netboot.sh
# Environment:
#   UBUNTU_VERSION - Ubuntu version (default: 25.10)
#   BUILD_DIR      - Output directory (default: build)

: "${UBUNTU_VERSION:=25.10}"
: "${BUILD_DIR:=build}"

TFTP_DIR="$BUILD_DIR/tftp"
HTTP_DIR="$BUILD_DIR/http"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

setup_directories() {
    log "Creating output directories..."
    mkdir -p "$TFTP_DIR"
    mkdir -p "$HTTP_DIR"
}

fetch_netboot_files() {
    local tarball_url="http://releases.ubuntu.com/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-netboot-amd64.tar.gz"
    local tarball="$BUILD_DIR/netboot.tar.gz"

    log "Fetching netboot tarball for Ubuntu $UBUNTU_VERSION..."
    log "URL: $tarball_url"

    curl -qfSL "$tarball_url" -o "$tarball"

    log "Extracting to $TFTP_DIR..."
    tar -xzf "$tarball" -C "$TFTP_DIR" --strip-components=2
    rm "$tarball"

    log "Netboot files extracted to $TFTP_DIR/"
}

create_placeholder_http() {
    # HTTP directory for any additional files (preseed, etc.)
    log "Creating HTTP placeholder..."
    mkdir -p "$HTTP_DIR"/iso/
    echo "Ubuntu $UBUNTU_VERSION Netboot" > "$HTTP_DIR/index.html"
}

show_summary() {
    log "Preparation complete!"
    log ""
    log "Files downloaded:"
    find "$BUILD_DIR" -type f | sort | while read -r f; do
        echo "  $f ($(du -h "$f" | cut -f1))"
    done
    log ""
    log "Next steps:"
    log "  1. make push"
    log "  2. sudo ./setup-nftables.sh"
    log "  3. make run"
}

main() {
    log "Ubuntu Netboot Preparation"
    log "Version: $UBUNTU_VERSION"
    log "Output: $BUILD_DIR"

    setup_directories
    fetch_netboot_files
    create_placeholder_http
    show_summary
}

main "$@"
