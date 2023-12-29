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

if [ "${PORT}" == "PORT" ]
then
    echo "Please set PORT variable (range 42000-42010)"
    exit 1
fi

# disable daemon
sed -i "s/Daemon=1/Daemon=0/g" /YSFReflector/YSFReflector.ini

# reflector name and description replacement
sed -i "s/Description=.*/Description=${DESCRIPTION}/g" /YSFReflector/YSFReflector.ini
sed -i "s/# Id=5 digits only/ID=${ID}/g" /YSFReflector/YSFReflector.ini
sed -i "s/Name=.*/Name=${NAME}/g" /YSFReflector/YSFReflector.ini
sed -i "s/Port=.*/Port=42000/g" /YSFReflector/YSFReflector.ini

touch /.firstRunComplete
echo "YSFReflector first run setup complete"
