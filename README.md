# mkz1 - Minimal PXE Boot Container

A Podman container that serves DHCP, TFTP, and HTTP for PXE booting Linux ISOs.

> **Note**: Requires `NET_ADMIN` and `NET_RAW` capabilities for DHCP functionality.

## Quick Start

```bash
# 1. Configure environment
make env-file
# Edit pxe.env with your ISO_URL and SERVER_IP

# 2. Download ISO and extract boot files (on host)
ln -s ubuntu-25.10-desktop-amd64.iso build/iso/boot.iso
make prepare-iso

# 3. Build and run container
make build
sudo ./setup-nftables.sh
make run

# Cleanup when done
make stop
sudo ./teardown-nftables.sh
```

## Remote Deployment

The `build/` directory can be rsynced to a destination server:

```bash
# On build machine
make prepare-iso

# Deploy to remote server
rsync -av build/ remote:/pxe/

# On remote server, run container with mounted dirs
podman run -d --name pxe \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -e SERVER_IP=192.168.100.1 \
  -v /pxe/tftp:/tftp \
  -v /pxe/http:/var/www/html:ro \
  ...
```

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `ISO_URL` | (required) | URL to download Linux ISO or path to an existing local ISO (used by `make prepare-iso`) |
| `SERVER_IP` | `192.168.100.1` | IP address of the PXE server |
| `DHCP_RANGE` | `192.168.100.50,192.168.100.100,12h` | DHCP range and lease time |
| `INTERFACE` | `eth0` | Network interface to bind |
| `DHCP_PORT` | `2067` | DHCP server port (unprivileged) |
| `TFTP_PORT` | `2069` | TFTP server port (unprivileged) |
| `HTTP_PORT` | `2080` | HTTP server port (unprivileged) |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Host                                                    │
│  nftables: 67→2067, 69→2069, 80→2080                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Container (with NET_ADMIN, NET_RAW caps)          │ │
│  │                                                   │ │
│  │  dnsmasq (:2067 DHCP, :2069 TFTP)                │ │
│  │  python3 http.server (:2080)                     │ │
│  │                                                   │ │
│  │  /tftp/bios/     - BIOS boot files (pxelinux)   │ │
│  │  /tftp/grub/     - UEFI boot files (grub)       │ │
│  │  /var/www/html/  - ISO contents                  │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Port Mapping

The container runs on high ports (2000+). Use nftables on the host to redirect standard PXE ports:

| Standard Port | Container Port | Service |
|--------------|----------------|---------|
| 67/udp | 2067/udp | DHCP |
| 69/udp | 2069/udp | TFTP |
| 80/tcp | 2080/tcp | HTTP |

## Testing

```bash
# Run unit tests
./test/run_all_tests.sh

# Run with integration test (requires QEMU)
RUN_INTEGRATION=1 ./test/run_all_tests.sh
```

## Boot Support

| Build Arch | BIOS (pxelinux) | UEFI (GRUB) |
|------------|-----------------|-------------|
| x86_64 | ✓ | ✓ |
| ARM64 | ✗ | ✓ |

The server auto-detects client architecture via DHCP option 93 (client-arch).

## Supported Image Formats

The container can extract boot files from:
- ISO 9660 images (`.iso`)
- tar archives (`.tar`)
- gzipped tar archives (`.tar.gz`)

## Tested ISOs

- Ubuntu 24.04 Desktop
- Ubuntu 22.04 Desktop/Server

Other ISOs with `casper/` or `isolinux/` layouts should work.
