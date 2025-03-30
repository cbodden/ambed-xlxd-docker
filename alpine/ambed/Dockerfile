## ambed
# syntax=docker/dockerfile:1-labs
FROM frolvlad/alpine-glibc
##FROM --platform=$BUILDPLATFORM alpine:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ARG TARGETARCH
ARG AMBED_DIR=/ambed AMBED_INST_DIR=/src/ambed USE_AGC=0
ARG FTDI_INST_VER=1.4.33 FTDI_INST_DIR=/src/ftdi
ARG FTDI_INST_ADDRESS=https://ftdichip.com/wp-content/uploads/2025/03
ARG S6_OVERLAY_VERSION=3.2.0.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

RUN apk update && \
    apk add --no-cache \
        build-base linux-headers \
        coreutils gcc g++ \
        curl git bash xz zstd
    ##apk add --virtual build-dependencies && \
    ##apk add --update --no-cache \
        ##alpine-sdk build-base linux-headers \
        ## curl git wget bash tar xz zstd
        ##libc-dev gcompat libstdc++ gcc g++ make \
        ##libc-dev libstdc++ gcc g++ make \
        ##libpthread-stubs \
        ##musl musl-utils musl-dev musl-dbg musl-fts musl-locales \
        ##libftdi1 libftdi1-dev libftdi1-static \

RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk && \
    apk add glibc-2.35-r1.apk

RUN mkdir -p \
    ${AMBED_DIR} \
    ${AMBED_INST_DIR} \
    ${FTDI_INST_DIR} \
    ${S6_OVERLAY_INST} \
    /usr/local/include/

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        cd "${S6_OVERLAY_INST}" && \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" && \
        tar -xJf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" && \
        mv * / ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" && \
        exit 1; \
    fi

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        cd "${FTDI_INST_DIR}" && \
        wget "${FTDI_INST_ADDRESS}/libftd2xx-linux-arm-v8-${FTDI_INST_VER}.tgz" && \
        tar xfz "${FTDI_INST_DIR}/libftd2xx-linux-arm-v8-${FTDI_INST_VER}.tgz" && \
        cp ${FTDI_INST_DIR}/linux-arm-v8/libftd2xx.* /usr/local/lib && \
        ln -sf /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib/libftd2xx.so && \
        cp linux-arm-v8/*.h /usr/local/include/ && \
        ldconfig /usr/local/lib ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH"; \
        exit 1; \
    fi

RUN ls -al /etc && \
    ldconfig && \
    exit 1 ; 

RUN ln /usr/glibc-compat/lib/librt.so.1 /usr/local/lib/librt.so && \
    ln /usr/glibc-compat/lib/libc.so.6 /usr/local/lib/libc.so && \
    ln /usr/glibc-compat/lib/libpthread.so.0 /usr/local/lib/libpthread.so && \
    ldconfig /usr/local/lib/ ;
    

##0.863 /usr/lib/librt.a
##0.979 /usr/glibc-compat/lib/librt.so.1

##0.874 /usr/lib/libpthread.a
##0.961 /usr/glibc-compat/lib/libpthread.so.0

##0.794 /lib/libc.musl-aarch64.so.1
##0.899 /usr/lib/libc.so
##0.899 /usr/lib/libc.musl-aarch64.so.1
##0.899 /usr/lib/libc.a
##0.899 /usr/glibc-compat/lib/libc.so
##0.899 /usr/glibc-compat/lib/libc.so.6


ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#master ${AMBED_INST_DIR}

RUN sed "s/\(USE_AGC[[:space:]]*\)[[:digit:]]/\1${USE_AGC}/g" ${AMBED_INST_DIR}${AMBED_DIR}/main.h && \
    cp ${AMBED_INST_DIR}${AMBED_DIR}/main.h ${AMBED_DIR}/main.h.customized

RUN cd ${AMBED_INST_DIR}${AMBED_DIR} && \
    echo "/lib:/usr/local/lib:/usr/lib" > /etc/ld-musl-x86_64.path && \
    make clean && \
    make && \
    make install && \
    cp ${AMBED_INST_DIR}${AMBED_DIR}${AMBED_DIR} ${AMBED_DIR}

COPY s6_overlay/ /

RUN rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

EXPOSE 10100/udp
EXPOSE 10101-10199/udp
