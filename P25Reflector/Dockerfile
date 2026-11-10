# syntax=docker/dockerfile:1-labs
## p25reflector
## G4KLX's P25Reflector - removed from g4klx/P25Clients in Feb 2023 (aa9ded6), so this builds the
## last commit that still had it. The code is frozen upstream; nothing to track.
FROM alpine:latest AS build

ARG P25_GIT_REF=a842b8d94ffa030a6269bf2e66c6a205e8281221

RUN apk add --no-cache build-base linux-headers

ADD https://github.com/g4klx/P25Clients.git#${P25_GIT_REF} /src

## the 2021 code predates newer gcc no longer pulling <cstdint> in transitively
RUN cd /src/P25Reflector \
    && make -j"$(nproc)" \
        CFLAGS="-O2 -Wall -DHAVE_LOG_H -DUDP_SOCKET_MAX=2 -std=c++0x -pthread -include cstdint" \
    && strip P25Reflector

FROM alpine:latest

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
## runtime settings - see README
ENV P25_PORT="41000" \
    P25_ID_URL="https://www.pistar.uk/downloads/DMRIds.dat" P25_ID_RELOAD="24" \
    P25_LOG_LEVEL="1" P25_DEBUG="0"

RUN apk add --no-cache libstdc++ libgcc curl tzdata \
    && adduser -D -H -s /sbin/nologin mmdvm \
    && mkdir -p /p25 /usr/local/share/p25 \
    && chown mmdvm:mmdvm /p25

COPY --from=build /src/P25Reflector/P25Reflector /usr/local/bin/
## fallback id list for when the download fails at start
COPY --from=build /src/P25Reflector/DMRIds.dat /usr/local/share/p25/DMRIds.dat
COPY --chmod=755 run.sh /usr/local/bin/run.sh

EXPOSE 41000/udp
USER mmdvm
WORKDIR /p25
ENTRYPOINT ["/usr/local/bin/run.sh"]
