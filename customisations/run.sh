#!/bin/bash

# This is a script that is run (inside the docker container) each time it is stood up / restarted.
# You may customise this script to suit your needs if you plan on adding any special config into your setup which you wish to "script".
#
# All files will be copied into the "/etc/airtime-customisations" directory inside the container.
#
################################################################

# Get the directory that this script is in...
SCRIPT_PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"



# Example: Change background image with a new custom background...

BACKGROUND_FILE="/usr/share/airtime/php/airtime_mvc/public/css/radio-page/img/background-testing-3.jpg"
rm -rf "$BACKGROUND_FILE"
cp "$SCRIPT_PWD/login-background.jpg" "$BACKGROUND_FILE"
chown www-data:www-data "$BACKGROUND_FILE"



# Example: Add in custom CSS to the login/homepage only..

HOMEPAGE_TEMPLATE="/usr/share/airtime/php/airtime_mvc/application/views/scripts/index/index.phtml"
CSS_CUSTOM_FILE="/usr/share/airtime/php/airtime_mvc/public/css/radio-page/custom.css"
CSS_STRING='<link href="/css/radio-page/custom.css" rel="stylesheet" type="text/css" />'

if ! grep -q "$CSS_STRING" "$HOMEPAGE_TEMPLATE"
then
    # Only add in CSS if it's not yet in the file...
    echo "$CSS_STRING" >> "$HOMEPAGE_TEMPLATE"
fi

cp "$SCRIPT_PWD/login-custom.css" "$CSS_CUSTOM_FILE"
chown www-data:www-data "$CSS_CUSTOM_FILE"



# Example: Add Google Analytics tracking on the homepage...
HOMEPAGE_TEMPLATE="/usr/share/airtime/php/airtime_mvc/application/views/scripts/index/index.phtml"
GA_SITE_TAG='<!-- GA-SITE-TAG -->'

# Update this with your real Google Analytics Site ID
GA_SITE_ID="UA-126119626-1"

if ! grep -q "$GA_SITE_TAG" "$HOMEPAGE_TEMPLATE"
then

    # Only add in GA Javascript if it's not yet in the file...
    echo '<!-- GA-SITE-TAG -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=UA-126119626-1"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag("js", new Date());

      gtag("config", "'"$GA_SITE_ID"'");
    </script>' >> "$HOMEPAGE_TEMPLATE"

fi


