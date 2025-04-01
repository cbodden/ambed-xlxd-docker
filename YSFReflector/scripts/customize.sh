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

# edit apache for host
sed -i "s/ServerAdmin you@example.com/ServerAdmin ${EMAIL}/g" /etc/apache2/httpd.conf
sed -i "s/ServerSignature On/ServerSignature Off/g" /etc/apache2/httpd.conf
sed -i "s/#ServerName www.example.com:80/ServerName ${URL}:80/g" /etc/apache2/httpd.conf
sed -i "s/\/var\/www\/localhost\/htdocs/\/var\/www\/html/g" /etc/apache2/httpd.conf
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.php/g" /etc/apache2/httpd.conf

# make sure www is owned by www
chown -R apache:apache /var/www
chmod -R 775 /var/www/html

# remove file weirdness
find /var/www/html/ -name '*.php' -exec dos2unix {} \;

touch /.firstRunComplete
echo "YSFReflector first run setup complete"
