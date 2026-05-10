FROM docker.io/library/alpine:3.20

RUN apk add --no-cache \
    dnsmasq \
    python3 \
    bash \
    coreutils

RUN mkdir -p /build/http/iso/

# Copy prepared netboot files from host build
COPY build/tftp /build/tftp

# Copy config templates and entrypoint
COPY dnsmasq.conf.template /etc/dnsmasq.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Unprivileged ports (add 2000 to standard ports)
# 2067 = DHCP, 2069 = TFTP, 2080 = HTTP
EXPOSE 2067/udp 2069/udp 2080/tcp

ENTRYPOINT ["/entrypoint.sh"]
