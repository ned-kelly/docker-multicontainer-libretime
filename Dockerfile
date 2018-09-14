FROM ubuntu:trusty

## General components we need in this container...
RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y locales sudo htop nano supervisor curl wget

# Boostrap process for libretime (apache and rabbitmq bust be running to get the thing properly installed with their wizard)...
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y apache2 icecast2 rabbitmq-server git && \
    . /etc/apache2/envvars && \
    service apache2 start && \
    service rabbitmq-server start

# Remove pulsaudio: - http://sourcefabric.booktype.pro/airtime-25-for-broadcasters/preparing-the-server/
RUN apt-get purge pulseaudio -y

# Multiverse requried for some pkgs...
## libretime also use python, and the latest ubuntu build is breaking a few things... Here's a quick fix:
RUN sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get --fix-missing --reinstall install python python-minimal dh-python -y && \
    apt-get -f install

# Setup PostgreSQL & PHP Libs
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install libapache2-mod-php5 php5 php5-common php5-dev -y

# Postgresql requires locales-all
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install postgresql postgresql-contrib crudini -y

## Locals need to be configured or the media monitor dies in the ass...
RUN locale-gen "en_US.UTF-8" && \
    dpkg-reconfigure locales && \
    echo -e "LC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8" >> /etc/default/locale

# Pull down libretime sources
RUN export DEBIAN_FRONTEND=noninteractive && \
    mkdir -p /opt/libretime && \
    curl -s -L https://github.com/LibreTime/libretime/releases/download/3.0.0-alpha.4/libretime-3.0.0-alpha.4.tar.gz | tar --strip-components=1 -C /opt/libretime -xz && \
    service rabbitmq-server start && \
    SYSTEM_INIT_METHOD=`readlink --canonicalize -n /proc/1/exe | rev | cut -d'/' -f 1 | rev` && \
    sed -i -e 's/\*sysvinit\*)/\*'"$SYSTEM_INIT_METHOD"'\*)/g' /opt/libretime/install && \
    echo "SYSTEM_INIT_METHOD: [$SYSTEM_INIT_METHOD]" && \
    bash -c 'cd /opt/libretime; ./install --distribution=ubuntu --release=trusty --force --apache --postgres --icecast'

# This will be mapped in with all the media...
RUN mkdir -p /external-media/ && \
    chmod 777 /external-media/
    #mkdir -p /etc/airtime/ && \
    #chmod 777 -R /etc/airtime/

# Cleanup excess fat...
RUN service postgresql stop && \
    service rabbitmq-server stop && \
    service icecast2 stop && \
    service apache2 stop && \
    apt-get remove rabbitmq-server postgresql-9.3 -y

# Required to optimize the PHP front end...
RUN php5enmod opcache

# There seems to be a bug somewhere in the code and it's not respecting the DB being on another host (even though it's configured in the config files!)
# We'll use a lightweight golang TCP proxy to proxy any PGSQL request to the postgres docker container on TCP:5432. 

RUN cd /opt && curl -s -O -L https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz && tar -xzf go* && \
    mv go /usr/local/ && \
    export GOPATH=/opt/ && \
    export GOROOT=/usr/local/go && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    go get github.com/jpillora/go-tcp-proxy/cmd/tcp-proxy

# Cleanup excess fat...
RUN apt-get clean

COPY bootstrap/entrypoint.sh /opt/libretime/entrypoint.sh
COPY bootstrap/firstrun.sh /opt/libretime/firstrun.sh
COPY config/supervisor-minimal.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /opt/libretime/firstrun.sh && \
    chmod +x /opt/libretime/entrypoint.sh

VOLUME ["/etc/airtime", "/var/tmp/airtime/", "/var/log/airtime", "/usr/share/airtime", "/usr/lib/airtime"]
VOLUME ["/var/tmp/airtime"]

VOLUME ["/var/log/icecast2", "/etc/icecast2"]

EXPOSE 80 8000

CMD ["/opt/libretime/entrypoint.sh"]
