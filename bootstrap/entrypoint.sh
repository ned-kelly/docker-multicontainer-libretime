#!/bin/bash
AIRTIME_CONFIG_FILE="/etc/airtime/airtime.conf"
AIRTIME_APACHE_CONFIG="/etc/apache2/sites-enabled/airtime.conf"

# Script that is executed to apply further customizations to airtime.
CUSTOMISATIONS_SCRIPT="/etc/airtime-customisations/run.sh"

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

function apacheFixes() {

    if ! grep -q 'BEGIN:LOCALHOSTFIX--' "$AIRTIME_APACHE_CONFIG"
    then

        # Add in a "Substitute" filter to apache to strip out localhost references on the fly...
        sed -i 's^.*</VirtualHost>.*^  # Quick fix for iframes that reference hard coded localhost in paths.\n  # BEGIN:LOCALHOSTFIX--\n   <Location "/">\n      SetOutputFilter SUBSTITUTE;DEFLATE\n      AddOutputFilterByType SUBSTITUTE text/html\n      Substitute "s|http://localhost//|/|ni"\n      Substitute "s|https://localhost//|/|ni"\n      Substitute "s|http://localhost/|/|ni"\n      Substitute "s|https://localhost/|/|ni"\n  </Location>\n&^' "$AIRTIME_APACHE_CONFIG"

        a2enmod substitute
    fi

    if ! grep -q "$EXTERNAL_HOSTNAME" "$AIRTIME_APACHE_CONFIG"
    then
        # Fix localhost on "Radio Embed Page"
        sed -i 's^.*</Location>.*^ Substitute "s|http:\\/\\/localhost:8000|http:\\/\\/'"$EXTERNAL_HOSTNAME"'|ni"\n&^' "$AIRTIME_APACHE_CONFIG"
    fi

}

function customisations() {
    if [ -f "$CUSTOMISATIONS_SCRIPT" ]; then
        bash "$CUSTOMISATIONS_SCRIPT" 
    fi
}

if [ ! -f "$AIRTIME_CONFIG_FILE" ]; then
    echo "Prepping libretime for first run..."

    # If this is the first time the container's started run the config scripts to setup the configuration files.
    /opt/libretime/firstrun.sh

    # update config based on environment variables...
    setConfigFromEnvironments && apacheFixes && customisations

    # Start everything up :)
    /usr/bin/supervisord
else
    # Check (and update if required) any config based on environment variables..
    setConfigFromEnvironments && apacheFixes && customisations

    # We're already installed - just run supervisor..
    /usr/bin/supervisord
fi
