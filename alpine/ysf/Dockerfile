## ysf
# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM alpine:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV DESCRIPTION="" ID="" NAME="" PORT="42000" URL="" WEB_PORT="80"
ARG TARGETARCH
ARG YSF_DIR=/YSFReflector YSF_INST_DIR=/src/ysf
ARG YSF_DASH_INST_DIR=/src/YSFDashboard
ARG S6_OVERLAY_VERSION=3.2.0.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

##libapache2-mod-php \

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk update && \
    apk add --virtual build-dependencies && \
    apk add --update --no-cache \
        alpine-sdk build-base linux-headers \
        bash xz procps-ng && \
    apk add --update --no-cache \
        --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        apache2 php81 php81-mbstring php81-apache2

RUN mkdir -p \
    ${YSF_DIR} \
    ${YSF_INST_DIR} \
    ${YSF_DASH_INST_DIR} \
    ${S6_OVERLAY_INST} \
    /var/www/html/

RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        cd "${S6_OVERLAY_INST}" && \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" && \
        tar -xJf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" && \
        mv * / ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        cd "${S6_OVERLAY_INST}" && \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" && \
        tar -xJf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" && \
        mv * / ; \
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
    rm -f /var/www/html/index.html

COPY s6_overlay/ /

RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

EXPOSE 80/tcp
EXPOSE 42000/udp
