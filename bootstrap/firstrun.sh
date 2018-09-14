#!/bin/bash

service apache2 start
#cp -rp /etc/airtime-template/* /etc/airtime/
#chmod 777 -R /etc/airtime/

# Configure (This is the same as running in the web-ui)
IP=$(ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://')

# Database
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data 'dbUser=libretime&dbPass=libretime&dbName=libretime&dbHost=libretime-postgres&dbErr=' \
     "http://${IP}/setup/setup-functions.php?obj=DatabaseSetup"

# RabbitMQ
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data 'rmqUser=libretime&rmqPass=libretime&rmqHost=libretime-rabbitmq&rmqPort=5672&rmqVHost=/libretime&rmqErr=' \
     "http://${IP}/setup/setup-functions.php?obj=RabbitMQSetup"

# Web Interface
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
     --data 'generalHost=localhost&generalPort=80&generalErr=' \
     "http://${IP}/setup/setup-functions.php?obj=GeneralSetup"

# Media Settings
curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
     -H 'Accept: application/json, text/javascript, */*; q=0.01' \
      --data 'mediaFolder=%2Fexternal-media%2F&mediaErr=' \
      "http://${IP}/setup/setup-functions.php?obj=MediaSetup"

service apache2 stop

#sudo cp ~/helpers/htaccess /opt/airtime/public/.htaccess

# Now fire up supervisor and we're good to go!
/usr/bin/supervisord