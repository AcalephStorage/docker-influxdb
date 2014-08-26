#!/bin/bash -e
 
# influxdb host and port
influxdb_host=localhost
influxdb_api_port=8086

# the root password. if not specified, will default to root
influxdb_root_password=${INFLUXDB_ROOT_PASSWORD:=root}
influxdb_graphite_user=${INFLUXDB_GRAPHITE_USER:=graphite}
influxdb_graphite_password=${INFLUXDB_GRAPHITE_PASSWORD:=graphite}
influxdb_events_user=${INFLUXDB_EVENTS_USER:=consul-notifier}
influxdb_events_password=${INFLUXDB_EVENTS_PASSWORD:=consul-notifier}

# location of config and data files
influxdb_graphite_config=/usr/local/etc/graphite.json
influxdb_events_config=/usr/local/etc/events.json




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
		echo 'creating graphite db'
		result=`curl -s -X POST -w %{http_code} "http://${influxdb_host}:${influxdb_api_port}/cluster/database_configs/graphite?u=root&p=${influxdb_root_password}" --data-binary @${influxdb_graphite_config}`
		if [[ "$result" != "201" ]]; then
			echo "unable to load database"
			exit 1
		fi
		echo 'creating graphite user'
		result=`curl -s -o /dev/null -X POST -w %{http_code} -d "{\"name\": \"${influxdb_graphite_user}\", \"password\": \"${influxdb_graphite_password}\"}" "http://${influxdb_host}:${influxdb_api_port}/db/graphite/users?u=root&p=${influxdb_root_password}"`
		if [[ "$result" != "200" ]]; then
			echo "unable to create database user"
			exit 1
		fi
	else
		echo 'graphite db already exists.'
	fi
}

function setup_events_db() {
	if ! db_exist event; then
		echo 'creating event db'
		result=`curl -s -X POST -w %{http_code} "http://${influxdb_host}:${influxdb_api_port}/cluster/database_configs/event?u=root&p=${influxdb_root_password}" --data-binary @${influxdb_events_config}`
		if [[ "$result" != "201" ]]; then
			echo "unable to load database"
			exit 1
		fi
		echo 'creating event user'
		result=`curl -s -o /dev/null -X POST -w %{http_code} -d "{\"name\": \"${influxdb_events_user}\", \"password\": \"${influxdb_events_password}\"}" "http://${influxdb_host}:${influxdb_api_port}/db/event/users?u=root&p=${influxdb_root_password}"`
		if [[ "$result" != "200" ]]; then
			echo "unable to create database user"
			exit 1
		fi
	else
		echo 'event db already exists.'
	fi
}

# main function
function main() {
	sleep 10
	change_root_password
	setup_graphite
	setup_events_db
	while :; do sleep 60; done
}


# run main
main

