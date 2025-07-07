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

## testing xlxconfig update
cp ${XLXCONFIG} /tmp
_TMPXLX=/tmp/config.inc.php

# configure dashboard
if [ ! -z ${CALLSIGN:-} ]; then
  sed -i "s/\(PageOptions\['MetaAuthor'\][[:blank:]]*\=[[:blank:]]*\)'\([[:alnum:]]*\)'/\1\'${CALLSIGN}\'/g" ${_TMPXLX} # callsign

fi

if [ ! -z ${EMAIL:-} ]; then
  sed -i "s/\(PageOptions\['ContactEmail'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${EMAIL}\'/g" ${_TMPXLX} # email address

fi

sed -i "s/\(CallingHome\['Country'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${COUNTRY} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${_TMPXLX} # country
sed -i "s/\(CallingHome\['Comment'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${_TMPXLX} # description
sed -i "s/\(PageOptions\['MetaDescription'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${COMMENT} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${_TMPXLX} # comment
sed -i "s/\(CallingHome\['MyDashBoardURL'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'http:\/\/${URL}:${PORT}\/\'/g" ${_TMPXLX} # URL
sed -i "s/\(CallingHome\['Active'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${CALLHOME}/g" ${_TMPXLX} # call home active
sed -i "s/\(PageOptions\['NumberOfModules'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${MODULES}/g" ${_TMPXLX} # number of modules
sed -i "s/\(CallingHome\['HashFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"\/xlxd\/callinghome.php\"/g" ${_TMPXLX}
sed -i "s/\(CallingHome\['LastCallHomefile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"\/xlxd\/lastcallhome.php\"/g" ${_TMPXLX} # move callinghome file to /xlxd
sed -i "s/\(PageOptions\['ModuleNames'\]\['A'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEA}\'/g" ${_TMPXLX} # name module A
sed -i "s/\(PageOptions\['ModuleNames'\]\['B'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEB}\'/g" ${_TMPXLX} # name module B
sed -i "s/\(PageOptions\['ModuleNames'\]\['C'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEC}\'/g" ${_TMPXLX} # name module C
sed -i "s/\(PageOptions\['ModuleNames'\]\['D'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULED}\'/g" ${_TMPXLX} # name module D
sed -i "s/\(PageOptions\['ModuleNames'\]\['E'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEE}\'/g" ${_TMPXLX} # name module E
sed -i "s/\(PageOptions\['RepeatersPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${_TMPXLX} # Hide IP addresses on repeaters page
sed -i "s/\(PageOptions\['PeerPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${_TMPXLX} # Hide IP addresses on peer page
sed -i "s/\(PageOptions\['CustomTXT'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')'/g" ${_TMPXLX}
sed -i "s/\(PageOptions\['IRCDDB'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1false/g" ${_TMPXLX}
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/peers.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/repeaters.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/traffic.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${XLXD_WEB_DIR}/pgs/users.php # convert date format to US

## testing xlxconfig update
cp ${_TMPXLX} ${XLXCONFIG}

# set timezone
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

sed -i "s/ServerAdmin you@example.com/ServerAdmin ${EMAIL}/g" /etc/apache2/httpd.conf
sed -i "s/ServerSignature On/ServerSignature Off/g" /etc/apache2/httpd.conf
sed -i "s/#ServerName www.example.com:80/ServerName ${URL}:80/g" /etc/apache2/httpd.conf
sed -i "s/\/var\/www\/localhost\/htdocs/\/var\/www\/xlxd/g" /etc/apache2/httpd.conf
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/apache2/httpd.conf
chown -R apache:apache /var/www
##find /var/www/xlxd/ -name '*.php' -exec dos2unix {} \;

touch /.firstRunComplete
echo "xlxd first run setup complete"
