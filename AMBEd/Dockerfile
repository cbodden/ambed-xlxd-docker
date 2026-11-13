## ambed
# syntax=docker/dockerfile:1-labs

## two stages : "build" compiles ambed and fetches libftd2xx + s6-overlay into /rootfs,
## the final image is a clean ubuntu with only /rootfs and the runtime packages (no compiler)

## previously published image used as a libftd2xx fallback (ftdichip.com 403s non-browser downloads)
## the final image keeps /usr/local/lib/libftd2xx.so.* and /usr/local/include/{ftd2xx,WinTypes}.h for this
## from ghcr (same image as docker hub's) so the build doesn't use up docker hub's pull limit
ARG FTDI_FALLBACK_IMAGE=ghcr.io/cbodden/ambed-docker:latest
FROM ${FTDI_FALLBACK_IMAGE} AS ftdi_fallback

##########################################
###### ubuntu + apt settings (both) ######
##########################################

## docker hub's official ubuntu via google's mirror (same digests, no docker hub pull limit)
FROM mirror.gcr.io/library/ubuntu:latest AS ubuntu

## optional ubuntu archive mirror (ex: http://azure.archive.ubuntu.com/ubuntu on github amd64 runners)
ARG UBUNTU_MIRROR

RUN if [ -n "${UBUNTU_MIRROR}" ]; then \
        sed -i "s|http://archive.ubuntu.com/ubuntu|${UBUNTU_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources ; \
    fi \
    && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries \
    && echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#########################
###### build stage ######
#########################

FROM ubuntu AS build

ARG TARGETARCH
ARG AMBED_DIR=/ambed AMBED_INST_DIR=/src/ambed
## LX3JL/xlxd commit : AMBEd 1.5.0 / xlxd 2.6.2
ARG XLXD_GIT_REF=f13dfaebb5759ae8fdf32ed7adaa29421f67a993
ARG FTDI_INST_VER=1.4.33 FTDI_INST_DIR=/src/ftdi
ARG FTDI_INST_ADDRESS=https://ftdichip.com/wp-content/uploads/2025/03
ARG FTDI_FALLBACK_IMAGE
ARG S6_OVERLAY_VERSION=3.2.3.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v
## everything the final image gets, laid out from /
ARG ROOTFS=/rootfs

## apt updates and adds
RUN apt update \
    && apt install -y \
        build-essential \
        ca-certificates \
        wget \
        xz-utils

## making dirs for installs
RUN mkdir -p \
    ${AMBED_DIR} \
    ${AMBED_INST_DIR} \
    ${FTDI_INST_DIR} \
    ${S6_OVERLAY_INST} \
    ${ROOTFS}/usr/local/lib \
    ${ROOTFS}/usr/local/include

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
    && ldconfig \
    && cp -a /usr/local/lib/libftd2xx.so.${FTDI_INST_VER} /usr/local/lib/libftd2xx.so ${ROOTFS}/usr/local/lib/ \
    && cp -a /usr/local/include/ftd2xx.h /usr/local/include/WinTypes.h ${ROOTFS}/usr/local/include/

## making ambed
## AMBEd 1.5.0 settings (gains, AGC, filter ...) live in ambed.ini, not main.h - the s6 ambed service
## writes /ambed/ambed.ini at start from AMBED_* env vars, upstream's copy is kept as ambed.ini.dist
RUN cd ${AMBED_INST_DIR}${AMBED_DIR} \
    && make clean \
    && make \
    && make install \
    && cp -a ${AMBED_DIR} ${ROOTFS}${AMBED_DIR} \
    && mv ${ROOTFS}${AMBED_DIR}/ambed.ini ${ROOTFS}${AMBED_DIR}/ambed.ini.dist

################################
###### s6 overlay install ######
################################

## installing the s6_overlay noarch
RUN wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        -O "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz" \
    && tar -C ${ROOTFS} -Jxpf "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz"

## installing the s6_overlay arch either arm || amd
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" \
        && tar -C ${ROOTFS} -Jxpf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" \
        && tar -C ${ROOTFS} -Jxpf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" \
        && exit 1 ; \
    fi

#########################
###### final image ######
#########################

FROM ubuntu

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

## runtime packages only, no compiler / download tools
RUN apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
        kmod \
        lsof \
        sudo \
    && apt -y clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## ambed, libftd2xx + headers, s6-overlay
COPY --from=build /rootfs/ /

#####################################
###### s6 overlay config begin ######
#####################################

COPY s6_overlay/ /

###################################
###### s6 overlay config end ######
###################################

## fail the build if ambed or libftd2xx can't find a library here (it was only checked against the build stage)
RUN ldconfig \
    && if ldd /ambed/ambed /usr/local/lib/libftd2xx.so | grep 'not found' ; then \
        echo "missing runtime libraries" \
        && exit 1 ; \
    fi

############################
###### exposing ports ######
############################

EXPOSE 10100/udp
EXPOSE 10101-10199/udp

########################
###### entrypoint ######
########################

ENTRYPOINT ["/init"]
