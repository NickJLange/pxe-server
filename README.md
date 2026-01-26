# mkz1 - Minimal PXE Boot Container

A Podman container that serves DHCP, TFTP, and HTTP for PXE booting Ubuntu via netboot.

> **Note**: Requires `NET_ADMIN` and `NET_RAW` capabilities for DHCP functionality.

## Quick Start

```bash
# 1. Configure environment
make env-file
# Edit pxe.env with your SERVER_IP and network settings

# 2. Fetch Ubuntu netboot files
make prepare-netboot

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
make prepare-netboot

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
| `UBUNTU_VERSION` | `25.10` | Ubuntu version for netboot files |
| `SERVER_IP` | `192.168.100.1` | IP address of the PXE server |
| `DHCP_RANGE` | `192.168.100.50,192.168.100.100,12h` | DHCP range and lease time |
| `INTERFACE` | `eth0` | Network interface to bind |
| `DHCP_PORT` | `67` | DHCP server port |
| `TFTP_PORT` | `69` | TFTP server port |
| `HTTP_PORT` | `80` | HTTP server port |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Host                                                    │
│  nftables: 67→2067, 69→2069, 80→2080                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Container (with NET_ADMIN, NET_RAW caps)          │ │
│  │                                                   │ │
│  │  dnsmasq (:67 DHCP, :69 TFTP)                    │ │
│  │  python3 http.server (:80)                       │ │
│  │                                                   │ │
│  │  /tftp/bios/     - BIOS boot files (pxelinux)   │ │
│  │  /tftp/grub/     - UEFI boot files (grub)       │ │
│  │  /tftp/linux     - Ubuntu kernel                │ │
│  │  /tftp/initrd    - Ubuntu initrd                │ │
│  │  /var/www/html/  - HTTP files                    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Port Mapping

The container uses standard ports internally. Use nftables on the host to redirect from high ports:

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

## Netboot Source

Files are fetched from Ubuntu's official archive mirror:
- `http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_VERSION}/main/installer-amd64/current/legacy-images/netboot/`

## Tested Versions

- Ubuntu 25.10 (Questing Quokka)
- Ubuntu 24.04 LTS (Noble Numbat)
