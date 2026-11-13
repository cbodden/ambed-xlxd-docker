# syntax=docker/dockerfile:1-labs
## ysfreflector
## IU5JAE's pYSFReflector3 (G4KLX's YSFReflector was removed from YSFClients in Feb 2023).
## xlxd peers it onto one XLX module; YSF hotspots / radios connect to it like any YSF reflector.
FROM mirror.gcr.io/library/alpine:latest

ARG PYSF_GIT_REF=8a9dbd755c45872d14f5a8bd1a22245d24bf7755

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
## runtime settings - see README
ENV YSF_NAME="" YSF_DESCRIPTION="" YSF_ID="0" YSF_CONTACT="" YSF_WEB="" \
    YSF_PORT="42000" YSF_JSON_PORT="42223" \
    YSF_DGID_LIST="1,9,50" YSF_DGID_DEFAULT="50" YSF_DGID_LOCAL="1" \
    YSF_TIMEOUT="190" YSF_CHECK_CALLSIGN="on" \
    YSF_APRS="off" YSF_APRS_SERVER="rotate.aprs2.net" YSF_APRS_PORT="14580" YSF_APRS_SSID="-10" \
    YSF_LOG_LEVEL="1" YSF_LOG_KEEP_DAYS="7"

RUN apk add --no-cache python3 py3-pip tzdata \
    && pip install --no-cache-dir --break-system-packages tinydb aprslib \
    && adduser -D -H -s /sbin/nologin mmdvm \
    && mkdir -p /usr/local/lib/pysfreflector /usr/local/share/pysfreflector /opt/pysfreflector /var/log/ysfreflector \
    && chown mmdvm:mmdvm /opt/pysfreflector /var/log/ysfreflector

ADD https://github.com/iu5jae/pYSFReflector3.git#${PYSF_GIT_REF} /src/pysf

RUN cp /src/pysf/YSFReflector /src/pysf/*.py /usr/local/lib/pysfreflector/ \
    && cp /src/pysf/deny.db /src/pysf/home.db /src/pysf/ACL_rules.txt /usr/local/share/pysfreflector/ \
    && chmod 755 /usr/local/lib/pysfreflector/YSFReflector \
    && rm -rf /src \
    && python3 -c "import sys; sys.path.insert(0, '/usr/local/lib/pysfreflector'); import ysffich, ysfpayload, ysfutils, gps, ysfaprs, tinydb, aprslib"

COPY --chmod=755 run.sh /usr/local/bin/run.sh

## /opt/pysfreflector : dg-id memory, home db, deny list (deny.db / home.db are seeded on first start - edit deny.db to block calls)
## /var/log/ysfreflector : dated log files + YSFReflector.ini (for ysfdashboard2)
EXPOSE 42000/udp
USER mmdvm
WORKDIR /opt/pysfreflector
ENTRYPOINT ["/usr/local/bin/run.sh"]
