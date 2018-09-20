# "Libretime" Multi-container Docker Setup.

This is a multi-container Docker build of the Libretime Radio Broadcast Software _(Libretime is a direct fork of Airtime for those who are wondering, hence the similarities)_.

It's an aim to run the environment ready for production, with common media directories, database files etc mapped into the container(s) so data is persisted between rebuilds of the application.

It's originally based off my [`docker-multicontainer-airtime`](https://github.com/ned-kelly/docker-multicontainer-airtime) setup, and has been adapted to suit the newer Libretime sources accordingly.

---------------------------

**Last Tested Libretime Build**: [`master branch (2018-10-16) #b79af94`](https://github.com/LibreTime/libretime/commit/b79af9480b6a22952cc36b8f8813646b770a057b)

**Docker Hub:** [`bushrangers/ubuntu-multicontainer-libretime`](https://hub.docker.com/r/bushrangers/ubuntu-multicontainer-libretime/)



![Docker Build Status](https://img.shields.io/docker/build/bushrangers/ubuntu-multicontainer-libretime.png) ![Docker Pulls](https://img.shields.io/docker/pulls/bushrangers/ubuntu-multicontainer-libretime.png)



## Overview:

The project consists of four main containers/components:

 - `libretime-core` - This is the main Libretime container - Currently Based on the latest Ubuntu Xenial build.
 - `libretime-rabbitmq` - A seperated RabbitMQ container based on Alpine Linux.
 - `libretime-postgres` - The database engine behind Libretime - It's also an Alpine Linux build in an attempt to be as 'lean and mean' as possible when it comes to system resources.
 - `libretime-icecast` - The Icecast2 daemon - Alpine linux based, lightweight and uses minimal resources.

![Container Overview](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/docker-container-diagram.png "Container Overview")

## Configuration:

You will want to edit the `docker-compose.yml` file and change some of the mappings to suit your needs.
If you're new to docker you should probably configure:

 - Edit: `/localmusic:/external-media` - Change this to the directory on your Linux server where your media resides.

 - Configure the environment variables in the `libretime-core` block if you don't want to run with the default configuration - Note it's safe to just leave the default configuration/passwords etc as services (Postgres, RabbitMQ, etc) are only accessible from within the containers as they are in a 'bridged' docker network.

 - You must configure the `libretime-icecast` environment variables in your `docker-compose.yml` file to suit your needs - **(Don't leave the passwords as the default if you're exposing this to the internet - You will also need to update your settings in the Libratime UI)**.

## Standing up:

It's pretty straightforward, just clone down the sources and stand up the container like so:

```bash
# Clone down sources
git clone https://github.com/ned-kelly/docker-multicontainer-libretime.git

### MAKE YOUR CONFIGURATION CHANGES IF REQUIRED ###
vi docker-multicontainer-libretime/docker-compose.yml
vi docker-multicontainer-libretime/config/icecast.xml

# Icecast XML file will be modified by startup script(s)
chmod 777 docker-multicontainer-libretime/config/icecast.xml

# Stand up the container
docker-compose up -d

```

**Building against the Master Branch**:

If you want to build against the most recent Libratime release on Github (rather than using the official releases), simply edit the main `docker-compose.yml` file and comment out the `image` directive (in the `libretime-core` definition) and uncomment the `build` line. This will not pull the latest build from the Docker hub, but rather build a local copy from the latest Libratime sources locally. Note that there's no guarantees against the stability of Libratime when using "bleeding edge" builds.

**NOTE**:

When running for the first time, the libretime-core container will run some 'boostrap' scripts. This will take 15-30 seconds (after standing up the containers) BEFORE you will be able to fully access libretime.

You can monitor the progress of the bootstrap process by running: `docker logs -f libretime-core`.

Once the containers have been stood up you should be able to access the project directly in your browser...

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
 
## Deploying on the internet?

You will need to setup port forwarding to your Docker host for:

 - TCP:8000 (Icecast server) - **NB: change the default icecast passwords first!**
 - Perhaps to your web interface port if you want this public...
 - TCP:8001 & TCP:8002 (Remote access for Master & Source inputs - **NB: This allows open access to Libretime, use with caution or via a VPN.**

You might want to use something like [This "Caddy" Docker Container](https://github.com/abiosoft/caddy-docker) to proxy pass to Apache with an automatic signed SSL certificate thanks to Lets Encrypt... 

## Screenshots

![Homepage Screenshot](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/homepage.png "Libretime UI Homepage")

_Fig 1: Homepage Example._

![Configuration Passing Screenshot](https://raw.githubusercontent.com/ned-kelly/docker-multicontainer-libretime/master/screenshots/config-check.png "Configuration Passing Screenshot")

_Fig 2: Configuration Passing & all services running "out of the box" as expected._