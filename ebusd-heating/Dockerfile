ARG EBUSD_VERSION=v26.1

# ebusd binary from upstream official image
FROM john30/ebusd:${EBUSD_VERSION} AS ebusd-upstream
# ttyd: web terminal served on HA ingress port
FROM ghcr.io/tsl0922/ttyd:latest AS ttyd-upstream

FROM ghcr.io/home-assistant/amd64-base-debian:trixie

ARG EBUSD_VERSION
ENV LANG=C.UTF-8

LABEL \
    io.hass.name="eBUSd Heating" \
    io.hass.description="ebusd daemon for eBUS heating systems" \
    io.hass.version="${EBUSD_VERSION}" \
    io.hass.type="addon" \
    org.opencontainers.image.source="https://git.zk35.de/secalpha/ha-addons"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmosquitto1 \
        ca-certificates \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ebusd-upstream /usr/bin/ebusd   /usr/bin/ebusd
COPY --from=ebusd-upstream /usr/bin/ebusctl /usr/bin/ebusctl
COPY --from=ebusd-upstream /etc/ebusd/      /etc/ebusd/
COPY --from=ttyd-upstream  /usr/bin/ttyd    /usr/bin/ttyd

COPY run.sh /run.sh
RUN chmod a+x /run.sh

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s \
    CMD nc -z 127.0.0.1 8888 || exit 1

CMD ["/run.sh"]
