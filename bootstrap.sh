#!/bin/sh

# This is just a quick script to create the graphite database and graphite user.
# This is executed under supervisor once.

# Sleep for a while to make sure that influxdb has totally started up
echo 'waiting for influxdb to bootup. (cheat: just 10 second wait)'
sleep 10


echo 'creating graphite database'
# create graphite database
wget --post-data='{"name": "graphite"}' 'http://localhost:8086/db?u=root&p=root'


echo 'creating graphite user'
# create graphite user
wget --post-data='{"name": "graphite", "password": "graphite"}' 'http://localhost:8086/db/graphite/users?u=root&p=root'

# sigh.. need data for maintain_cache to work or else it fails miserably.
echo "bootstrap 1 `date +%s`" | nc -q0 localhost 2003

# maintain cache
echo 'running cache maintenance'
/usr/local/bin/maintain_cache.py >>/var/log/supervisor/maintain_cache.log 2>&1