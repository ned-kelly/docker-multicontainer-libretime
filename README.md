# "Libretime" Multi-container Docker Setup.

This is a multi-container Docker build of the Libretime Radio Broadcast Software _(Libretime is a direct fork of Airtime for those who are wondering, hence the similarities)_.

It's an aim to run the environment ready for production which can be stood up in a few minutes (with ease), and all common media directories, database files, auto-dj icecast fallback support etc is mapped into the container(s) so data is persisted between rebuilds of the application.

It's originally based off my [`docker-multicontainer-airtime`](https://github.com/ned-kelly/docker-multicontainer-airtime) setup, and has been adapted to suit the newer Libretime sources accordingly.

**If you require assistance deploying this solution for a commercial station, please feel free to reach out to me - I do provide consultancy services.**

---------------------------

**Docker Hub:** [`bushrangers/ubuntu-multicontainer-libretime`](https://hub.docker.com/r/bushrangers/ubuntu-multicontainer-libretime/)

![Docker Build Status](https://img.shields.io/docker/build/bushrangers/ubuntu-multicontainer-libretime.png) ![Docker Pulls](https://img.shields.io/docker/pulls/bushrangers/ubuntu-multicontainer-libretime.png)



## Overview:

The project consists of four main containers/components:

 - `libretime-core` - This is the main Libretime container - Currently Based on the latest Ubuntu Xenial build.
 - `libretime-rabbitmq` - A seperated RabbitMQ container based on Alpine Linux.
 - `libretime-postgres` - The database engine behind Libretime - It's also an Alpine Linux build in an attempt to be as 'lean and mean' as possible when it comes to system resources.
 - `libretime-icecast` - The Icecast2 daemon - Alpine linux based, lightweight and uses minimal resources.

Optional Extras:

 - `icecast-analytics` - Your Icecast statistics in Google Analytics.

![Container Overview](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/docker-container-diagram.png "Container Overview")

## Standing up:

It's pretty straightforward, just clone down the sources and stand up the container like so:

```bash
# Clone down sources to /opt/libretime...
git clone https://github.com/ned-kelly/docker-multicontainer-libretime.git /opt/libretime
cd /opt/libretime

### CREATE A .env FILE AND ADD CONFIGURATION (see below for configuration options) ###
# You can use the default configuration and skip this step if you are just testing.

vi docker-multicontainer-libretime/.env

# Create a new docker network if this is the first time running Libretime it will be required...
docker network create libretime

# You will need to make your 'localmusic' directory writable so you can upload some content to the server...
mkdir localmusic && chmod 777 localmusic

# Stand up the container
docker-compose up -d

```

**Building against the Master Branch**:

If you want to build against the most recent Libratime releases (rather than using the pre-built docker image), simply edit the main `docker-compose.yml` file and comment out the `image` directive (in the `libretime-core` definition) and uncomment the `build` line. This will not pull the latest build from the Docker hub, but rather build a local copy from the latest Libratime sources locally. Note that there's no guarantees against the stability of Libratime when using "bleeding edge" builds and you should test this before rolling out into production.

**NOTE**:

When running for the first time, the libretime-core container will run some 'boostrap' scripts. This will take 15-30 seconds (after standing up the containers) BEFORE you will be able to fully access libretime.

You can monitor the progress of the bootstrap process by running: `docker logs -f libretime-core`.

Once the containers have been stood up you should be able to access the project directly in your browser...


## Configuration:

You will want to create a new `.env` file in the root of the project directory with variables that will not be over-written when pulling down newer builds of the configuration.

If you are just testing locally and not deploying this in a production environment, you can skip over this section and use the default configuration, however **if you are planning on deploying this on the Internet as a live server you SHOULD SET this configuration so you are not using default passwords/configuration etc.**

### Configuration Variables Currently Supported:

| Variable                    | Targets            | Default Value                | Purpose                                                                                                                                                                                                                 |
|-----------------------------|--------------------|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `POSTGRES_USER`             | libretime-postgres | `libretime`                  | The username to provision when standing up PostgreSQL                                                                                                                                                                   |
| `POSTGRES_PASSWORD`         | libretime-postgres | `libretime`                  | Password for the PostgreSQL Database                                                                                                                                                                                    |
| `RABBITMQ_DEFAULT_USER`     | libretime-rabbitmq | `libretime`                  | Username to access the RabbitMQ service                                                                                                                                                                                 |
| `RABBITMQ_DEFAULT_PASS`     | libretime-rabbitmq | `libretime`                  | Username to access the RabbitMQ service                                                                                                                                                                                 |
| `EXTERNAL_HOSTNAME`         | libretime-core     | `localhost`                  | The FQDN of your server published on the Internet - If left as `localhost` apache iframes and other configuration will be stripped out and made "relative"                                                              |
| `LOCAL_MUSIC_MAPPING`       | libretime-core     | `./localmusic`               | The path to your media directory / where uploads/media will be stored                                                                                                                                                   |
| `WEB_UI_PORT`               | libretime-core     | `8882`                       | The default port that the main Libretime HTTP Server/Web-UI will run on                                                                                                                                                 |
| `MASTER_SOURCE_PORT`        | libretime-core     | `8001`                       | Master port that producers can use to over-ride the active program with an Icecast Stream (Use a tool like [BUTT](https://github.com/dkwiebe/broadcasttool))                                                            |
| `DJ_SOURCE_PORT`            | libretime-core     | `8002`                       | DJ's Icecast port that they can use remotely (using their Libretime credentials) to broadcast during their scheduled time-slot                                                                                          |
| `ICECAST_PORT`              | libretime-icecast  | `35112`                      | The default port that Icecast will stream on -- Suggest leaving as default (a high number), 8000 is a common port that is often port-scanned                                                                            |
| `ICECAST_LOCATION`          | libretime-icecast  | `Mars`                       | The location of your Stream - Hint, put your city name here!                                                                                                                                                            |
| `ICECAST_SOURCE_PASSWORD`   | libretime-icecast  | `libretime`                  | This is the password Libretime uses to connect to icecast - You should make this something nice and secure - You don't want people hijacking your stream!                                                               |
| `ICECAST_RELAY_PASSWORD`    | libretime-icecast  | `libretime`                  | The password that people can use to re-stream your stream (i.e. create a satellite stream)                                                                                                                              |
| `ICECAST_ADMIN_USERNAME`    | libretime-icecast  | `admin`                      | The username to Administer the Icecast service                                                                                                                                                                          |
| `ICECAST_ADMIN_PASSWORD`    | libretime-icecast  | `libretime`                  | Password for the Icecast Administration User                                                                                                                                                                            |
| `ICECAST_ADMIN_EMAIL`       | libretime-icecast  | `martians@example.com`       | The "contact email" of the main person managing this setup/station (make this a generic email i.e. info@yourstation.com)                                                                                                |
| `ICECAST_HOSTNAME`          | libretime-icecast  | `icecast.local`              | This can be the same as your `EXTERNAL_HOSTNAME` parameter if you're running on the same IP/Host - It does however need to be a FQDN!                                                                                   |
| `ICECAST_MAX_CLIENTS`       | libretime-icecast  | `500`                        | Total number of people that can stream the station before Icecast will deny connections - You should limit this to a realistic value depending on how much UPLOAD bandwidth you have available at your station...       |
| `ICECAST_MOUNT_NAME`        | libretime-icecast  | `/live`                      | This is the endpoint that your stream will be published/accessible on                                                                                                                                                   |
| `WEBSITE_HOMEPAGE`          | libretime-icecast  | `http://libretime.org/`      | The URL to your station's homepage.                                                                                                                                                                                     |

You should change the Icecast passwords at a minimum - **(Don't leave the passwords as the default if you're exposing this to the internet, you will be hacked _(The default is ok if you're testing)_ - You will also need to update your settings in the Libratime UI)**.

## Accessing:

Just go to http://server-ip:8882/ (change port 8882 to whatever you mapped in your docker-compose file if you changed this)...

 - Default Username: `admin`
 - Default Password: `admin`

If you need to check the status of any services you may also do so by going to:

 - http://server-ip:8882/?config

Have fun!

**BE SURE TO WAIT 15-30 SECONDS OR SO FOR THE CONTAINERS TO BOOTSTRAP BEFORE TRYING TO ACCESS FOR THE FIRST TIME**

## Things to note & hack fixes:

 - There seems to be a bug in the current build of Libretime where if you run Postgres on another host the web/ui fails to log in (without any logs/errors showing anywhere)... After much pain trying to get this running "properly", the quick and simple fix has been to use a TCP proxy, that just proxies the PostgreSQL port:5432 to the actual dedicated postgres container.

 - By default - using "localhost" as the server name variable (in airtime.conf), iFrames obviously won't work - For now we are using a reverse proxy fix to replace any references to the "localhost" iframes to be relative.. See [Feature Request 515](https://github.com/LibreTime/libretime/issues/515) for details.

 - There seems to be issues when trying to just plonk a reverse proxy directly in front of the latest release of Libratime - Suspect some additional headers may need to be passed through - Anyone who has found a fix when using reverse proxies, please submit a PR.

 - The current build of Airtime has some issues pulling in podcasts that are in formats other than MP3 - this includes the [#519](https://github.com/LibreTime/libretime/issues/519) fix for users wanting to auto-import large quantities of podcasts it's pretty important as libretime currently only seems to work with MP3 podcasts.
 
 - If you're syndicating a lot of podcasts, there's an issue where the temp files are not properly cleaned up in the /tmp/ directory of the container which will result in disk space issues if you're running for a long time... There's a cron job that's been added to the container to cleanup the /tmp/ files each hour ... If you need to add any other custom cron jobs for your setup, just add them to the `bootstrap/add-to-cron.txt` file and then re-build the container.

## Deploying on the Internet?

You will need to setup port forwarding to your Docker host for:

 - TCP:8000 (Icecast server) - **NB: change the default icecast passwords first!**
 - Perhaps to your web interface port if you want this public...
 - TCP:8001 & TCP:8002 (Remote access for Master & Source inputs - **NB: This allows open access to Libretime, use with caution or via a VPN - or make sure you have secure passwords for your DJ's!**

You might want to use something like [This "Caddy" Docker Container](https://github.com/ned-kelly/alpine-caddy) to proxy pass to Apache with an automatic signed SSL certificate thanks to Lets Encrypt... 

## Icecast Google Analytics

If you want to send the data from your Icecast Streams to Google Analytics (so number of listeners, most popular streams/bitrates etc - please see the docker-[icecast-google-analytics](https://github.com/ned-kelly/docker-icecast-google-analytics) project, which can be integrated to your cluster.

## Fallback Icecast Stream Support

The setup includes a custom build of Icecast which has been pre-configured with a service called `ezstream` which will automatically play fallback music (A random playlist generated from your `LOCAL_MUSIC_MAPPING` content) in the event of a Libretime failure/restart/upgrade of the main Libretime container, or lack of programming in Libretime (i.e. there's nothing configured in Libretime).

By default, the "playlist" of fallback media will be auto-regenerated each night at midnight...
if you wish to manually trigger a regeneration of the fallback playlist you may run the following:

```bash
docker exec -it libretime-icecast bash -c "/playlist-builder.sh"
```

## Customising & scripting your deployment

- Anything in the `customisations/` directory will be mapped into `/etc/airtime-customisations` in the container allowing you to script custom fixes/changes to the core libretime container.

- By default a file called `run.sh` will be executed (if it exists).

**Sample Customisations (in `run.sh`):**

  - Change Homepage Background
  - Add in Custom CSS to Homepage
  - Add in Google Analytics Tracking to Homepage

## Sample screenshots

![Homepage Screenshot](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/homepage.png "Libretime UI Homepage")

_Fig 1: Homepage Example (with CSS customisations)._

![Schedule Example](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/schedule-example.png "Schedule Example")

_Fig 2: Example of Schedule_

![Configuration Passing Screenshot](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/config-check.png "Configuration Passing Screenshot")

_Fig 3: Configuration Passing & all services running "out of the box" as expected._