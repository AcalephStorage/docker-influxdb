FROM ubuntu:trusty
MAINTAINER Acaleph <admin@acale.ph>

# Install InfluxDB
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y language-pack-en wget curl
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

RUN wget http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && dpkg -i influxdb_latest_amd64.deb
RUN wget https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego -O /usr/local/bin/forego && chmod 0744 /usr/local/bin/forego

ADD ./influxdb.conf /usr/local/etc/influxdb.conf
ADD ./graphite.json /usr/local/etc/graphite.json
ADD ./events.json /usr/local/etc/events.json

ADD ./Procfile /usr/local/etc/Procfile
RUN chmod 0644 /usr/local/etc/Procfile

ADD ./bootstrap.sh /usr/local/etc/bootstrap.sh
RUN chmod 0744 /usr/local/etc/bootstrap.sh

# cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Admin
EXPOSE 8083

# API
EXPOSE 8086

# Raft
EXPOSE 8090

# Replication
EXPOSE 8099

# Graphite
EXPOSE 2003
EXPOSE 2003/udp

VOLUME /var/lib/influxdb

CMD ["/usr/local/bin/forego", "start", "-f", "/usr/local/etc/Procfile", "-c", "influxdb=1"]
