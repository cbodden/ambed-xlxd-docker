# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM ubuntu:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV DESCRIPTION="" ID="" NAME="" PORT="42000" URL="" WEB_PORT="80"
ARG TARGETARCH
ARG YSF_DIR=/YSFReflector YSF_INST_DIR=/src/ysf
ARG YSF_DASH_INST_DIR=/src/YSFDashboard
ARG S6_OVERLAY_VERSION=3.2.0.6 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        apache2 \
        build-essential \
        libapache2-mod-php \
        php \
        php-mbstring \
        procps \
        wget

RUN mkdir -p \
    ${YSF_DIR} \
    ${YSF_INST_DIR} \
    ${YSF_DASH_INST_DIR} \
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

ADD --keep-git-dir=true https://github.com/dg9vh/YSFReflector-Dashboard.git#master ${YSF_DASH_INST_DIR}

RUN cp ${YSF_DASH_INST_DIR}/favicon.ico /var/www/html/ && \
    cp ${YSF_DASH_INST_DIR}/index.php /var/www/html/ && \
    cp ${YSF_DASH_INST_DIR}/txinfo.php /var/www/html/ && \
    cp ${YSF_DASH_INST_DIR}/version.php /var/www/html/ && \
    cp -r ${YSF_DASH_INST_DIR}/include/ /var/www/html/ && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    rm -f /var/www/html/index.html

COPY s6_overlay/ /

RUN apt -y purge build-essential \
        wget && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

EXPOSE 80/tcp
EXPOSE 42000/udp
