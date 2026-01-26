## 1. Implementation

- [x] 1.1 Create `prepare-netboot.sh` script to fetch files from Ubuntu netboot mirror
- [x] 1.2 Add `make prepare-netboot` target that runs the script
- [x] 1.3 Define standard output directories: `build/tftp/`, `build/http/`
- [x] 1.4 Update Makefile `run` target to mount `build/` directories
- [x] 1.5 Simplify `entrypoint.sh` (expect files present, no downloads)
- [x] 1.6 Update `pxe.env.example` with `UBUNTU_VERSION` variable
- [x] 1.7 Update README.md with netboot workflow
- [x] 1.8 Update/create tests for netboot directory structure
