#!/bin/bash
AIRTIME_CONFIG_FILE="/etc/airtime/airtime.conf"

# Airtime seems to expect the hostname of 'airtime' to be set to properly function...
echo "127.0.0.1 airtime libretime" >> /etc/hosts

function setConfigFromEnvironments {

    # RabbitMQ
    crudini --set "$AIRTIME_CONFIG_FILE" "rabbitmq" "host" "libretime-rabbitmq"
    crudini --set "$AIRTIME_CONFIG_FILE" "rabbitmq" "user" "$RABBITMQ_DEFAULT_USER"
    crudini --set "$AIRTIME_CONFIG_FILE" "rabbitmq" "password" "$RABBITMQ_DEFAULT_PASS"
    crudini --set "$AIRTIME_CONFIG_FILE" "rabbitmq" "vhost" "$RABBITMQ_DEFAULT_VHOST"

    # PostgreSQL
    crudini --set "$AIRTIME_CONFIG_FILE" "database" "host" "libretime-postgres"
    crudini --set "$AIRTIME_CONFIG_FILE" "database" "dbname" "$POSTGRES_DB_NAME"
    crudini --set "$AIRTIME_CONFIG_FILE" "database" "dbuser" "$POSTGRES_USER"
    crudini --set "$AIRTIME_CONFIG_FILE" "database" "dbpass" "$POSTGRES_PASSWORD"

    # AWS S3 Config
    crudini --set "$AIRTIME_CONFIG_FILE" "amazon_S3" "api_key" "$AWS_S3_API_KEY"
    crudini --set "$AIRTIME_CONFIG_FILE" "amazon_S3" "api_key_secret" "$AWS_S3_API_SECRET"
    crudini --set "$AIRTIME_CONFIG_FILE" "amazon_S3" "bucket" "$AWS_S3_BUCKET_NAME"

    # Make sure the file is owned by the corect user...
    chown www-data:www-data "$AIRTIME_CONFIG_FILE"

    # Make sure we can write to the config directory
    chmod 777 /etc/airtime/
}

if [ ! -f "$AIRTIME_CONFIG_FILE" ]; then
    echo "Prepping libretime for first run..."

    # If this is the first time the container's started run the config scripts to setup the configuration files.
    /opt/libretime/firstrun.sh

    # update config based on environment variables...
    setConfigFromEnvironments

    # Start everything up :)
    /usr/bin/supervisord
else
    # Check (and update if required) any config based on environment variables..
    setConfigFromEnvironments

    # We're already installed - just run supervisor..
    /usr/bin/supervisord
fi
