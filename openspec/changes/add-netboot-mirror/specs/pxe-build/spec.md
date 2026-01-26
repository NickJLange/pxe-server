## ADDED Requirements

### Requirement: Netboot Mirror Fetching
The build system SHALL fetch all netboot files from Ubuntu's official releases mirror.

#### Scenario: Fetch netboot files
- **WHEN** user runs `make prepare-netboot`
- **THEN** pxelinux.0, ldlinux.c32, linux (kernel), initrd are downloaded to `build/tftp/`
- **AND** bootx64.efi, grubx64.efi are downloaded to `build/tftp/`
- **AND** pxelinux.cfg/default is downloaded to `build/tftp/pxelinux.cfg/`
- **AND** grub/grub.cfg is downloaded to `build/tftp/grub/`

#### Scenario: Configurable version
- **WHEN** `UBUNTU_VERSION` environment variable is set
- **THEN** files are fetched from `http://releases.ubuntu.com/${UBUNTU_VERSION}/netboot/amd64/`

#### Scenario: Default version
- **WHEN** `UBUNTU_VERSION` is not set
- **THEN** version defaults to `25.10`

### Requirement: Standard Output Directories
The build system SHALL output fetched files to predictable directories suitable for rsync.

#### Scenario: Directory structure
- **WHEN** netboot fetch completes
- **THEN** `build/tftp/` contains all boot files (kernel, initrd, boot loaders, configs)
- **AND** `build/http/` is created for additional files (preseed, etc.)
- **AND** directories are owned by current user (not root)

### Requirement: Runtime Volume Mounts
The container launcher SHALL mount pre-prepared directories instead of downloading at runtime.

#### Scenario: Container startup with prepared files
- **WHEN** container starts via `make run`
- **THEN** `build/tftp/` is mounted to container
- **AND** `build/http/` is mounted to container
- **AND** container starts without network fetch operations
