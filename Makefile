# mkz1 PXE Boot Container
# Usage: make build push run

REGISTRY ?= ghcr.io
REPO ?= $(shell git remote get-url origin 2>/dev/null | sed -E 's|.*[:/]([^/]+/[^/]+)(\.git)?$$|\1|' | tr '[:upper:]' '[:lower:]')
IMAGE ?= $(REGISTRY)/$(REPO)
CONTAINER_NAME ?= pxe
ENV_FILE ?= pxe.env
BUILD_DIR ?= build

# Extract ISO name for tag (e.g., ubuntu-25.10-desktop-amd64 from .iso filename)
ISO_NAME ?= $(shell ls -1 *.iso 2>/dev/null | head -1 | sed 's/\.iso$$//')
TAG ?= $(if $(ISO_NAME),$(ISO_NAME),latest)

.PHONY: build push pull run stop clean login nft-setup nft-teardown logs env-file prepare-iso help

help:
	@echo "Targets:"
	@echo "  build        Prepare ISO and build self-contained container image"
	@echo "  push         Push to $(REGISTRY)"
	@echo "  pull         Pull from $(REGISTRY)"
	@echo "  run          Run container"
	@echo "  stop         Stop and remove container"
	@echo "  clean        Remove container, build dir, and local image"
	@echo "  login        Login to ghcr.io (requires GITHUB_TOKEN)"
	@echo "  nft-setup    Setup nftables port redirects (requires sudo)"
	@echo "  nft-teardown Remove nftables port redirects (requires sudo)"
	@echo "  logs         Follow container logs"
	@echo "  env-file     Create pxe.env from example"
	@echo ""
	@echo "Workflow:"
	@echo "  1. make env-file && edit pxe.env"
	@echo "  2. Place ISO in current directory or set ISO_URL"
	@echo "  3. make build run"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE=$(IMAGE)"
	@echo "  TAG=$(TAG)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"
	@echo "  ENV_FILE=$(ENV_FILE)"

prepare-iso: $(ENV_FILE)
	@if [ ! -f $(ENV_FILE) ]; then echo "Run: make env-file"; exit 1; fi
	BUILD_DIR=$(BUILD_DIR) bash -c 'source $(ENV_FILE) && ./prepare-iso.sh'

build: prepare-iso
	podman build -t $(IMAGE):$(TAG) .

push: build
	podman push $(IMAGE):$(TAG)

pull:
	podman pull $(IMAGE):$(TAG)

login:
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "Error: GITHUB_TOKEN not set"; \
		echo "Create one at: https://github.com/settings/tokens"; \
		echo "Required scope: write:packages"; \
		exit 1; \
	fi
	@echo "$$GITHUB_TOKEN" | podman login $(REGISTRY) -u $(shell git config user.name || echo "user") --password-stdin

run: $(ENV_FILE)
	podman run -d --name $(CONTAINER_NAME) \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		--env-file $(ENV_FILE) \
		-p 2067:67/udp \
		-p 2069:69/udp \
		-p 2080:80/tcp \
		-v ./$(BUILD_DIR)/http:/var/www/html:ro \
		$(IMAGE):$(TAG)

stop:
	-podman stop $(CONTAINER_NAME)
	-podman rm $(CONTAINER_NAME)

clean: stop
	-rm -rf $(BUILD_DIR)
	-podman rmi $(IMAGE):$(TAG)

nft-setup:
	sudo ./setup-nftables.sh

nft-teardown:
	sudo ./teardown-nftables.sh

logs:
	podman logs -f $(CONTAINER_NAME)

env-file:
	@if [ ! -f $(ENV_FILE) ]; then \
		cp pxe.env.example $(ENV_FILE); \
		echo "Created $(ENV_FILE) - edit before running"; \
	else \
		echo "$(ENV_FILE) already exists"; \
	fi

$(ENV_FILE):
	@echo "Error: $(ENV_FILE) not found"
	@echo "Run: make env-file"
	@exit 1
