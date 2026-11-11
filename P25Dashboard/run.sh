#!/bin/sh
## shared by nxdndashboard / p25dashboard / ysfdashboard2 (DASH_KIND=NXDN|P25|YSF): write the dashboard's config/config.php
## from the environment (instead of its setup wizard), point apache at it, run apache in the foreground
set -eu
KIND=${DASH_KIND}
WEB=/var/www/dashboard
LOGDIR=/var/log/$(echo "${KIND}" | tr 'A-Z' 'a-z')reflector

## on/off -> true/false (bad value: warn, use default) : bool <value> <default true|false> <name>
bool() {
  case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
    on|true|enable|enabled|yes|1)    echo true ;;
    off|false|disable|disabled|no|0) echo false ;;
    "")                              echo "$2" ;;
    *) echo "WARNING : $3='$1' is not on/off - using $2" >&2; echo "$2" ;;
  esac
}
## whole number in [min, max] (bad value: warn, use default) : int <value> <default> <min> <max> <name>
int() {
  case "$1" in
    "") echo "$2"; return ;;
    *[!0-9]*) echo "WARNING : $5='$1' is not a whole number - using $2" >&2; echo "$2"; return ;;
  esac
  if [ "$1" -lt "$3" ] || [ "$1" -gt "$4" ]; then
    echo "WARNING : $5='$1' is outside $3-$4 - using $2" >&2; echo "$2"; return
  fi
  echo "$1"
}
## text for a php "..." string (the dashboard html-escapes it when it prints it) : txt <value>
txt() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g; s/"/\\"/g; s/\$/\\$/g'
}

PORT=$(int "${DASHBOARD_PORT:-}" 80 1 65535 DASHBOARD_PORT)
## public path when served under a proxy prefix, e.g. /nxdnreflector/ (only used for canonical urls)
BASEPATH=${DASHBOARD_PATH:-/}
case "${BASEPATH}" in
  /|/*/) ;;
  /*) BASEPATH="${BASEPATH}/" ;;
  *) BASEPATH="/${BASEPATH%/}/" ;;
esac
case "${BASEPATH}" in
  *[!A-Za-z0-9/_.-]*) echo "WARNING : DASHBOARD_PATH='${DASHBOARD_PATH}' has odd characters - using /" >&2; BASEPATH=/ ;;
esac
TZ_NAME=${TZ:-UTC}
[ -e "/usr/share/zoneinfo/${TZ_NAME}" ] || { echo "WARNING : TZ='${TZ_NAME}' unknown - using UTC" >&2; TZ_NAME=UTC; }

cat > "${WEB}/config/config.php" <<EOF
<?php
/**
 * ${KIND}Reflector-Dashboard2 configuration - written by the container at start from its environment
 */

// the reflector's log lines and dated file names are UTC: php parses them in UTC, TIMEZONE is only for display
date_default_timezone_set('UTC');

define("${KIND}REFLECTORLOGPATH", "${LOGDIR}/");
define("${KIND}REFLECTORLOGPREFIX", "${KIND}Reflector");
define("${KIND}REFLECTORINIPATH", "${LOGDIR}/");
define("${KIND}REFLECTORINIFILENAME", "${KIND}Reflector.ini");
define("${KIND}REFLECTORPATH", "/usr/local/bin/");
define("TIMEZONE", "${TZ_NAME}");
define("DASHBOARD_BASE_PATH", "${BASEPATH}");
define("LOGO", "$(txt "${DASHBOARD_LOGO:-}")");
define("REFRESHAFTER", "15");
define("SHOWOLDMHEARD", "$(int "${SHOW_OLD_MHEARD:-}" 7 1 365 SHOW_OLD_MHEARD)");
define("TEMPERATUREHIGHLEVEL", "60");
define("DASHBOARD_NAME", "$(txt "${DASHBOARD_NAME:-${KIND} Reflector Dashboard}")");
define("DASHBOARD_TAGLINE", "$(txt "${DASHBOARD_TAGLINE:-}")");
define("SHOWPROGRESSBARS", $(bool "${SHOW_PROGRESS_BARS:-}" true SHOW_PROGRESS_BARS));
define("TEMPERATUREALERT", false);
define("SHOWQRZ", $(bool "${SHOW_QRZ:-}" false SHOW_QRZ));
define("GDPR", $(bool "${GDPR:-}" false GDPR));
define("LAST_HEARD_FIRST", $(bool "${LAST_HEARD_FIRST:-}" false LAST_HEARD_FIRST));
define("SHOW_SYSTEM_INFO", $(bool "${SHOW_SYSTEM_INFO:-}" false SHOW_SYSTEM_INFO));
?>
EOF

sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/httpd.conf
mkdir -p /run/apache2

[ -d "${LOGDIR}" ] && ls "${LOGDIR}"/"${KIND}"Reflector-*.log > /dev/null 2>&1 \
  || echo "WARNING : no ${KIND}Reflector log files in ${LOGDIR} yet - share the reflector's log volume$([ "${KIND}" = YSF ] || echo " and turn on ${KIND}_LOG_FILE") (normal for a few seconds after a fresh start)"

echo "${KIND}Reflector-Dashboard2 on port ${PORT} (public path ${BASEPATH}), reading ${LOGDIR}"
exec httpd -D FOREGROUND
