#!/bin/bash
AIRTIME_INSTALLED="/etc/airtime/airtime.conf"

# Airtime seems to expect the hostname of 'airtime' to be set to properly function...
echo "127.0.0.1 airtime libretime" >> /etc/hosts

if [ ! -f "$AIRTIME_INSTALLED" ]; then
    echo "Prepping libretime for first run..."

    # If this is the first time the container's started run the config scripts to setup the configuration files.
    /opt/libretime/firstrun.sh
else
    # We're already installed - just run supervisor..
    /usr/bin/supervisord
fi
