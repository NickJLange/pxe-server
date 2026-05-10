#!/bin/bash
set -euo pipefail

# Configuration via environment variables
: "${DHCP_RANGE:=192.168.100.50,192.168.100.100,12h}"
: "${SERVER_IP:=192.168.100.1}"
: "${DHCP_PORT:=2067}"
: "${TFTP_PORT:=2069}"
: "${HTTP_PORT:=2080}"
: "${INTERFACE:=eth0}"

BUILD_TFTP="/build/tftp"
BUILD_HTTP="/build/http"
TFTP_ROOT="/run/tftp"
HTTP_ROOT="/run/http"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

copy_files() {
    log "Validating boot files..."
    if [ ! -d "$BUILD_TFTP" ] || [ ! -f "$BUILD_TFTP/linux" ] || [ ! -f "$BUILD_TFTP/initrd" ]; then
        log "Error: Missing netboot files in $BUILD_TFTP. Did you run 'make prepare-netboot'?"
        exit 1
    fi

    log "Setting up runtime directories..."
    mkdir -p "$(dirname "$TFTP_ROOT")"
    mkdir -p "$(dirname "$HTTP_ROOT")"

    ln -sfn "$BUILD_TFTP" "$TFTP_ROOT"
    ln -sfn "$BUILD_HTTP" "$HTTP_ROOT"
    log "Runtime directories linked to $TFTP_ROOT and $HTTP_ROOT"
}

generate_dnsmasq_config() {
    log "Generating dnsmasq configuration..."

    sed -e "s|{{SERVER_IP}}|$SERVER_IP|g" \
        -e "s|{{DHCP_RANGE}}|$DHCP_RANGE|g" \
        -e "s|{{DHCP_PORT}}|$DHCP_PORT|g" \
        -e "s|{{TFTP_PORT}}|$TFTP_PORT|g" \
        -e "s|{{INTERFACE}}|$INTERFACE|g" \
        -e "s|{{TFTP_ROOT}}|$TFTP_ROOT|g" \
        /etc/dnsmasq.conf.template > /etc/dnsmasq.conf

    log "dnsmasq configuration generated"
}

start_http_server() {
    log "Starting HTTP server on port $HTTP_PORT..."
    cd "$HTTP_ROOT"
    python3 -m http.server "$HTTP_PORT" --bind 0.0.0.0 &
    HTTP_PID=$!
    log "HTTP server started (PID: $HTTP_PID)"
}

start_dnsmasq() {
    log "Starting dnsmasq with debug logging..."
    exec dnsmasq --no-daemon --log-queries --log-dhcp --log-debug --log-facility=-
}

main() {
    log "PXE Boot Server starting..."
    log "Server IP: $SERVER_IP"
    log "DHCP Range: $DHCP_RANGE"
    log "Ports - DHCP: $DHCP_PORT, TFTP: $TFTP_PORT, HTTP: $HTTP_PORT"

    copy_files
    generate_dnsmasq_config
    start_http_server
    start_dnsmasq
}

main "$@"
