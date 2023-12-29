# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM ubuntu:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV DESCRIPTION="" ID="" NAME="" PORT=""
ARG TARGETARCH
ARG YSF_DIR=/YSFReflector YSF_INST_DIR=/src/ysf
ARG S6_OVERLAY_VERSION=3.1.6.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        build-essential \
        wget

RUN mkdir -p \
    ${YSF_DIR} \
    ${YSF_INST_DIR} \
    ${S6_OVERLAY_INST}

RUN wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        -O "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz" && \
    tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz"

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" && \
        tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz"; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" && \
        tar -C / -Jxpf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz"; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" && \
        exit 1; \
    fi

ADD --keep-git-dir=true https://github.com/nostar/DVReflectors.git#main ${YSF_INST_DIR}

RUN cd ${YSF_INST_DIR}${YSF_DIR} && \
    make clean && \
    make && \
    make all && \
    cp ${YSF_INST_DIR}/YSFReflector/YSFReflector.ini ${YSF_DIR}/YSFReflector.ini && \
    cp ${YSF_INST_DIR}/YSFReflector/YSFReflector ${YSF_DIR}/YSFReflector

COPY s6_overlay/ /

RUN apt -y purge build-essential \
        wget && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

EXPOSE 42000-42010/udp
