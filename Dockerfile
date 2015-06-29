FROM ubuntu:trusty
MAINTAINER Acaleph <admin@acale.ph>

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# update system
RUN apt-get update && \
    apt-get install -y language-pack-en wget && \
    wget http://influxdb.s3.amazonaws.com/influxdb_0.9.0_amd64.deb && \
    sudo dpkg -i influxdb_0.9.0_amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && dpkg-reconfigure locales

ADD configs/influxdb.conf /etc/opt/influxdb/influxdb.conf
ADD scripts/start /usr/local/etc/start

EXPOSE 8083 8086

VOLUME /var/opt/influxdb/data

# CMD ["start"]
CMD ["/usr/local/etc/start"]

