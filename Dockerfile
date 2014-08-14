FROM ubuntu:trusty
MAINTAINER Acaleph <admin@acale.ph>

# the universe is broken. thank you https://github.com/docker/docker/issues/5388 for the fix.
#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list

# Install InfluxDB
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y language-pack-en wget
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales

RUN wget http://s3.amazonaws.com/influxdb/influxdb_0.8.0-rc.4_amd64.deb && dpkg -i influxdb_0.8.0-rc.4_amd64.deb

RUN apt-get install -y build-essential python-dev libffi-dev libcairo2-dev python-pip supervisor

RUN pip install gunicorn Flask-Cache statsd raven blinker

# patched version with cache
RUN pip install https://github.com/Dieterbe/graphite-api/tarball/check-series-early

# graphite-influxdb PR#16 which fixes metrics api
RUN pip install https://github.com/svanharmelen/graphite-influxdb/tarball/bugfix

# latest influxdb-python
RUN pip uninstall -y influxdb
RUN pip install https://github.com/influxdb/influxdb-python/tarball/master

# add graphite-api config
ADD graphite-api.yaml /etc/graphite-api.yaml
RUN chmod 0644 /etc/graphite-api.yaml

# bootstrap to add graphite db
ADD ./bootstrap.sh /bootstrap.sh
RUN chmod 0744 /bootstrap.sh

ADD ./influxdb.conf /usr/local/etc/influxdb.conf
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# HACK. added 1 second interval.
ADD ./maintain_cache.py /usr/local/bin/maintain_cache.py
RUN chmod 0744 /usr/local/bin/maintain_cache.py

RUN mkdir /srv/graphite && chmod 777 /srv/graphite

# cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Graphite
EXPOSE 2003
EXPOSE 2003/udp

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

# VOLUME [ "/opt/influxdb/shared/data/db" ]
# VOLUME [ "/opt/graphite" ]
VOLUME [ "/var/log/supervisor", "/var/lib/influxdb" ]


CMD ["/usr/bin/supervisord"]
