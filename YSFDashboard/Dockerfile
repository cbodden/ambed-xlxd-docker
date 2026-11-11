# syntax=docker/dockerfile:1-labs
## ysfdashboard
## pYSFReflector3's own dashboard (IK5XMK's collector3 + php pages) for the ysfreflector image:
## the collector pulls the reflector's json feed (YSF_JSON_HOST:YSF_JSON_PORT) into sqlite, apache serves the pages
FROM alpine:latest

ARG PYSF_GIT_REF=8a9dbd755c45872d14f5a8bd1a22245d24bf7755

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
## runtime settings - see README
ENV DASHBOARD_PORT="80" YSF_JSON_HOST="ysfreflector" YSF_JSON_PORT="42223"

RUN apk add --no-cache apache2 php84 php84-apache2 php84-sqlite3 php84-ctype python3 tzdata

ADD https://github.com/iu5jae/pYSFReflector3.git#${PYSF_GIT_REF} /src/pysf

## pages + collector; the collector reads its reflector address from the environment, the pages use the
## bundled Yaesu image instead of a third-party http logo; fails the build if upstream moved either line
RUN mkdir -p /var/www/dashboard /usr/local/lib/collector3 /opt/pysfreflector \
    && cp /src/pysf/dashboard/php_pages/*.php /var/www/dashboard/ \
    && cp /src/pysf/dashboard/collector3/ID_Yaesu.jpg /var/www/dashboard/ \
    && cp /src/pysf/dashboard/collector3/collector3.py /usr/local/lib/collector3/ \
    && rm -rf /src \
    && sed -i "s|^srv_addr_port = ('127.0.0.1', 42223)\$|srv_addr_port = (os.environ.get('YSF_JSON_HOST', '127.0.0.1'), int(os.environ.get('YSF_JSON_PORT', '42223')))|" \
        /usr/local/lib/collector3/collector3.py \
    && grep -q "os.environ.get('YSF_JSON_HOST'" /usr/local/lib/collector3/collector3.py \
    && sed -i 's|<img src="http://xlx039.dmrbrescia.it/db/img/logo_bm2222.jpg" width="100" height="100" alt="BM2222">|<img src="./ID_Yaesu.jpg" width="100" height="100" alt="YSF">|' \
        /var/www/dashboard/main.php /var/www/dashboard/linked.php /var/www/dashboard/blocked.php \
    && ! grep -q 'xlx039.dmrbrescia.it' /var/www/dashboard/*.php \
    && chown -R apache:apache /opt/pysfreflector \
    && sed -i \
        -e 's|/var/www/localhost/htdocs|/var/www/dashboard|g' \
        -e 's|DirectoryIndex index.html|DirectoryIndex index.php|' \
        -e 's|^ErrorLog .*|ErrorLog /dev/stderr|' \
        -e 's|^\([[:blank:]]*\)CustomLog .*|\1CustomLog /dev/stdout combined|' \
        -e 's|^ServerTokens .*|ServerTokens Prod|' \
        -e 's|^ServerSignature .*|ServerSignature Off|' \
        -e 's|^#ServerName .*|ServerName localhost|' \
        /etc/apache2/httpd.conf \
    && grep -q 'DocumentRoot "/var/www/dashboard"' /etc/apache2/httpd.conf

COPY --chmod=755 run.sh /usr/local/bin/run.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/run.sh"]
