## ysf
# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM alpine:latest

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV DESCRIPTION="" ID="" NAME="" PORT="42000" URL="" WEB_PORT="80"
ARG TARGETARCH
ARG YSF_DIR=/YSFReflector YSF_INST_DIR=/src/ysf
ARG YSF_DASH_INST_DIR=/src/YSFDashboard
ARG S6_OVERLAY_VERSION=3.2.0.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

## mounting a cache volume - then apk updates and adds
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk update \
    && apk add --virtual build-dependencies \
    && apk add --update --no-cache \
        alpine-sdk build-base linux-headers \
        bash curl procps-ng xz  \
        apache2 apache2-utils \
        php84 php84-apache2 php84-common php84-mbstring php84-session

## making dirs for installs
RUN mkdir -p \
    ${YSF_DIR} \
    ${YSF_INST_DIR} \
    ${YSF_DASH_INST_DIR} \
    ${S6_OVERLAY_INST}

##################################
###### YSFReflector Install ######
##################################

#### reflector ####

ADD --keep-git-dir=true https://github.com/nostar/DVReflectors.git#main ${YSF_INST_DIR}

RUN cd ${YSF_INST_DIR}${YSF_DIR} \
    && make clean \
    && make \
    && make all \
    && cp ${YSF_INST_DIR}/YSFReflector/YSFReflector.ini ${YSF_DIR}/YSFReflector.ini \
    && cp ${YSF_INST_DIR}/YSFReflector/YSFReflector ${YSF_DIR}/YSFReflector

#### Dashboard ####

ADD --keep-git-dir=true https://github.com/dg9vh/YSFReflector-Dashboard.git#master ${YSF_DASH_INST_DIR}

RUN mkdir /var/www/html \
    && cp ${YSF_DASH_INST_DIR}/favicon.ico /var/www/html/ \
    && cp ${YSF_DASH_INST_DIR}/index.php /var/www/html/ \
    && cp ${YSF_DASH_INST_DIR}/txinfo.php /var/www/html/ \
    && cp ${YSF_DASH_INST_DIR}/version.php /var/www/html/ \
    && cp -r ${YSF_DASH_INST_DIR}/include/ /var/www/html/ \
    && rm -f /var/www/html/index.html

#################################
###### s6 overlay install  ######
#################################

## installing the s6_overlay noarch
RUN wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        -O "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz" \
    && tar -C / -xJf "${S6_OVERLAY_INST}/s6-overlay-noarch.tar.xz"

## installing the s6_overlay arch either arm || amd
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" \
        && tar -C / -xJf "${S6_OVERLAY_INST}/s6-overlay-aarch64.tar.xz" ; \
    elif [ "${TARGETARCH}" = "amd64" ]; then \
        wget "${S6_OVERLAY_ADDRESS}${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" \
            -O "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" \
        && tar -C / -xJf "${S6_OVERLAY_INST}/s6-overlay-x86_64.tar.xz" ; \
    else \
        echo "DANGER WILL ROBINSON. UNKNOWN TARGETARCH" \
        && exit 1 ; \
    fi

#####################################
###### s6 overlay config begin ######
#####################################


#### httpd ####

## define httpd as a longrun s6 service
COPY <<EOF /etc/s6-overlay/s6-rc.d/httpd/type
longrun
EOF

## define entrypoint for httpd && start in foreground
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/httpd/run
#!/command/with-contenv sh
exec /usr/sbin/httpd -D FOREGROUND
EOF

## register httpd as a service for s6
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/httpd

## register dependencies
RUN mkdir /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/YSFReflector \
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/customize \
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/base


#### httpd customization script ####

## define httpd customization as a oneshot service
COPY <<EOF /etc/s6-overlay/s6-rc.d/customize/type
oneshot
EOF

## run httpd customize as oneshot run on up
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/customize/up
/etc/s6-overlay/scripts/customize.sh
EOF

## register httpd customization as a service for s6
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/customize

## copying the httpd customization script to /etc/s6-overlay/scripts/customize.sh
COPY --chmod=700 scripts/customize.sh /etc/s6-overlay/scripts/

## register dependencies
RUN mkdir /etc/s6-overlay/s6-rc.d/customize/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/customize/dependencies.d/base


#### YSFReflector ####

## define YSFReflector as a longrun s6 service
COPY <<EOF /etc/s6-overlay/s6-rc.d/YSFReflector/type
longrun
EOF

## define entrypoint for YSFReflector && start in foreground
COPY --chmod=700 scripts/YSFReflector_run.sh /etc/s6-overlay/s6-rc.d/YSFReflector/run

## register YSFReflector as a service for s6
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/YSFReflector

## register dependencies
RUN mkdir /etc/s6-overlay/s6-rc.d/YSFReflector/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/base \
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/customize

###################################
###### s6 overlay config end ######
###################################

#####################
###### cleanup ######
#####################

RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

############################
###### exposing ports ######
############################

EXPOSE 80/tcp
EXPOSE 42000/udp

########################
###### entrypoint ######
########################

ENTRYPOINT ["/init"]
