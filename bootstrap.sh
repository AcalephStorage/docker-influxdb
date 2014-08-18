#!/bin/bash -e
 
# the influxdb binary
influxdb_bin=/usr/bin/influxdb

# influxdb host and port
influxdb_host=localhost
influxdb_api_port=8086

# the root password. if not specified, will default to root
influxdb_root_password=${INFLUXDB_ROOT_PASSWORD:=root}

# location of config and data files
influxdb_config=/usr/local/etc/influxdb.conf
influxdb_db_config=/usr/local/etc/database.json


# start influxdb, if a parameter is given, influxdb will be 
# ran in the background
function start_influxdb() {
	if [[ -n "$1" ]]; then
		$influxdb_bin --config=$influxdb_config &
		sleep 10
	else
		$influxdb_bin --config=$influxdb_config
	fi
}



# check if a database already exists. returns 0 if it exists. 
# else it returns 1
function db_exist() {
	echo "checking if database $1 exists..."
	db_list=`curl -s "http://${influxdb_host}:${influxdb_api_port}/db?u=root&p=${influxdb_root_password}"`
	if [[ $db_list == *$1* ]]; then
		return 0
	else
		return 1
	fi
}



# change the root password to the value of ${influxdb_root_password}
function change_root_password() {
	already_changed=`curl -s -o /dev/null -w %{http_code} "http://${influxdb_host}:${influxdb_api_port}/db?u=root&p=${influxdb_root_password}"`
	if [[ "$already_changed" == "200" ]]; then
		echo 'password already changed'
	else
		change_success=`curl -s -o /dev/null -w %{http_code} "http://${influxdb_host}:${influxdb_api_port}/cluster_admins/root?u=root&p=root" -d "{\"password\": \"${influxdb_root_password}\"}"`
		if [[ "$change_success" == "200" ]]; then
			echo 'root password changed'
		else
			echo $change_success
			echo 'unable to change password.'
			exit 1
		fi
	fi
}



# setup the graphite database.
function setup_graphite() {
	if ! db_exist graphite; then
		echo 'loading configuration'
		result=`curl -s -X POST -w %{http_code} "http://${influxdb_host}:${influxdb_api_port}/cluster/database_configs/graphite?u=root&p=${influxdb_root_password}" --data-binary @${influxdb_db_config}`
		if [[ "$result" != "201" ]]; then
			echo "unable to load database"
			exit 1
		fi
		echo 'creating graphite user'
		result=`curl -s -o /dev/null -X POST -w %{http_code} -d '{"name": "graphite", "password": "graphite"}' "http://${influxdb_host}:${influxdb_api_port}/db/graphite/users?u=root&p=${influxdb_root_password}"`
		if [[ "$result" != "200" ]]; then
			echo "unable to create database user"
			exit 1
		fi
	else
		echo 'graphite db already exists.'
	fi
}


# main function
function main() {
	start_influxdb background
	change_root_password
	setup_graphite
	kill $! 	# kill influxdb
	start_influxdb
}


# run main
main
