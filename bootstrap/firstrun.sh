#!/bin/bash

chmod 777 -R /etc/airtime/

service apache2 restart

# Wait a moment for apache to do it's thing..
sleep 5

# Configure (This is the same as running in the web-ui)
IP="127.0.0.1"

# Database - Variables are mapped in via Docker Compose environment variables...
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data "dbUser=$POSTGRES_USER&dbPass=$POSTGRES_PASSWORD&dbName=$POSTGRES_DB_NAME&dbHost=libretime-postgres&dbErr=" \
     "http://${IP}/setup/setup-functions.php?obj=DatabaseSetup"

# RabbitMQ - Variables are mapped in via Docker Compose environment variables...
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data "rmqUser=$RABBITMQ_DEFAULT_USER&rmqPass=$RABBITMQ_DEFAULT_PASS&rmqHost=libretime-rabbitmq&rmqPort=5672&rmqVHost=$RABBITMQ_DEFAULT_VHOST&rmqErr=" \
     "http://${IP}/setup/setup-functions.php?obj=RabbitMQSetup"

# Web Interface
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data "generalHost=localhost&generalPort=80&generalErr=" \
     "http://${IP}/setup/setup-functions.php?obj=GeneralSetup"

# Media Settings
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      --data 'mediaFolder=%2Fexternal-media%2F&mediaErr=' \
      "http://${IP}/setup/setup-functions.php?obj=MediaSetup"
