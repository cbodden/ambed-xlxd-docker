#!/command/with-contenv bash

### Use environment variables to configure services

# If the first run completed successfully, we are done
if [ -e /.firstRunComplete ]; then
    exit 0

fi

# Make sure environment variables are set
if [ -z ${ID:-} ]; then
    echo "ID not set"
    echo "Register your YSFReflector at: https://register.ysfreflector.de for an ID"
    exit 1

fi

# reflector name && description
if [ "${NAME}" == "NAME" ]
then
    echo "Please set NAME variable (max 16 characters)"
    exit 1
fi

if [ ${#NAME} -gt 16 ]
then
    echo "NAME variable can be at most 16 characters"
    exit 1
fi

if [ "${DESCRIPTION}" == "DESCRIPTION" ]
then
    echo "Please set DESCRIPTION variable (min 14 characters)"
    exit 1
fi

if [ ${#DESCRIPTION} -gt 14 ]
then
    echo "DESCRIPTION variable can be at most 14 characters"
    exit 1
fi

# disable daemon
sed -i "s/Daemon=1/Daemon=0/g" /YSFReflector/YSFReflector.ini

# reflector name and description replacement
sed -i "s/Description=.*/Description=${DESCRIPTION}/g" /YSFReflector/YSFReflector.ini
sed -i "s/# Id=5 digits only/ID=${ID}/g" /YSFReflector/YSFReflector.ini
sed -i "s/Name=.*/Name=${NAME}/g" /YSFReflector/YSFReflector.ini
sed -i "s/Port=.*/Port=42000/g" /YSFReflector/YSFReflector.ini

# logging
mkdir -p /YSFReflector/logs
mkdir -p /var/www/html/config
sed -i "s/FilePath=.*/FilePath=\/var\/log\//g" /YSFReflector/YSFReflector.ini

# generate config.php
cat << EOF > /var/www/html/config/config.php
<?php
date_default_timezone_set('UTC');
define("YSFREFLECTORLOGPATH", "/var/log");
define("YSFREFLECTORLOGPREFIX", "YSFReflector");
define("YSFREFLECTORINIPATH", "/YSFReflector/");
define("YSFREFLECTORINIFILENAME", "YSFReflector.ini");
define("YSFREFLECTORPATH", "/YSFReflector/");
define("TIMEZONE", "UTC");
define("LOGO", "");
define("REFRESHAFTER", "60");
define("SHOWPROGRESSBARS", "on");
define("SHOWOLDMHEARD", "60");
define("TEMPERATUREHIGHLEVEL", "60");
define("SHOWQRZ", "on");
?>
EOF

# make sure www is owned by www
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

# generate virtual host
cat << EOF > /etc/apache2/sites-available/${URL}.conf
<VirtualHost *:${WEB_PORT}>
    ServerName ${URL}
    DocumentRoot /var/www/html
</VirtualHost>
EOF

# Configure httpd
echo "Listen ${WEB_PORT}" >/etc/apache2/ports.conf
echo "ServerName ${URL}" >> /etc/apache2/apache2.conf

# disable default site(s)
a2dissite *default >/dev/null 2>&1

# enable YSFDashboard dashboard
a2ensite ${URL} >/dev/null 2>&1

touch /.firstRunComplete
echo "YSFReflector first run setup complete"
