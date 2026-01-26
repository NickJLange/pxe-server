# Project Context

## Purpose
mkz1 is a minimal PXE boot container that serves DHCP, TFTP, and HTTP for network booting Linux ISOs. It runs as a Podman container with unprivileged ports (2067, 2069, 2080) and uses host nftables to redirect standard PXE ports (67, 69, 80).

## Tech Stack
- **Container**: Alpine Linux 3.20, Podman/OCI
- **Services**: dnsmasq (DHCP/TFTP), Python http.server (HTTP)
- **Boot loaders**: syslinux/pxelinux (BIOS), GRUB EFI (UEFI)
- **Build**: Makefile, Containerfile
- **Scripts**: Bash (entrypoint, nftables setup/teardown)
- **Netboot source**: Ubuntu official netboot mirror

## Project Conventions

### Code Style
- Shell scripts use `set -euo pipefail`
- Environment variables for configuration with defaults via `${VAR:=default}`
- Template files use `{{PLACEHOLDER}}` syntax processed by `sed`
- Kebab-case for file names, UPPER_SNAKE for env vars

### Architecture Patterns
- Single-container design with dnsmasq + python http.server
- Unprivileged ports inside container, nftables redirect on host
- Config templates rendered at container startup via entrypoint.sh
- Build-time file preparation (netboot mirror fetch)
- Architecture-aware builds (x86_64: BIOS+UEFI, ARM64: UEFI only)

### Testing Strategy
- Shell-based unit tests in `test/` directory
- Run with `./test/run_all_tests.sh`
- Integration tests require QEMU (`RUN_INTEGRATION=1`)
- Tests cover: DHCP, TFTP, HTTP, container services, full simulation

### Git Workflow
- Main branch for stable releases
- `legacy` branch preserves ISO-based approach
- Push to ghcr.io via `make push`
- GitHub token required for registry auth

## Domain Context
- **PXE boot**: Network boot protocol using DHCP for IP + boot server info, TFTP for boot loader, HTTP for OS files
- **Client arch detection**: DHCP option 93 distinguishes BIOS (0) from UEFI (7/9)
- **Ubuntu netboot**: Official minimal network install files (vmlinuz, initrd) from releases.ubuntu.com
- **Netboot params**: kernel command line for network installation

## Important Constraints
- Requires `NET_ADMIN` and `NET_RAW` capabilities for DHCP
- Host nftables setup requires root access
- BIOS boot (pxelinux) only available on x86_64 builds
- Standard ports (67, 69, 80) cannot be bound directly without root

## External Dependencies
- Ubuntu netboot mirror (releases.ubuntu.com)
- Host nftables for port redirection
- QEMU for integration testing
