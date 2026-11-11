#!/command/with-contenv sh

PIDFILE="/var/log/xlxd.pid"
XMLFILE="/var/log/xlxd.xml"
IP=$( hostname -i )
AMBED=${AMBED:-ambed}

if [ -z ${XLXNUM:-} ]; then
  echo "XLXNUM is not set"
  exit 1
fi

# xlxd falls back to 0.0.0.0 (itself) when the transcoder host doesn't resolve - say so loudly
if ! echo "${AMBED}" | grep -qE '^[0-9.]+$' && ! getent hosts "${AMBED}" > /dev/null 2>&1; then
  echo "WARNING : AMBED host '${AMBED}' does not resolve - transcoding is disabled. set AMBED to the ambed service / container name"
fi

# check for modified config files
cp -p /config/*.* ${XLXD_DIR}

# optional NXDN / P25 / YSF reflector peers (e.g. the nxdnreflector / p25reflector / ysfreflector containers in the stack)
# NXDN_PEER / P25_PEER / YSF_PEER = "<number> <host>:<port> <module>", added to xlxd.interlink when *_PEER_ENABLED is on
. /etc/s6-overlay/scripts/dashboard-env.sh
INTERLINK="${XLXD_DIR}/xlxd.interlink"
touch "${INTERLINK}"
add_peer() { # <prefix NX|P25|YSF> <enabled> <"number host:port module"> <name>
  [ "$2" = "true" ] || return 0
  PREFIX=$1; NAME=$4; PEER=$3
  MAX=65535; [ "${PREFIX}" = "YSF" ] && MAX=99999 # NXDN / P25 ids are 16-bit, YSF registry ids 5 digits
  set -- ${PEER} # split the peer string
  if [ $# -ne 3 ]; then
    echo "WARNING : ${NAME}='${PEER}' needs '<number> <host>:<port> <module>' - not peering"; return 0
  fi
  NUM=$1; HOSTPORT=$2; MOD=$3
  case "${NUM}" in ""|*[!0-9]*) echo "WARNING : ${NAME} number '${NUM}' is not a number - not peering"; return 0 ;; esac
  if [ "${NUM}" -lt 1 ] || [ "${NUM}" -gt "${MAX}" ]; then
    echo "WARNING : ${NAME} number '${NUM}' is outside 1-${MAX} - not peering"; return 0
  fi
  case "${HOSTPORT}" in *?:[0-9]*) ;; *) echo "WARNING : ${NAME} '${HOSTPORT}' is not <host>:<port> - not peering"; return 0 ;; esac
  case "${MOD}" in [A-Z]) ;; *) echo "WARNING : ${NAME} module '${MOD}' is not A-Z - not peering"; return 0 ;; esac
  ID=$(printf '%s%05d' "${PREFIX}" "${NUM}")
  if grep -q "^${ID}[[:blank:]]" "${INTERLINK}"; then
    echo "${ID} is already in /config/xlxd.interlink - leaving it as is"; return 0
  fi
  echo "${ID} ${HOSTPORT} ${MOD}" >> "${INTERLINK}"
  echo "peering ${ID} ${HOSTPORT} on module ${MOD}"
}
add_peer NX "$(env_bool "${NXDN_PEER_ENABLED:-}" false NXDN_PEER_ENABLED)" "${NXDN_PEER:-}" NXDN_PEER
add_peer P25 "$(env_bool "${P25_PEER_ENABLED:-}" false P25_PEER_ENABLED)" "${P25_PEER:-}" P25_PEER
add_peer YSF "$(env_bool "${YSF_PEER_ENABLED:-}" false YSF_PEER_ENABLED)" "${YSF_PEER:-}" YSF_PEER

# restore xml file to preserve historical data and allow dashboard to start immediately
cp -p /config/log/xlxd.xml ${XMLFILE}

# download the dmrid.dat from the XLXAPI server to the xlxd folder
curl -L -s -o ${XLXD_DIR}/dmrid.dat http://xlxapi.rlx.lu/api/exportdmr.php

# TODO: generate xlxd.interlink file

# Create pid file for service uptime dashboard class
touch ${PIDFILE}

# start daemon
exec /xlxd/xlxd ${XLXNUM} ${IP} ${AMBED}
