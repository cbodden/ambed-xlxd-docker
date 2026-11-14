# syntax=mirror.gcr.io/docker/dockerfile:1-labs
## ysfdashboard2
## ShaYmez/YSFReflector-Dashboard2 for the ysfreflector image: reads the reflector's dated log files and
## YSFReflector.ini (written there for it) from its shared log volume, mounted read only
FROM mirror.gcr.io/library/alpine:latest

ARG DASH_GIT_REF=8a9d3b468470b9ab4fad7c244755c03accf331b2

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC" DASH_KIND="YSF"
## runtime settings - see README
ENV DASHBOARD_PORT="80" DASHBOARD_PATH="/" DASHBOARD_NAME="" DASHBOARD_TAGLINE="" DASHBOARD_LOGO="" \
    SHOW_QRZ="off" GDPR="off" LAST_HEARD_FIRST="off" SHOW_SYSTEM_INFO="off" \
    SHOW_PROGRESS_BARS="on" SHOW_OLD_MHEARD="7"

RUN apk add --no-cache apache2 php84 php84-apache2 php84-ctype php84-mbstring tzdata

ADD https://github.com/ShaYmez/YSFReflector-Dashboard2.git#${DASH_GIT_REF} /var/www/dashboard

## no setup wizard (the config comes from the environment); apache serves the dashboard, logs to the
## container output, and refuses config/ and dot-files
RUN rm -f /var/www/dashboard/setup.php \
    && rm -rf /var/www/dashboard/src /var/www/dashboard/package*.json /var/www/dashboard/tailwind.config.js \
    && sed -i \
        -e 's|/var/www/localhost/htdocs|/var/www/dashboard|g' \
        -e 's|DirectoryIndex index.html|DirectoryIndex index.php|' \
        -e 's|^ErrorLog .*|ErrorLog /dev/stderr|' \
        -e 's|^\([[:blank:]]*\)CustomLog .*|\1CustomLog /dev/stdout combined|' \
        -e 's|^ServerTokens .*|ServerTokens Prod|' \
        -e 's|^ServerSignature .*|ServerSignature Off|' \
        -e 's|^#ServerName .*|ServerName localhost|' \
        /etc/apache2/httpd.conf \
    && printf '%s\n' \
        '<Directory "/var/www/dashboard/config">' '    Require all denied' '</Directory>' \
        '<FilesMatch "^\.">' '    Require all denied' '</FilesMatch>' \
        > /etc/apache2/conf.d/dashboard.conf \
    && grep -q 'DocumentRoot "/var/www/dashboard"' /etc/apache2/httpd.conf \
    && chown -R apache:apache /var/www/dashboard/config

## served under a path behind a proxy (DASHBOARD_PATH, e.g. /ysfreflector/): make the canonical / social
## urls include it instead of claiming the site root; fails the build if upstream changed that line
RUN sed -i "s|return \$scheme \. '://' \. \$host \. '/';|return \$scheme . '://' . \$host . (defined(\"DASHBOARD_BASE_PATH\") ? DASHBOARD_BASE_PATH : '/');|" \
        /var/www/dashboard/include/seo.php \
    && grep -q 'DASHBOARD_BASE_PATH' /var/www/dashboard/include/seo.php

COPY --chmod=755 run.sh /usr/local/bin/run.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/run.sh"]
