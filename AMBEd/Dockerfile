## ambed
# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM ubuntu:latest AS base

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ARG TARGETARCH
ARG AMBED_DIR=/ambed AMBED_INST_DIR=/src/ambed USE_AGC=0
ARG FTDI_INST_VER=1.4.33 FTDI_INST_DIR=/src/ftdi
ARG FTDI_INST_ADDRESS=https://ftdichip.com/wp-content/uploads/2025/03
ARG S6_OVERLAY_VERSION=3.2.1.0 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

## apt updates and adds
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt update \
    && apt upgrade -y \
    && apt install -y \
        build-essential \
        curl \
        kmod \
        lsof \
        sudo \
        wget

## making dirs for installs
RUN mkdir -p \
    ${AMBED_DIR} \
    ${AMBED_INST_DIR} \
    ${FTDI_INST_DIR} \
    ${S6_OVERLAY_INST}

##########################
###### FTDI install ######
##########################

## pulling repo xlxd
ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#master ${AMBED_INST_DIR}

## installing FTDI drivers
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${FTDI_INST_ADDRESS}/libftd2xx-linux-arm-v8-${FTDI_INST_VER}.tgz" \
            -O "${FTDI_INST_DIR}/libftd2xx-arm-v8-${FTDI_INST_VER}.tgz" \
        && tar xfvz "${FTDI_INST_DIR}/libftd2xx-arm-v8-${FTDI_INST_VER}.tgz" \
        && cp linux-arm-v8/libftd2xx.* /usr/local/lib \
        && chmod 0755 /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} \
        && ln -sf /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib/libftd2xx.so \
        && cp linux-arm-v8/ftd2xx.h /usr/local/include \
        && cp linux-arm-v8/WinTypes.h /usr/local/include \
        && ldconfig ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${FTDI_INST_ADDRESS}/libftd2xx-linux-x86_64-${FTDI_INST_VER}.tgz" \
            -O "${FTDI_INST_DIR}/libftd2xx-x86_64-${FTDI_INST_VER}.tgz" \
        && tar xfvz "${FTDI_INST_DIR}/libftd2xx-x86_64-${FTDI_INST_VER}.tgz" \
        && cp linux-x86_64/libftd2xx.* /usr/local/lib \
        && chmod 0755 /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} \
        && ln -sf /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib/libftd2xx.so \
        && cp linux-x86_64/ftd2xx.h /usr/local/include \
        && cp linux-x86_64/WinTypes.h /usr/local/include \
        && ldconfig ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" \
        && exit 1 ; \
    fi

## sed edits for main.h
RUN sed "s/\(USE_AGC[[:space:]]*\)[[:digit:]]/\1${USE_AGC}/g" ${AMBED_INST_DIR}${AMBED_DIR}/main.h \
    && cp ${AMBED_INST_DIR}${AMBED_DIR}/main.h ${AMBED_DIR}/main.h.customized

## making ambed
RUN cd ${AMBED_INST_DIR}${AMBED_DIR} \
    && make clean \
    && make \
    && make install \
    && cp ${AMBED_INST_DIR}${AMBED_DIR}${AMBED_DIR} ${AMBED_DIR}

################################
###### s6 overlay install ######
################################

## installing the s6_overlay noarch
RUN wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        -O "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz" \
    && tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz"

## installing the s6_overlay arch either arm || amd
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" \
        && tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" \
        && tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" \
        && exit 1 ; \
    fi

#####################################
###### s6 overlay config begin ######
#####################################

COPY s6_overlay/ /

###################################
###### s6 overlay config end ######
###################################

#####################
###### cleanup ######
#####################

RUN apt -y purge build-essential \
    && apt -y autoremove \
    && apt -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /src

############################
###### exposing ports ######
############################

EXPOSE 10100/udp
EXPOSE 10101-10199/udp

########################
###### entrypoint ######
########################

ENTRYPOINT ["/init"]

