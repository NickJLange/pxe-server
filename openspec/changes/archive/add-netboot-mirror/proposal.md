# Change: Netboot Mirror Support

## Why
Using Ubuntu's official netboot mirror is simpler and lighter than ISO extraction:
- Smaller downloads (only kernel + initrd, not full ISO)
- Official Ubuntu netboot files are designed for network installation
- No ISO mounting or extraction tools required

## What Changes
- **NEW**: `make prepare-netboot` target that fetches files from Ubuntu netboot mirror
- **NEW**: `UBUNTU_VERSION` variable (default: `25.10`) for version selection
- **NEW**: Standard output directories (`build/tftp/`, `build/http/`) for deployment
- **MODIFIED**: Container expects pre-mounted volumes with netboot files
- **REMOVED**: ISO download/extraction logic (moved to `legacy` branch)

## Impact
- Affected code: Makefile, entrypoint.sh, pxe.env.example
- New files: prepare-netboot.sh (fetch script)
- Deployment: Users run `make prepare-netboot` before `make run`
