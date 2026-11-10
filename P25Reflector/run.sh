#!/bin/sh
## write P25Reflector.ini from the environment, refresh the id list, run in the foreground
## (a P25 reflector has no number of its own - that lives in the host lists and in xlxd.interlink)
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

need_int "${P25_PORT}" 1 65535 P25_PORT
need_int "${P25_ID_RELOAD}" 0 8760 P25_ID_RELOAD # hours, 0 = never reload
need_int "${P25_LOG_LEVEL}" 0 6 P25_LOG_LEVEL    # 1 = debug .. 6 = fatal only, 0 = off
need_int "${P25_DEBUG}" 0 1 P25_DEBUG

## id list (P25 radios use DMR ids) - only used to show callsigns in the log
if curl -fsSL -m 60 -o DMRIds.dat.new "${P25_ID_URL}"; then
  mv DMRIds.dat.new DMRIds.dat
else
  rm -f DMRIds.dat.new
  echo "WARNING : could not download ${P25_ID_URL} - using the bundled id list"
  cp /usr/local/share/p25/DMRIds.dat DMRIds.dat
fi

cat > P25Reflector.ini <<EOF
[General]
Daemon=0

[Id Lookup]
Name=/p25/DMRIds.dat
Time=${P25_ID_RELOAD}

[Log]
DisplayLevel=${P25_LOG_LEVEL}
FileLevel=0
FilePath=/p25
FileRoot=P25Reflector
FileRotate=0

[Network]
Port=${P25_PORT}
Debug=${P25_DEBUG}
EOF

echo "P25Reflector : UDP ${P25_PORT}"
exec /usr/local/bin/P25Reflector /p25/P25Reflector.ini
