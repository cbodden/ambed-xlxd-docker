## ambed
# syntax=docker/dockerfile:1-labs

## previously published image used as a libftd2xx fallback (ftdichip.com 403s non-browser downloads)
ARG FTDI_FALLBACK_IMAGE=cbodden/ambed-docker:latest
FROM ${FTDI_FALLBACK_IMAGE} AS ftdi_fallback

FROM ubuntu:latest AS base

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ARG TARGETARCH
ARG AMBED_DIR=/ambed AMBED_INST_DIR=/src/ambed USE_AGC=0
## LX3JL/xlxd commit : AMBEd 1.4.0 / xlxd 2.6.1
ARG XLXD_GIT_REF=a978f03671d87c6d9ac13453689755991e5cb668
ARG FTDI_INST_VER=1.4.33 FTDI_INST_DIR=/src/ftdi
ARG FTDI_INST_ADDRESS=https://ftdichip.com/wp-content/uploads/2025/03
ARG FTDI_FALLBACK_IMAGE
ARG S6_OVERLAY_VERSION=3.2.1.0 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v
## optional ubuntu archive mirror (ex: http://azure.archive.ubuntu.com/ubuntu on github amd64 runners)
ARG UBUNTU_MIRROR

## apt updates and adds
RUN if [ -n "${UBUNTU_MIRROR}" ]; then \
        sed -i "s|http://archive.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources ; \
    fi \
    && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries \
    && echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
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
ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#${XLXD_GIT_REF} ${AMBED_INST_DIR}

## staging the fallback FTDI lib && headers from the previously published image
COPY --from=ftdi_fallback /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} ${FTDI_INST_DIR}/fallback/
COPY --from=ftdi_fallback /usr/local/include/ftd2xx.h /usr/local/include/WinTypes.h ${FTDI_INST_DIR}/fallback/

## installing FTDI drivers - ftdichip.com first, fallback image if the download fails
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        FTDI_ARCH=arm-v8 ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        FTDI_ARCH=x86_64 ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" \
        && exit 1 ; \
    fi \
    && if wget "${FTDI_INST_ADDRESS}/libftd2xx-linux-${FTDI_ARCH}-${FTDI_INST_VER}.tgz" \
            -O "${FTDI_INST_DIR}/libftd2xx-${FTDI_ARCH}-${FTDI_INST_VER}.tgz" ; then \
        tar -C "${FTDI_INST_DIR}" -xzvf "${FTDI_INST_DIR}/libftd2xx-${FTDI_ARCH}-${FTDI_INST_VER}.tgz" \
        && cp ${FTDI_INST_DIR}/linux-${FTDI_ARCH}/libftd2xx.* /usr/local/lib \
        && cp ${FTDI_INST_DIR}/linux-${FTDI_ARCH}/ftd2xx.h /usr/local/include \
        && cp ${FTDI_INST_DIR}/linux-${FTDI_ARCH}/WinTypes.h /usr/local/include ; \
    else \
        echo "ftdichip.com download failed - using libftd2xx ${FTDI_INST_VER} from ${FTDI_FALLBACK_IMAGE}" \
        && cp ${FTDI_INST_DIR}/fallback/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib \
        && cp ${FTDI_INST_DIR}/fallback/*.h /usr/local/include ; \
    fi \
    && chmod 0755 /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} \
    && ln -sf /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib/libftd2xx.so \
    && ldconfig

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

