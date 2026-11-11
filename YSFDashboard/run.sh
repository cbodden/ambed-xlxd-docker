#!/bin/sh
## run pYSF3's collector (as apache, restarted if it exits) and serve the dashboard pages with apache
set -eu

PORT=${DASHBOARD_PORT:-80}
case "${PORT}" in ""|*[!0-9]*) echo "WARNING : DASHBOARD_PORT='${PORT}' - using 80" >&2; PORT=80 ;; esac
sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/httpd.conf
mkdir -p /run/apache2

## the collector keeps a sqlite db of streams / linked / blocked that the pages read
( while :; do
    su -p -s /bin/sh apache -c "cd /opt/pysfreflector && exec python3 -u /usr/local/lib/collector3/collector3.py" || true
    echo "collector3 exited - restarting in 10s"
    sleep 10
  done ) &

echo "pYSF3 dashboard on port ${PORT}, collecting from ${YSF_JSON_HOST}:${YSF_JSON_PORT}"
exec httpd -D FOREGROUND
