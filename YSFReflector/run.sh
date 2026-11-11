#!/bin/sh
## write pysfreflector.ini from the environment, seed the deny list, prune old logs, run pYSFReflector3 in the foreground
set -eu
DATA=/opt/pysfreflector
LOGDIR=/var/log/ysfreflector

## whole number in [min, max] or exit : need_int <value> <min> <max> <name>
need_int() {
  case "$1" in
    ""|*[!0-9]*) echo "ERROR : $4='$1' must be a whole number ($2-$3)"; exit 1 ;;
  esac
  if [ "$1" -lt "$2" ] || [ "$1" -gt "$3" ]; then
    echo "ERROR : $4='$1' is outside $2-$3"; exit 1
  fi
}
## on/off -> 1/0 or exit : need_bool <value> <name>
need_bool() {
  case "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" in
    on|true|enable|enabled|yes|1)    echo 1 ;;
    off|false|disable|disabled|no|0) echo 0 ;;
    *) echo "ERROR : $2='$1' must be on or off" >&2; exit 1 ;;
  esac
}
## cut to the registry's length limits : fit <value> <max> <name>
fit() {
  if [ "${#1}" -gt "$2" ]; then
    echo "WARNING : $3 is longer than $2 characters - cut to '$(printf '%s' "$1" | cut -c1-"$2")'" >&2
  fi
  printf '%s' "$1" | cut -c1-"$2"
}

[ -n "${YSF_NAME}" ] || { echo "ERROR : YSF_NAME is required (the reflector's registry name, 16 characters max)"; exit 1; }
NAME=$(fit "${YSF_NAME}" 16 YSF_NAME)
DESC=$(fit "${YSF_DESCRIPTION:-${YSF_NAME}}" 14 YSF_DESCRIPTION)
need_int "${YSF_ID}" 0 99999 YSF_ID
need_int "${YSF_PORT}" 1 65535 YSF_PORT
need_int "${YSF_JSON_PORT}" 1 65535 YSF_JSON_PORT
need_int "${YSF_DGID_DEFAULT}" 0 99 YSF_DGID_DEFAULT
need_int "${YSF_DGID_LOCAL}" 0 99 YSF_DGID_LOCAL
case "${YSF_DGID_LIST}" in
  *[!0-9,\ ]*|"") echo "ERROR : YSF_DGID_LIST='${YSF_DGID_LIST}' must be comma separated numbers"; exit 1 ;;
esac
need_int "${YSF_TIMEOUT}" 10 3600 YSF_TIMEOUT
need_int "${YSF_APRS_PORT}" 1 65535 YSF_APRS_PORT
need_int "${YSF_LOG_LEVEL}" 0 5 YSF_LOG_LEVEL
need_int "${YSF_LOG_KEEP_DAYS}" 1 3650 YSF_LOG_KEEP_DAYS
CHECKRE=$(need_bool "${YSF_CHECK_CALLSIGN}" YSF_CHECK_CALLSIGN)
APRS=$(need_bool "${YSF_APRS}" YSF_APRS)

## deny list / home db: seed them once, then they're the operator's (CS:call blocks a callsign, see ACL_rules.txt)
[ -e "${DATA}/deny.db" ] || cp /usr/local/share/pysfreflector/deny.db "${DATA}/deny.db"
[ -e "${DATA}/home.db" ] || cp /usr/local/share/pysfreflector/home.db "${DATA}/home.db"

## old dated logs
find "${LOGDIR}" -name 'YSFReflector-*.log' -mtime +"${YSF_LOG_KEEP_DAYS}" -delete 2> /dev/null || true
( while sleep 86400; do
    find "${LOGDIR}" -name 'YSFReflector-*.log' -mtime +"${YSF_LOG_KEEP_DAYS}" -delete 2> /dev/null
  done ) &

## pYSF3 only logs to its dated (UTC) file - follow today's file to stdout for docker logs, switching at midnight
( FROM=0
  while :; do
    timeout $(( 86400 - $(date -u +%s) % 86400 + 2 )) \
      tail -n "${FROM}" -F "${LOGDIR}/YSFReflector-$(date -u +%Y-%m-%d).log" 2> /dev/null
    FROM=+1
  done ) &

cat > "${DATA}/pysfreflector.ini" <<EOF
[General]
Daemon=0

[Info]
id=${YSF_ID}
Name=${NAME}
Description=${DESC}
Contact=${YSF_CONTACT}
Web=${YSF_WEB}

[Log]
FileLevel=${YSF_LOG_LEVEL}
FilePath=${LOGDIR}/
FileRoot=YSFReflector
FileRotate=1

[Network]
IP=0.0.0.0
Port=${YSF_PORT}
Json_IP=0.0.0.0
Json_Port=${YSF_JSON_PORT}
Debug=0

[Block List]
File=${DATA}/deny.db
Time=0.5
CheckRE=${CHECKRE}

[Protections]
Timeout = ${YSF_TIMEOUT}
WildPTTTime = 5
WildPTTCount = 4
Treactivate = 900

[APRS]
enable = ${APRS}
server = ${YSF_APRS_SERVER}
port = ${YSF_APRS_PORT}
ssid = ${YSF_APRS_SSID}

[DGID]
list = ${YSF_DGID_LIST}
default = ${YSF_DGID_DEFAULT}
local = ${YSF_DGID_LOCAL}
database = ${DATA}/dgid.json
home = ${DATA}/home.db
aux_port =
prefix = 1
bth_time = 900.0

[REFL_ALIAS]
refl_01 =
EOF

## id 0 = pYSF3 hashes the name like the registry does (its CalcID) - work it out too, for the dashboard / log
ID=${YSF_ID}
[ "${ID}" -ne 0 ] || ID=$(python3 -c '
import sys
u = 0
for a in sys.argv[1].strip().ljust(16):
    u = (u + ord(a)) & 0xFFFFFFFF
    u = (u + (u << 10) & 0xFFFFFFFF) & 0xFFFFFFFF
    u = (u ^ (u >> 6)) & 0xFFFFFFFF
u = (u + (u << 3) & 0xFFFFFFFF) & 0xFFFFFFFF
u = (u ^ (u >> 11)) & 0xFFFFFFFF
u = (u + (u << 15) & 0xFFFFFFFF) & 0xFFFFFFFF
print(u % 100000)' "${NAME}")

## ysfdashboard2 reads a G4KLX style YSFReflector.ini next to the logs (pysfreflector.ini's keys differ)
cat > "${LOGDIR}/YSFReflector.ini" <<EOF
[Info]
Id=${ID}
Name=${NAME}
Description=${DESC}

[Network]
Port=${YSF_PORT}
EOF

echo "pYSFReflector3 : '${NAME}' (id ${ID}) on UDP ${YSF_PORT}, json ${YSF_JSON_PORT}, DG-IDs ${YSF_DGID_LIST} (default ${YSF_DGID_DEFAULT})"
cd /usr/local/lib/pysfreflector
exec python3 -u ./YSFReflector "${DATA}/pysfreflector.ini"
