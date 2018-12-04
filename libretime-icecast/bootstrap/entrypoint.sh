#!/bin/sh

#### CONFIGURE EZSTREAM ####

if [ -n "$ICECAST_PORT" ]; then
    sed -i "s/<url>[^<]*<\/url>/<url>http:\/\/localhost:$ICECAST_PORT\/fallback<\/url>/g" /etc/ezstream_mp3.xml
fi
if [ -n "$ICECAST_SOURCE_PASSWORD" ]; then
    sed -i "s/<sourcepassword>[^<]*<\/sourcepassword>/<sourcepassword>$ICECAST_SOURCE_PASSWORD<\/sourcepassword>/g" /etc/ezstream_mp3.xml
fi
if [ -n "$WEBSITE_HOMEPAGE" ]; then
    sed -i "s/<svrinfourl>[^<]*<\/svrinfourl>/<svrinfourl>$WEBSITE_HOMEPAGE<\/svrinfourl>/g" /etc/ezstream_mp3.xml
fi

#### CONFIGURE ICECAST ####

if [ -n "$ICECAST_PORT" ]; then
    sed -i "s/<port>[^<]*<\/port>/<port>$ICECAST_PORT<\/port>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_SOURCE_PASSWORD" ]; then
    sed -i "s/<source-password>[^<]*<\/source-password>/<source-password>$ICECAST_SOURCE_PASSWORD<\/source-password>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_RELAY_PASSWORD" ]; then
    sed -i "s/<relay-password>[^<]*<\/relay-password>/<relay-password>$ICECAST_RELAY_PASSWORD<\/relay-password>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_ADMIN_PASSWORD" ]; then
    sed -i "s/<admin-password>[^<]*<\/admin-password>/<admin-password>$ICECAST_ADMIN_PASSWORD<\/admin-password>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_ADMIN_USERNAME" ]; then
    sed -i "s/<admin-user>[^<]*<\/admin-user>/<admin-user>$ICECAST_ADMIN_USERNAME<\/admin-user>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_ADMIN_EMAIL" ]; then
    sed -i "s/<admin>[^<]*<\/admin>/<admin>$ICECAST_ADMIN_EMAIL<\/admin>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_LOCATION" ]; then
    sed -i "s/<location>[^<]*<\/location>/<location>$ICECAST_LOCATION<\/location>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_HOSTNAME" ]; then
    sed -i "s/<hostname>[^<]*<\/hostname>/<hostname>$ICECAST_HOSTNAME<\/hostname>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_MAX_CLIENTS" ]; then
    sed -i "s/<clients>[^<]*<\/clients>/<clients>$ICECAST_MAX_CLIENTS<\/clients>/g" /etc/icecast.xml
fi
if [ -n "$ICECAST_MOUNT_NAME" ]; then
    sed -i "s/<mount-name>[^<]*<\/mount-name>/<mount-name>$ICECAST_MOUNT_NAME<\/mount-name>/g" /etc/icecast.xml
fi

# Redirects the icecast root to your website homepage...
if [ -n "$WEBSITE_HOMEPAGE" ]; then
    sed -i "s/\/status.xsl/$WEBSITE_HOMEPAGE/g" /etc/icecast.xml
fi

# Run playlist builder -- NB your libretime media directory needs to be mapped into this container to work - otherwise by default we will fallback to 3-4 CC media tracks...
/playlist-builder.sh

# Start everything up :)
/usr/bin/supervisord -c "/etc/supervisor/supervisord.conf"
