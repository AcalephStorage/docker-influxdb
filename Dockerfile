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

RUN wget http://s3.amazonaws.com/influxdb/influxdb_0.8.0-rc.4_amd64.deb && dpkg -i influxdb_0.8.0-rc.4_amd64.deb

ADD ./influxdb.conf /usr/local/etc/influxdb.conf
ADD ./database.json /usr/local/etc/database.json
ADD ./continuous_queries.dat /usr/local/etc/continuous_queries.dat

ADD ./bootstrap.sh /bootstrap.sh
RUN chmod 0744 /bootstrap.sh

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

CMD ["/bootstrap.sh"]
