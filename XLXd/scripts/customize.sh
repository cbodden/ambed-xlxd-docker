#!/command/with-contenv bash

### Use environment variables to configure services

# If the first run completed successfully, we are done
if [ -e /.firstRunComplete ]; then
  exit 0

fi

# Make sure environment variables are set
if [ -z ${URL:-} ]; then
  echo "URL not set"
  exit 1

fi

# configure dashboard
if [ ! -z ${CALLSIGN:-} ]; then
  sed -i "s/\(PageOptions\['MetaAuthor'\][[:blank:]]*\=[[:blank:]]*\)'\([[:alnum:]]*\)'/\1\'${CALLSIGN}\'/g" ${XLXCONFIG} # callsign

fi

if [ ! -z ${EMAIL:-} ]; then
  sed -i "s/\(PageOptions\['ContactEmail'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${EMAIL}\'/g" ${XLXCONFIG} # email address

fi

sed -i "s/\(CallingHome\['Country'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${COUNTRY} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${XLXCONFIG} # country
sed -i "s/\(CallingHome\['Comment'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${XLXCONFIG} # description
if [ ! -z "${COMMENT:-}" ]; then
  # MetaDescription is single quoted in the dashboard config
  sed -i "s/\(PageOptions\['MetaDescription'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'$(printf '%s' "${COMMENT}" | sed 's/[\/&]/\\&/g')'/g" ${XLXCONFIG} # comment

fi
sed -i "s/\(CallingHome\['MyDashBoardURL'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'http:\/\/${URL}:${PORT}\/\'/g" ${XLXCONFIG} # URL
sed -i "s/\(CallingHome\['Active'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${CALLHOME}/g" ${XLXCONFIG} # call home active
sed -i "s/\(PageOptions\['NumberOfModules'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${MODULES}/g" ${XLXCONFIG} # number of modules
sed -i "s/\(CallingHome\['HashFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"\/xlxd\/callinghome.php\"/g" ${XLXCONFIG}
sed -i "s/\(CallingHome\['LastCallHomefile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"\/xlxd\/lastcallhome.php\"/g" ${XLXCONFIG} # move callinghome file to /xlxd
# name modules A-Z from MODULEA..MODULEZ - replace the line if the dashboard config has one, else add it after the last module name
for MOD in {A..Z}; do
  [ "${MOD}" = "S" ] && continue # MODULES is the module count, not module S's name
  VAR="MODULE${MOD}"
  [ -z "${!VAR+set}" ] && continue
  NAME=$(printf '%s' "${!VAR}" | sed 's/[\/&]/\\&/g') # escape for sed
  if grep -q "PageOptions\['ModuleNames'\]\['${MOD}'\]" ${XLXCONFIG}; then
    sed -i "s/\(PageOptions\['ModuleNames'\]\['${MOD}'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${NAME}\'/g" ${XLXCONFIG}
  else
    LAST=$(grep -n "PageOptions\['ModuleNames'\]" ${XLXCONFIG} | tail -1 | cut -d: -f1)
    sed -i "${LAST}a \$PageOptions['ModuleNames']['${MOD}']                     = '${NAME}';" ${XLXCONFIG}
  fi
done
sed -i "s/\(PageOptions\['CustomTXT'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')'/g" ${XLXCONFIG}

## dashboard switches - every default matches what the image did before they existed
. /etc/s6-overlay/scripts/dashboard-env.sh

IPMODUS=$(env_ipmodus "${IP_DISPLAY:-}") # repeaters / peers pages: how much of an IP to show
sed -i "s/\(PageOptions\['RepeatersPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'${IPMODUS}'/g" ${XLXCONFIG}
sed -i "s/\(PageOptions\['PeerPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'${IPMODUS}'/g" ${XLXCONFIG}

LIMIT=$(env_int "${LASTHEARD_LIMIT:-}" 39 1 999 LASTHEARD_LIMIT)
sed -i "s/\(PageOptions\['LastHeardPage'\]\['LimitTo'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${LIMIT}/g" ${XLXCONFIG}
LIMIT=$(env_int "${REPEATERS_LIMIT:-}" 99 1 999 REPEATERS_LIMIT)
sed -i "s/\(PageOptions\['RepeatersPage'\]\['LimitTo'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${LIMIT}/g" ${XLXCONFIG}
LIMIT=$(env_int "${PEERS_LIMIT:-}" 99 1 999 PEERS_LIMIT)
sed -i "s/\(PageOptions\['PeerPage'\]\['LimitTo'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${LIMIT}/g" ${XLXCONFIG}

REFRESH=$(env_int "${PAGE_REFRESH:-}" 10 0 3600 PAGE_REFRESH) # seconds, 0 = no auto-refresh
if [ "${REFRESH}" -eq 0 ]; then
  sed -i "s/\(PageOptions\['PageRefreshActive'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1false/g" ${XLXCONFIG}
else
  sed -i "s/\(PageOptions\['PageRefreshActive'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1true/g" ${XLXCONFIG}
  sed -i "s/\(PageOptions\['PageRefreshDelay'\][[:blank:]]*\=[[:blank:]]*\)'[[:digit:]]*'/\1'$((REFRESH * 1000))'/g" ${XLXCONFIG}
fi

SHOW=$(env_bool "${REFLECTORS_PAGE:-}" true REFLECTORS_PAGE)
sed -i "s/\(PageOptions\['ReflectorsPage'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${SHOW}/g" ${XLXCONFIG}
SHOW=$(env_bool "${TRAFFIC_PAGE:-}" false TRAFFIC_PAGE) # the vnstatd service reads TRAFFIC_PAGE too
sed -i "s/\(PageOptions\['Traffic'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${SHOW}/g" ${XLXCONFIG}
SHOW=$(env_bool "${IRCDDB_PAGE:-}" false IRCDDB_PAGE)
sed -i "s/\(PageOptions\['IRCDDB'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${SHOW}/g" ${XLXCONFIG}
if [ -n "${IRCDDB_URL:-}" ]; then
  # turn the shipped commented-out example into a live setting
  sed -i "s|^//[[:blank:]]*\(\$PageOptions\['IRCDDB'\]\['URL'\][[:blank:]]*=[[:blank:]]*\)'[^']*'|\1'$(printf '%s' "${IRCDDB_URL}" | sed 's/[|&]/\\&/g')'|" ${XLXCONFIG}
fi
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/peers.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/repeaters.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/traffic.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/users.php # convert date format to US
sed -i "s/alt=\"XLX Multiprotocol Gateway Reflector\"/alt=\"${XLXNUM}\"/" ${XLXD_WEB_DIR}/index.php # header image alt text

# set timezone
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

sed -i "s/ServerAdmin you@example.com/ServerAdmin ${EMAIL}/g" /etc/apache2/httpd.conf
sed -i "s/ServerSignature On/ServerSignature Off/g" /etc/apache2/httpd.conf
sed -i "s/#ServerName www.example.com:80/ServerName ${URL}:80/g" /etc/apache2/httpd.conf
sed -i "s/\/var\/www\/localhost\/htdocs/\/var\/www\/xlxd/g" /etc/apache2/httpd.conf
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/apache2/httpd.conf
chown -R apache:apache /var/www
find /var/www/xlxd/ -name '*.php' -exec dos2unix {} \;

touch /.firstRunComplete
echo "xlxd first run setup complete"
