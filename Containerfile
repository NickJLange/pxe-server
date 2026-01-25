FROM docker.io/library/alpine:3.20

ARG TARGETARCH

RUN apk add --no-cache \
    dnsmasq \
    python3 \
    bash \
    coreutils \
    && mkdir -p /build/tftp/bios/pxelinux.cfg \
    && mkdir -p /build/tftp/grub \
    && mkdir -p /build/tftp/boot/casper \
    && mkdir -p /build/http

# Install architecture-specific packages
# syslinux (BIOS PXE) only available on x86_64
# grub-efi available on both x86_64 and aarch64
RUN if [ "$TARGETARCH" = "amd64" ] || [ "$(uname -m)" = "x86_64" ]; then \
        apk add --no-cache syslinux grub-efi \
        && cp /usr/share/syslinux/pxelinux.0 /build/tftp/bios/ \
        && cp /usr/share/syslinux/ldlinux.c32 /build/tftp/bios/ \
        && cp /usr/share/syslinux/libutil.c32 /build/tftp/bios/ \
        && cp /usr/share/syslinux/menu.c32 /build/tftp/bios/ \
        && cp /usr/share/syslinux/libcom32.c32 /build/tftp/bios/ \
        && (cp /usr/share/grub/x86_64-efi/grub.efi /build/tftp/grub/grubx64.efi 2>/dev/null || \
            cp /usr/lib/grub/x86_64-efi/grub.efi /build/tftp/grub/grubx64.efi 2>/dev/null || true); \
    else \
        apk add --no-cache grub-efi \
        && echo "ARM64 build: BIOS PXE boot not supported, UEFI only"; \
    fi

# Copy GRUB EFI for ARM64 if available
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        cp /usr/lib/grub/arm64-efi/grub.efi /build/tftp/grub/grubaa64.efi 2>/dev/null || \
        echo "ARM64 GRUB EFI copied"; \
    fi

# Copy prepared boot files from host build (http content rsynced separately)
COPY build/tftp /build/tftp

# Copy config templates and entrypoint
COPY dnsmasq.conf.template /etc/dnsmasq.conf.template
COPY pxelinux.cfg/default /build/tftp/bios/pxelinux.cfg/default.template
COPY grub.cfg.template /build/tftp/grub/grub.cfg.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Unprivileged ports (add 2000 to standard ports)
# 2067 = DHCP, 2069 = TFTP, 2080 = HTTP
EXPOSE 2067/udp 2069/udp 2080/tcp

ENTRYPOINT ["/entrypoint.sh"]
