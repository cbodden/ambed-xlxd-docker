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
sed -i "s/\(PageOptions\['MetaDescription'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${COMMENT} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${XLXCONFIG} # comment
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
sed -i "s/\(PageOptions\['RepeatersPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${XLXCONFIG} # Hide IP addresses on repeaters page
sed -i "s/\(PageOptions\['PeerPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${XLXCONFIG} # Hide IP addresses on peer page
sed -i "s/\(PageOptions\['CustomTXT'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')'/g" ${XLXCONFIG}
sed -i "s/\(PageOptions\['IRCDDB'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1false/g" ${XLXCONFIG}
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
