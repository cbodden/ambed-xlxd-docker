# syntax=docker/dockerfile:1-labs
## nxdnreflector
## G4KLX's NXDNReflector - removed from g4klx/NXDNClients in Feb 2023 (486106a), so this builds the
## last commit that still had it. The code is frozen upstream; nothing to track.
FROM alpine:latest AS build

ARG NXDN_GIT_REF=3bc2a1415b1a4454abd8622e59631bbe781fefc7

RUN apk add --no-cache build-base linux-headers

ADD https://github.com/g4klx/NXDNClients.git#${NXDN_GIT_REF} /src

## the 2021 code predates newer gcc no longer pulling <cstdint> in transitively
RUN cd /src/NXDNReflector \
    && make -j"$(nproc)" \
        CFLAGS="-O2 -Wall -DHAVE_LOG_H -DUDP_SOCKET_MAX=2 -std=c++0x -pthread -include cstdint" \
    && strip NXDNReflector

FROM alpine:latest

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
## runtime settings - see README
ENV NXDN_TG="" NXDN_PORT="41400" \
    NXDN_ID_URL="https://radioid.net/static/nxdn.csv" NXDN_ID_RELOAD="24" \
    NXDN_LOG_LEVEL="1" NXDN_DEBUG="0" \
    NXDN_LOG_FILE="off" NXDN_LOG_FILE_LEVEL="2" NXDN_LOG_KEEP_DAYS="7"

RUN apk add --no-cache libstdc++ libgcc curl tzdata \
    && adduser -D -H -s /sbin/nologin mmdvm \
    && mkdir -p /nxdn /usr/local/share/nxdn /var/log/nxdnreflector \
    && chown mmdvm:mmdvm /nxdn /var/log/nxdnreflector

COPY --from=build /src/NXDNReflector/NXDNReflector /usr/local/bin/
## fallback id list (2022) for when radioid can't be reached at start
COPY --from=build /src/NXDNReflector/NXDN.csv /usr/local/share/nxdn/NXDN.csv
COPY --chmod=755 run.sh /usr/local/bin/run.sh

## log files for the dashboard (NXDN_LOG_FILE=on) - share this volume with nxdndashboard
VOLUME /var/log/nxdnreflector
EXPOSE 41400/udp
USER mmdvm
WORKDIR /nxdn
ENTRYPOINT ["/usr/local/bin/run.sh"]
