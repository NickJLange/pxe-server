FROM docker.io/library/alpine:3.20

RUN apk add --no-cache \
    dnsmasq \
    python3 \
    bash \
    coreutils \
    tcpdump

RUN mkdir -p /build/http/iso/

# Copy prepared netboot files from host build
COPY build/tftp /build/tftp

# Copy config templates and entrypoint
COPY dnsmasq.conf.template /etc/dnsmasq.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Standard PXE ports
#
# 67 = DHCP, 69 = TFTP, 80 = HTTP
EXPOSE 67/udp 69/udp 80/tcp

ENTRYPOINT ["/entrypoint.sh"]
