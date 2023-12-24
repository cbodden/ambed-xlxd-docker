# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM ubuntu:latest AS base

ENTRYPOINT [ "/init" ]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV CALLHOME CALLSIGN COMMENT COUNTRY DESCRIPTION EMAIL PORT TZ URL XLXNUM
ENV MODULES MODULEA MODULEB MODULEC MODULED
ENV XLXD_DIR=/xlxd XLXD_INST_DIR=/src/xlxd XLXD_WEB_DIR=/var/www/xlxd
ENV XLXCONFIG=/var/www/xlxd/pgs/config.inc.php
ARG TARGETARCH
ARG YSF_AUTOLINK_ENABLE=1 YSF_AUTOLINK_MODULE="A"
ARG YSF_DEFAULT_NODE_RX_FREQ=438000000 YSF_DEFAULT_NODE_TX_FREQ=438000000
ARG S6_OVERLAY_VERSION=3.1.6.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        apache2 \
        build-essential \
        curl \
        libapache2-mod-php \
        php \
        php-mbstring \
        wget

RUN mkdir -p \
    ${S6_OVERLAY_INST} \
    ${XLXD_DIR} \
    ${XLXD_INST_DIR} \
    ${XLXD_WEB_DIR} && \
    chown -R www-data:www-data ${XLXD_DIR}/

RUN wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -O "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz" && \
    tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz"

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" -O "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" && \
        tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz"; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" -O "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" && \
        tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz"; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" && \
        exit 1; \
    fi

ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#master ${XLXD_INST_DIR}

RUN sed -i "s/\#define\ RUN_AS_DAEMON/\/\/\#define\ RUN_AS_DAEMON/g" ${XLXD_INST_DIR}/src/main.h && \
    sed -i "1!b;s/\(NB_OF_MODULES[[:blank:]]*\)[[:digit:]]*/\1${MODULES}/g" ${XLXD_INST_DIR}/src/main.h && \
    sed -i "s/\(YSF_AUTOLINK_ENABLE[[:blank:]]*\)[[:digit:]]/\1${YSF_AUTOLINK_ENABLE}/g" ${XLXD_INST_DIR}/src/main.h && \
    sed -i "s/\(YSF_AUTOLINK_MODULE[[:blank:]]*\)'[[:alpha:]]'/\1\'${YSF_AUTOLINK_MODULE}\'/g" ${XLXD_INST_DIR}/src/main.h && \
    sed -i "s/\(YSF_DEFAULT_NODE_RX_FREQ[[:blank:]]*\)[[:digit:]]*/\1${YSF_DEFAULT_NODE_RX_FREQ}/g" ${XLXD_INST_DIR}/src/main.h && \
    sed -i "s/\(YSF_DEFAULT_NODE_TX_FREQ[[:blank:]]*\)[[:digit:]]*/\1${YSF_DEFAULT_NODE_TX_FREQ}/g" ${XLXD_INST_DIR}/src/main.h && \
    cp ${XLXD_INST_DIR}/src/main.h ${XLXD_DIR}/main.h.customized && \
    cp ${XLXD_INST_DIR}/src/cysfprotocol.cpp ${XLXD_DIR}/cysfprotocol.cpp.customized

RUN cd ${XLXD_INST_DIR}/src && \
    make clean && \
    make && \
    make install

RUN cp -ivR ${XLXD_INST_DIR}/dashboard/* ${XLXD_WEB_DIR}/ && \
    chown -R www-data:www-data ${XLXD_WEB_DIR}/

COPY s6_overlay/ /

RUN apt -y purge build-essential && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

EXPOSE 80/tcp
EXPOSE 8080/tcp
EXPOSE 10001/udp
EXPOSE 10002/udp
EXPOSE 42000/udp
EXPOSE 30001/udp
EXPOSE 20001/udp
EXPOSE 30051/udp
EXPOSE 8880/udp
EXPOSE 62030/udp
EXPOSE 12345-12346/udp
EXPOSE 40000/udp
EXPOSE 21110/udp
