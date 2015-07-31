FROM ubuntu:trusty
MAINTAINER Acaleph <admin@acale.ph>

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# update system
RUN apt-get update && \
    apt-get upgrade -y && \ 
    apt-get install -y language-pack-en wget curl python python-pip && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# install latest influxdb
RUN wget http://s3.amazonaws.com/influxdb/influxdb_0.8.8_amd64.deb && \
    dpkg -i influxdb_0.8.8_amd64.deb && \
    rm influxdb_latest_amd64.deb

# install latest forego
RUN wget https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego -O /usr/local/bin/forego && \
    chmod 0744 /usr/local/bin/forego

ADD ./configs/influxdb.conf /usr/local/etc/influxdb.conf
ADD ./configs/graphite_db.json /usr/local/etc/graphite_db.json
ADD ./configs/default_db.json /usr/local/etc/default_db.json

ADD ./configs/Procfile /usr/local/etc/Procfile

ADD ./scripts/bootstrap.sh /usr/local/etc/bootstrap.sh
ADD ./scripts/whisper-to-influxdb.py /usr/local/bin/whisper-to-influxdb.py
ADD ./scripts/start /usr/local/etc/start

RUN pip install whisper

ENV ROOT_PASSWORD root
ENV GRAPHITE_DATABASE graphite
ENV GRAPHITE_USERNAME graphite
ENV GRAPHITE_PASSWORD graphite
ENV DEFAULT_DATABASE acaleph
ENV DEFAULT_USERNAME acaleph
ENV DEFAULT_PASSWORD acaleph

# Admin API Raft Replication
EXPOSE 8083 8086 8090 8099

# Graphite
EXPOSE 2003 2003/udp

VOLUME /var/lib/influxdb

WORKDIR /usr/local/etc

CMD ["start"]
ENTRYPOINT ["/usr/local/etc/start"]

