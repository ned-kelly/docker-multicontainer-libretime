FROM ubuntu:xenial

LABEL maintainer="david@nedved.com.au"
LABEL description="A multi-container deployment of the Libretime Radio Broadcast Server, PostgreSQL, Icecast2 & RabbitMQ, based on Ubuntu Xenial & Alpine Linux!"

## General components we need in this container...
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y \
        locales \
        sudo \
        htop \
        nano \
        supervisor \
        curl \
        wget \
        crudini \
        git

# Multiverse requried for some pkgs...
## libretime also use python, and the latest ubuntu build is breaking a few things... Here's a quick fix:
RUN sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get --fix-missing --reinstall install \
        python \
        python-minimal \
        dh-python -y && \
    apt-get -f install

## Locals need to be configured or the media monitor dies in the ass...
RUN locale-gen "en_US.UTF-8" && \
    echo -e "LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8" >> /etc/default/locale

ENV PYTHONIOENCODING UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN apt-get install -y \
        php7.0-curl \
        php7.0-pgsql \
        apache2 \
        libapache2-mod-php7.0 \
        php7.0 \
        php-pear \
        php7.0-gd \
        php-bcmath \
        php-mbstring

# Pull down libretime sources
RUN export DEBIAN_FRONTEND=noninteractive && \
    git clone --depth=1 https://github.com/ned-kelly/libretime.git /opt/libretime && \
    SYSTEM_INIT_METHOD=`readlink --canonicalize -n /proc/1/exe | rev | cut -d'/' -f 1 | rev` && \
    sed -i -e 's/\*systemd\*)/\*'"$SYSTEM_INIT_METHOD"'\*)/g' /opt/libretime/install && \
    echo "SYSTEM_INIT_METHOD: [$SYSTEM_INIT_METHOD]" && \
    bash -c 'cd /opt/libretime; ./install --distribution=ubuntu --release=xenial_docker_minimal --force --apache --no-postgres --no-rabbitmq; exit 0'; exit 0

# This will be mapped in with all the media...
RUN mkdir -p /external-media/ && \
    chmod 777 /external-media/

# There seems to be a bug somewhere in the code and it's not respecting the DB being on another host (even though it's configured in the config files!)
# We'll use a lightweight golang TCP proxy to proxy any PGSQL request to the postgres docker container on TCP:5432. 

RUN cd /opt && curl -s -O -L https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz && tar -xzf go* && \
    mv go /usr/local/ && \
    export GOPATH=/opt/ && \
    export GOROOT=/usr/local/go && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    go get github.com/jpillora/go-tcp-proxy/cmd/tcp-proxy && \
    rm -rf /opt/go1.*.tar.gz

# Remove PostgreSQL and RMQ before building Silian...
RUN apt-get remove -y postgresql-9.5 rabbitmq-server icecast2

# We need to install ffmpeg BEFORE we've built and statically linked silan (it will link some files that ffmpeg will remove if ffmpeg installed after)...
# See: https://github.com/LibreTime/libretime/commit/796a2a3ddd94dc671ab206b0e8ec1e20fbc4fb2a
RUN apt-get install ffmpeg -y

# Build us a copy of Silan 0.4.0 which fixes many of the various problems listed throughout the libretime forums.
RUN apt-get remove silan -y && \
    git clone https://github.com/x42/silan.git /opt/silan && \
    cd /opt/silan && git fetch && git fetch --tags && git checkout "v0.4.0" && \
    /opt/silan/x-pbuildstatic.sh && \
    cd /usr/src/silan && make && make install && \
    ln -s /usr/local/bin/silan /usr/bin/silan

COPY bootstrap/entrypoint.sh bootstrap/add-to-cron.txt bootstrap/firstrun.sh /opt/libretime/
COPY config/supervisor-minimal.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /opt/libretime/firstrun.sh && \
    chmod +x /opt/libretime/entrypoint.sh && \

    # Setup cron (the podcast script leaves a bit of a mess in /tmp - there's a few cleanup tasks that run via crontab)... 
    crontab /opt/libretime/add-to-cron.txt

# Cleanup excess fat...
RUN apt-get clean

VOLUME ["/etc/airtime", "/var/tmp/airtime/", "/var/log/airtime", "/usr/share/airtime", "/usr/lib/airtime"]
VOLUME ["/var/tmp/airtime"]

EXPOSE 80 8000

CMD ["/opt/libretime/entrypoint.sh"]
