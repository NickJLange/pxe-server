#!/bin/bash
set -euo pipefail

# Build-time ISO download and extraction
# Run this on the host before starting the container

: "${ISO_URL:=}"
: "${BUILD_DIR:=build}"

ISO_DIR="$BUILD_DIR/iso"
TFTP_DIR="$BUILD_DIR/tftp"
HTTP_DIR="$BUILD_DIR/http"
ISO_PATH="$ISO_DIR/boot.iso"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_dependencies() {
    local missing=()
    for cmd in curl xorriso file tar; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "ERROR: Missing required commands: ${missing[*]}"
        log "Install with: brew install ${missing[*]}  # macOS"
        log "         or: apt install ${missing[*]}    # Debian/Ubuntu"
        exit 1
    fi
}

setup_directories() {
    log "Creating build directories..."
    mkdir -p "$ISO_DIR"
    mkdir -p "$TFTP_DIR/bios/pxelinux.cfg"
    mkdir -p "$TFTP_DIR/grub"
    mkdir -p "$TFTP_DIR/boot/casper"
    mkdir -p "$HTTP_DIR"
}

download_iso() {
    echo $ISO_PATH
    echo $ISO_URL
    if [[ -f "$ISO_PATH" ]]; then
        log "ISO already exists at $ISO_PATH"
        return 0
    fi

    if [[ -z "$ISO_URL" ]]; then
        log "ERROR: ISO_URL not set and no ISO found at $ISO_PATH"
        log "Set ISO_URL in your env file or environment"
        exit 1
    fi

    # If ISO_URL points to a local file, copy it instead of downloading
    if [[ -f "$ISO_URL" ]]; then
        log "Using existing local ISO at $ISO_URL"
        cp "$ISO_URL" "$ISO_PATH"
        log "ISO copy complete"
        return 0
    fi

    # If ISO_URL looks like an HTTP(S) URL, download it
    if [[ "$ISO_URL" =~ ^https?:// ]]; then
        log "Downloading ISO from $ISO_URL..."
        curl -fL -o "$ISO_PATH" "$ISO_URL"
        log "ISO download complete"
        return 0
    fi

    # Otherwise, it's neither a file nor a valid HTTP(S) URL
    log "ERROR: ISO_URL '$ISO_URL' is neither an existing file nor an http/https URL"
    exit 1
}

extract_boot_files() {
    log "Extracting boot files from ISO..."

    # Clean existing directories to avoid permission conflicts from previous runs
    for dir in "$HTTP_DIR" "$TFTP_DIR"; do
        if [[ -d "$dir" ]]; then
            log "Cleaning existing $dir..."
            chmod -R u+w "$dir" 2>/dev/null || true
            rm -rf "$dir"
        fi
    done
    mkdir -p "$HTTP_DIR"
    mkdir -p "$TFTP_DIR/bios/pxelinux.cfg"
    mkdir -p "$TFTP_DIR/grub"
    mkdir -p "$TFTP_DIR/boot/casper"

    local file_type
    file_type=$(file -b "$ISO_PATH" 2>/dev/null || echo "unknown")

    if [[ "$file_type" == *"ISO 9660"* ]]; then
        log "Detected ISO 9660 image"
        xorriso -osirrox on -indev "$ISO_PATH" -extract / "$HTTP_DIR" 2>/dev/null
    elif [[ "$file_type" == *"tar archive"* ]] || [[ "$file_type" == *"POSIX tar"* ]]; then
        log "Detected tar archive"
        tar -xf "$ISO_PATH" -C "$HTTP_DIR"
    elif [[ "$file_type" == *"gzip"* ]]; then
        log "Detected gzipped archive"
        tar -xzf "$ISO_PATH" -C "$HTTP_DIR"
    else
        log "Unknown file type: $file_type, trying xorriso..."
        xorriso -osirrox on -indev "$ISO_PATH" -extract / "$HTTP_DIR" 2>/dev/null || {
            log "Trying tar..."
            tar -xf "$ISO_PATH" -C "$HTTP_DIR" 2>/dev/null || {
                log "ERROR: Cannot extract $ISO_PATH"
                exit 1
            }
        }
    fi

    # Copy kernel and initrd to TFTP for netboot
    if [[ -d "$HTTP_DIR/casper" ]]; then
        log "Found Ubuntu-style casper layout"
        cp "$HTTP_DIR/casper/vmlinuz" "$TFTP_DIR/boot/casper/"
        cp "$HTTP_DIR/casper/initrd" "$TFTP_DIR/boot/casper/" 2>/dev/null || \
        cp "$HTTP_DIR/casper/initrd.lz" "$TFTP_DIR/boot/casper/" 2>/dev/null || true
    elif [[ -d "$HTTP_DIR/isolinux" ]]; then
        log "Found isolinux layout"
        mkdir -p "$TFTP_DIR/boot/isolinux"
        cp "$HTTP_DIR/isolinux/vmlinuz" "$TFTP_DIR/boot/isolinux/" 2>/dev/null || true
        cp "$HTTP_DIR/isolinux/initrd"* "$TFTP_DIR/boot/isolinux/" 2>/dev/null || true
    else
        log "WARNING: No recognized boot layout found (casper/ or isolinux/)"
    fi

    log "Boot files extracted to $TFTP_DIR and $HTTP_DIR"
}

main() {
    log "=== PXE Build-time Preparation ==="
    
    check_dependencies
    setup_directories
    download_iso
    extract_boot_files
    
    log "=== Preparation complete ==="
    log "TFTP files: $TFTP_DIR"
    log "HTTP files: $HTTP_DIR"
    log ""
    log "Next: make build"
}

main "$@"
