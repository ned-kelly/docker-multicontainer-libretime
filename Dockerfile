FROM ubuntu:xenial

## General components we need in this container...
RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y locales sudo htop nano supervisor curl wget crudini git

# Multiverse requried for some pkgs...
## libretime also use python, and the latest ubuntu build is breaking a few things... Here's a quick fix:
RUN sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get --fix-missing --reinstall install python python-minimal dh-python git -y && \
    apt-get -f install

## Locals need to be configured or the media monitor dies in the ass...
RUN locale-gen "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    echo -e "LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8" >> /etc/default/locale

RUN apt-get install -y php7.0-curl php7.0-pgsql apache2 libapache2-mod-php7.0 php7.0 php-pear php7.0-gd php-bcmath php-mbstring

# Pull down libretime sources
RUN export DEBIAN_FRONTEND=noninteractive && \
    git clone https://github.com/ned-kelly/libretime.git /opt/libretime && \
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
    go get github.com/jpillora/go-tcp-proxy/cmd/tcp-proxy

# Cleanup excess fat...
RUN apt-get remove -y postgresql-9.5 rabbitmq-server icecast2
RUN apt-get clean

RUN export DEBIAN_FRONTEND=noninteractive && \
 wget -qO- http://download.opensuse.org/repositories/home:/hairmare:/silan/Debian_7.0/Release.key   | apt-key add -  && \
echo 'deb http://download.opensuse.org/repositories/home:/hairmare:/silan/xUbuntu_16.04 ./'   > /etc/apt/sources.list.d/hairmare_silan.list  && \
apt-get update  && \
apt-get install silan

COPY bootstrap/entrypoint.sh /opt/libretime/entrypoint.sh
COPY bootstrap/firstrun.sh /opt/libretime/firstrun.sh
COPY config/supervisor-minimal.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /opt/libretime/firstrun.sh && \
    chmod +x /opt/libretime/entrypoint.sh

# Setup cron (the podcast script leaves a bit of a mess in /tmp - there's a few cleanup tasks that run via crontab)...
COPY bootstrap/add-to-cron.txt /var/add-to-cron.txt
RUN crontab /var/add-to-cron.txt

VOLUME ["/etc/airtime", "/var/tmp/airtime/", "/var/log/airtime", "/usr/share/airtime", "/usr/lib/airtime"]
VOLUME ["/var/tmp/airtime"]

EXPOSE 80 8000

CMD ["/opt/libretime/entrypoint.sh"]
