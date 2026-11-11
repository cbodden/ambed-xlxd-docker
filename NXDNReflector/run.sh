#!/bin/sh
## write NXDNReflector.ini from the environment, refresh the NXDN id list, run in the foreground
set -eu

## whole number in [min, max] or exit : need_int <value> <min> <max> <name>
need_int() {
  case "$1" in
    ""|*[!0-9]*) echo "ERROR : $4='$1' must be a whole number ($2-$3)"; exit 1 ;;
  esac
  if [ "$1" -lt "$2" ] || [ "$1" -gt "$3" ]; then
    echo "ERROR : $4='$1' is outside $2-$3"; exit 1
  fi
}

need_int "${NXDN_TG}" 1 65535 NXDN_TG              # the reflector's number / talkgroup
need_int "${NXDN_PORT}" 1 65535 NXDN_PORT
need_int "${NXDN_ID_RELOAD}" 0 8760 NXDN_ID_RELOAD # hours, 0 = never reload
need_int "${NXDN_LOG_LEVEL}" 0 6 NXDN_LOG_LEVEL    # 1 = debug .. 6 = fatal only, 0 = off
need_int "${NXDN_DEBUG}" 0 1 NXDN_DEBUG

## optional log files (for nxdndashboard): dated files + a copy of the ini in /var/log/nxdnreflector
LOGDIR=/var/log/nxdnreflector
case "$(printf '%s' "${NXDN_LOG_FILE:-off}" | tr 'A-Z' 'a-z')" in
  on|true|enable|enabled|yes|1)
    need_int "${NXDN_LOG_FILE_LEVEL:-2}" 1 6 NXDN_LOG_FILE_LEVEL
    need_int "${NXDN_LOG_KEEP_DAYS:-7}" 1 3650 NXDN_LOG_KEEP_DAYS
    FILELEVEL=${NXDN_LOG_FILE_LEVEL:-2}
    find "${LOGDIR}" -name 'NXDNReflector-*.log' -mtime +"${NXDN_LOG_KEEP_DAYS:-7}" -delete 2> /dev/null || true
    # prune once a day while running (the reflector exec's below, this keeps going alongside it)
    ( while sleep 86400; do
        find "${LOGDIR}" -name 'NXDNReflector-*.log' -mtime +"${NXDN_LOG_KEEP_DAYS:-7}" -delete 2> /dev/null
      done ) &
    ;;
  *) FILELEVEL=0 ;;
esac

## id list - only used to show callsigns in the log
if curl -fsSL -m 60 -o NXDN.csv.new "${NXDN_ID_URL}"; then
  mv NXDN.csv.new NXDN.csv
else
  rm -f NXDN.csv.new
  echo "WARNING : could not download ${NXDN_ID_URL} - using the bundled id list"
  cp /usr/local/share/nxdn/NXDN.csv NXDN.csv
fi

cat > NXDNReflector.ini <<EOF
[General]
TG=${NXDN_TG}
Daemon=0

[Id Lookup]
Name=/nxdn/NXDN.csv
Time=${NXDN_ID_RELOAD}

[Log]
DisplayLevel=${NXDN_LOG_LEVEL}
FileLevel=${FILELEVEL}
FilePath=${LOGDIR}
FileRoot=NXDNReflector
FileRotate=1

[Network]
Port=${NXDN_PORT}
Debug=${NXDN_DEBUG}

[Icom Network]
Enabled=0
Address=flicom.nxcore.org
Debug=0

[Kenwood Network]
Enabled=0
Address=flkenwood.nxcore.org
Debug=0
EOF

## the dashboard reads the ini next to the logs
[ "${FILELEVEL}" -gt 0 ] && cp NXDNReflector.ini "${LOGDIR}/NXDNReflector.ini"

echo "NXDNReflector : TG ${NXDN_TG} on UDP ${NXDN_PORT}$([ "${FILELEVEL}" -gt 0 ] && echo ", log files in ${LOGDIR}")"
exec /usr/local/bin/NXDNReflector /nxdn/NXDNReflector.ini
