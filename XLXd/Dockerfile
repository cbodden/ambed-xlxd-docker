## xlx
# syntax=docker/dockerfile:1-labs
FROM mirror.gcr.io/library/alpine:latest

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
## runtime defaults - URL && XLXNUM must be set by the stack
ENV AMBED="ambed" CALLHOME="false" CALLSIGN="" COMMENT="" COUNTRY="" DESCRIPTION="" EMAIL="" \
    PORT="80" TZ="UTC" URL="" XLXNUM=""
## module count (xlxd is built with 26) - names come from MODULEA..MODULEZ, unset keeps the dashboard default
ENV MODULES="26"
ENV XLXD_DIR=/xlxd XLXD_INST_DIR=/src/xlxd XLXD_WEB_DIR=/var/www/xlxd
ENV XLXCONFIG=/var/www/xlxd/pgs/config.inc.php
ARG TARGETARCH
## LX3JL/xlxd commit : xlxd 2.6.2 / AMBEd 1.5.0
ARG XLXD_GIT_REF=f13dfaebb5759ae8fdf32ed7adaa29421f67a993
## module a YSF client lands on when it doesn't pick one, and the IMRS (Wires-X) default module
## upstream 2.6 uses B; A keeps them off a parrot / special-purpose module B
ARG YSF_AUTOLINK_MODULE=A IMRS_DEFAULT_MODULE=A
ARG S6_OVERLAY_VERSION=3.2.3.2 S6_OVERLAY_INST=/src/S6
ARG S6_OVERLAY_ADDRESS=https://github.com/just-containers/s6-overlay/releases/download/v

## mounting a cache volume - then apk updates and adds
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked \
    apk update \
    && apk add --virtual build-dependencies \
    && apk add --update --no-cache \
        alpine-sdk build-base linux-headers \
        bash curl xz \
        vnstat \
        apache2 apache2-utils \
        php84 php84-apache2 php84-common php84-curl php84-mbstring php84-session

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
ADD --keep-git-dir=true https://github.com/LX3JL/xlxd.git#${XLXD_GIT_REF} ${XLXD_INST_DIR}

## sed edits for xlxd config
RUN sed -i "s/\#define\ RUN_AS_DAEMON/\/\/\#define\ RUN_AS_DAEMON/g" ${XLXD_INST_DIR}/src/main.h \
    && sed -i "1!b;s/\(NB_OF_MODULES[[:blank:]]*\)[[:digit:]]*/\1${MODULES}/g" ${XLXD_INST_DIR}/src/main.h \
    && sed -i "s/^\(#define[[:blank:]]*YSF_AUTOLINK_MODULE[[:blank:]]*\)'[A-Z]'/\1'${YSF_AUTOLINK_MODULE}'/" ${XLXD_INST_DIR}/src/main.h \
    && sed -i "s/^\(#define[[:blank:]]*IMRS_DEFAULT_MODULE[[:blank:]]*\)'[A-Z]'/\1'${IMRS_DEFAULT_MODULE}'/" ${XLXD_INST_DIR}/src/main.h \
    && grep -Eq "^#define[[:blank:]]+YSF_AUTOLINK_MODULE[[:blank:]]+'${YSF_AUTOLINK_MODULE}'" ${XLXD_INST_DIR}/src/main.h \
    && grep -Eq "^#define[[:blank:]]+IMRS_DEFAULT_MODULE[[:blank:]]+'${IMRS_DEFAULT_MODULE}'" ${XLXD_INST_DIR}/src/main.h \
    && cp ${XLXD_INST_DIR}/src/main.h ${XLXD_DIR}/main.h.customized \
    && cp ${XLXD_INST_DIR}/src/cysfprotocol.cpp ${XLXD_DIR}/cysfprotocol.cpp.customized

## making xlxd
RUN cd ${XLXD_INST_DIR}/src \
    && make clean \
    && make \
    && make install

## copying the dashboard (upstream split into dashboard1 classic && dashboard2)
RUN cp -ivR ${XLXD_INST_DIR}/dashboard1/* ${XLXD_WEB_DIR}/

## dashboard 2.4.7 html-escapes module names - keep the escaping but allow <br> so multi-line names still work
COPY <<"EOF" /src/sanitize_module_name.php
<?php
// module names (PageOptions['ModuleNames']) : escape everything except <br>
function sanitize_module_name($string) {
    return preg_replace('#&lt;br\s*/?&gt;#i', '<br />', sanitize_output($string));
}
EOF

RUN cat /src/sanitize_module_name.php >> ${XLXD_WEB_DIR}/pgs/functions.php \
    && sed -i "/ModuleNames/s/sanitize_output(/sanitize_module_name(/" \
        ${XLXD_WEB_DIR}/pgs/users.php ${XLXD_WEB_DIR}/pgs/modules.php \
    && grep -q "sanitize_module_name(" ${XLXD_WEB_DIR}/pgs/users.php \
    && grep -q "sanitize_module_name(" ${XLXD_WEB_DIR}/pgs/modules.php

## upstream always shows the Reflectors list - add a ReflectorsPage['Show'] option (REFLECTORS_PAGE)
## that the menu and the page switch honour; fails the build if upstream's markup moved
COPY scripts/patch-dashboard.sh /src/patch-dashboard.sh
RUN sh /src/patch-dashboard.sh ${XLXD_WEB_DIR}

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
COPY --chmod=700 scripts/xlxd_run.sh /etc/s6-overlay/s6-rc.d/xlxd/run

## register xlxd as a service for s6
RUN touch /etc/s6-overlay/user-bundles.d/user/contents.d/xlxd

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
RUN touch /etc/s6-overlay/user-bundles.d/user/contents.d/httpd

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
RUN touch /etc/s6-overlay/user-bundles.d/user/contents.d/customize

## copying the httpd customization script to /etc/s6-overlay/scripts/customize.sh
## plus the env helpers it shares with vnstatd (dashboard switches: on/off, numbers, IP display)
COPY --chmod=700 scripts/customize.sh /etc/s6-overlay/scripts/
COPY --chmod=644 scripts/dashboard-env.sh /etc/s6-overlay/scripts/

## register dependencies
RUN mkdir /etc/s6-overlay/s6-rc.d/customize/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/customize/dependencies.d/base


#### vnstatd ####

## traffic collector for the dashboard's Traffic statistics page - idles unless TRAFFIC_PAGE is on
COPY <<EOF /etc/s6-overlay/s6-rc.d/vnstatd/type
longrun
EOF

COPY --chmod=700 scripts/vnstatd_run.sh /etc/s6-overlay/s6-rc.d/vnstatd/run

## register vnstatd as a service for s6
RUN touch /etc/s6-overlay/user-bundles.d/user/contents.d/vnstatd

## register dependencies
RUN mkdir /etc/s6-overlay/s6-rc.d/vnstatd/dependencies.d/ \
    && touch /etc/s6-overlay/s6-rc.d/vnstatd/dependencies.d/base

###################################
###### s6 overlay config end ######
###################################

#####################
###### cleanup ######
#####################

RUN rm -rf /var/cache/apk/* \
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
EXPOSE 17000/udp
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
