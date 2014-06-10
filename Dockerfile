FROM ubuntu:trusty
MAINTAINER Acaleph <admin@acale.ph>
 
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

# Install InfluxDB
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y language-pack-en wget
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

RUN wget http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb
RUN sudo dpkg -i influxdb_latest_amd64.deb

RUN apt-get install -y build-essential python-dev libffi-dev libcairo2-dev python-pip supervisor

RUN pip install gunicorn graphite-api[sentry,cyanite] graphite_influxdb

# add graphite-api config
ADD graphite-api.yaml /etc/graphite-api.yaml
RUN chmod 0644 /etc/graphite-api.yaml

# bootstrap to add graphite db
ADD ./bootstrap.sh /bootstrap.sh
RUN chmod 0744 /bootstrap.sh

ADD ./influxdb.conf /usr/local/etc/influxdb.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf


RUN mkdir /srv/graphite
RUN chmod 777 /srv/graphite


# Graphite
EXPOSE 2003

# Admin
EXPOSE 8083

# API
EXPOSE 8086

# Raft 
EXPOSE 8090

# Replication 
EXPOSE 8099

# graphite-api 
EXPOSE 8000 

VOLUME "/opt/influxdb/shared/data/db"
VOLUME "/opt/graphite"
VOLUME "/var/log/supervisor"




CMD ["/usr/bin/supervisord"]
