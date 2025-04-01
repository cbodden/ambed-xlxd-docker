#!/command/with-contenv sh

# Make sure environment variables are set
if [ -z ${ID:-} ]; then
    echo "ID not set"
    echo "Register your YSFReflector at: https://register.ysfreflector.de for an ID"
    exit 1

fi

# check for modified config files
#cp -pv /config/*.* /YSFReflector/

# start daemon
exec /YSFReflector/YSFReflector /YSFReflector/YSFReflector.ini
