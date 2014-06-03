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

# ADD run.sh /run.sh
# RUN chmod 755 /*.sh

RUN apt-get install -y build-essential python-dev libffi-dev libcairo2-dev python-pip

RUN pip install gunicorn graphite-api[sentry,cyanite] graphite_influxdb

ADD graphite-api.yaml /etc/graphite-api.yaml
RUN chmod 0644 /etc/graphite-api.yaml


EXPOSE 2003 # Graphite
EXPOSE 8083 # Admin
EXPOSE 8086 # API
EXPOSE 8090 # Raft
EXPOSE 8099 # Replication
EXPOSE 8000 # graphite-api

VOLUME "/opt/influxdb/shared/data/db"
VOLUME "/opt/graphite"

# CMD ["/run.sh"]
# CMD ["-config=/opt/influxdb/shared/config.json"]
# ENTRYPOINT ["/usr/bin/influxdb"]

CMD gunicorn -b 0.0.0.0:8000 -w 2 --log-level debug graphite_api.app:app