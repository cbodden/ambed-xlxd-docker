#!/command/with-contenv sh

PIDFILE="/var/log/xlxd.pid"
XMLFILE="/var/log/xlxd.xml"
IP=$( hostname -i )
AMBED=ambed

if [ -z ${XLXNUM:-} ]; then
  echo "XLXNUM is not set"
  exit 1
fi

# check for modified config files
cp -p /config/*.* ${XLXD_DIR}

# restore xml file to preserve historical data and allow dashboard to start immediately
cp -p /config/log/xlxd.xml ${XMLFILE}

# download the dmrid.dat from the XLXAPI server to the xlxd folder
curl -L -s -o ${XLXD_DIR}/dmrid.dat http://xlxapi.rlx.lu/api/exportdmr.php

# TODO: generate xlxd.interlink file

# Create pid file for service uptime dashboard class
touch ${PIDFILE}

# start daemon
exec /xlxd/xlxd ${XLXNUM} ${IP} ${AMBED}
