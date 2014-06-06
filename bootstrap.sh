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

