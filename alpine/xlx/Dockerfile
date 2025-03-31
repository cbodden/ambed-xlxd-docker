## xlx
# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM alpine:latest

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV CALLHOME CALLSIGN COMMENT COUNTRY DESCRIPTION EMAIL PORT TZ URL XLXNUM
ENV MODULES MODULEA MODULEB MODULEC MODULED
ENV XLXD_DIR=/xlxd XLXD_INST_DIR=/src/xlxd XLXD_WEB_DIR=/var/www/xlxd
ENV XLXCONFIG=/var/www/xlxd/pgs/config.inc.php
ARG TARGETARCH
ARG YSF_AUTOLINK_ENABLE=1 YSF_PORT=42000 YSF_AUTOLINK_MODULE="A"
ARG YSF_DEFAULT_NODE_RX_FREQ=438000000 YSF_DEFAULT_NODE_TX_FREQ=438000000
ARG S6_OVERLAY_VERSION=3.2.0.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

## mounting a cache volume - then apk updates and adds
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk update \
    && apk add --virtual build-dependencies \
    && apk add --update --no-cache \
        alpine-sdk build-base linux-headers \
        bash curl xz \
    && apk add --update --no-cache \
        --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
        apache2 apache2-utils php84 php84-apache2 php84-mbstring

## making dirs for installs
RUN mkdir -p \
    ${S6_OVERLAY_INST} \
    ${XLXD_DIR} \
    ${XLXD_INST_DIR} \
    ${XLXD_WEB_DIR}

##########################
###### xlxd install ######
##########################

 ## pulling repo xlxd
 ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#master ${XLXD_INST_DIR}
 
 ## sed edits for xlxd config
 RUN sed -i "s/\#define\ RUN_AS_DAEMON/\/\/\#define\ RUN_AS_DAEMON/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "1!b;s/\(NB_OF_MODULES[[:blank:]]*\)[[:digit:]]*/\1${MODULES}/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "s/\(YSF_AUTOLINK_ENABLE[[:blank:]]*\)[[:digit:]]/\1${YSF_AUTOLINK_ENABLE}/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "s/\(YSF_AUTOLINK_MODULE[[:blank:]]*\)'[[:alpha:]]'/\1\'${YSF_AUTOLINK_MODULE}\'/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "s/\(YSF_PORT[[:blank:]]*\)[[:digit:]]/\1${YSF_PORT}/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "s/\(YSF_DEFAULT_NODE_RX_FREQ[[:blank:]]*\)[[:digit:]]*/\1${YSF_DEFAULT_NODE_RX_FREQ}/g" ${XLXD_INST_DIR}/src/main.h \
     && sed -i "s/\(YSF_DEFAULT_NODE_TX_FREQ[[:blank:]]*\)[[:digit:]]*/\1${YSF_DEFAULT_NODE_TX_FREQ}/g" ${XLXD_INST_DIR}/src/main.h \
     && cp ${XLXD_INST_DIR}/src/main.h ${XLXD_DIR}/main.h.customized \
     && cp ${XLXD_INST_DIR}/src/cysfprotocol.cpp ${XLXD_DIR}/cysfprotocol.cpp.customized
 
 ## making xlxd
 RUN cd ${XLXD_INST_DIR}/src \
     && make clean \
     && make \
     && make install
 
 ## copying the dashboard
 RUN cp -ivR ${XLXD_INST_DIR}/dashboard/* ${XLXD_WEB_DIR}/

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

#### xlx ####

## Define xlxd as a long running s6 service
COPY <<EOF /etc/s6-overlay/s6-rc.d/xlxd/type
longrun
EOF

## Define entrypoint for xlxd && start in foreground
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/xlxd/run
#!/command/with-contenv sh

PIDFILE="/var/log/xlxd.pid"
XMLFILE="/var/log/xlxd.xml"
IP=$( hostname -i )
AMBED=ambed

if [ -z ${XLXNUM:-} ]; then
  echo "XLXNUM is not set"
  exit 1
fi

# check for modified config files
cp -p /config/*.* ${XLXD_DIR}

# restore xml file to preserve historical data and allow dashboard to start immediately
cp -p /config/log/xlxd.xml ${XMLFILE}

# download the dmrid.dat from the XLXAPI server to the xlxd folder
curl -L -s -o ${XLXD_DIR}/dmrid.dat http://xlxapi.rlx.lu/api/exportdmr.php

# TODO: generate xlxd.interlink file

# Create pid file for service uptime dashboard class
touch ${PIDFILE}

# start daemon
exec /xlxd/xlxd ${XLXNUM} ${IP} ${AMBED}
EOF

## register xlxd as a service for s6
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/xlxd

## register dependencies 
RUN mkdir /etc/s6-overlay/s6-rc.d/xlxd/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/xlxd/dependencies.d/customize \
    && touch /etc/s6-overlay/s6-rc.d/xlxd/dependencies.d/base

#### httpd ####

## define httpd as a long running s6 service
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
    && touch /etc/s6-overlay/s6-rc.d/httpd/dependencies.d/xlxd \
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


###################################
###### s6 overlay config end ######
###################################

#####################
###### cleanup ######
#####################

RUN rm -rf /var/cache/apk/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /src

############################
###### exposing ports ######
############################

EXPOSE 80/tcp
EXPOSE 8080/tcp
EXPOSE 8880/udp
EXPOSE 10001/udp
EXPOSE 10002/udp
EXPOSE 12345-12346/udp
EXPOSE 20001/udp
EXPOSE 21110/udp
EXPOSE 30001/udp
EXPOSE 30051/udp
EXPOSE 40000/udp
EXPOSE 42000-42005/udp
EXPOSE 62030/udp

########################
###### entrypoint ######
########################

ENTRYPOINT ["/init"]
