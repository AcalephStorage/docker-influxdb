#!/bin/bash -e
 
# influxdb host and port
host=localhost
port=8086

graphite_config=/usr/local/etc/graphite_db.json
default_config=/usr/local/etc/default_db.json


# check if a database already exists. returns 0 if it exists. 
# else it returns 1
function db_exist() {
	echo "checking if database $1 exists..."
	db_list=`curl -s "http://${host}:${port}/db?u=root&p=${ROOT_PASSWORD}"`
	if [[ $db_list == *$1* ]]; then
		return 0
	else
		return 1
	fi
}

# change the root password to the value of ${influxdb_root_password}
function change_root_password() {
	already_changed=`curl -s -o /dev/null -w %{http_code} "http://${host}:${port}/db?u=root&p=${ROOT_PASSWORD}"`
	if [[ "$already_changed" == "200" ]]; then
		echo 'password already changed'
	else
		change_success=`curl -s -o /dev/null -w %{http_code} "http://${host}:${port}/cluster_admins/root?u=root&p=root" -d "{\"password\": \"${ROOT_PASSWORD}\"}"`
		if [[ "$change_success" == "200" ]]; then
			echo 'root password changed'
		else
			echo $change_success
			echo 'unable to change password.'
			exit 1
		fi
	fi
}


function create_database() {
	db=$1
	user=$2
	pass=$3
	config=$4
	if ! db_exist ${db}; then
		echo "creating ${db} db"
		result=`curl -s -X POST -w %{http_code} "http://${host}:${port}/cluster/database_configs/${db}?u=root&p=${ROOT_PASSWORD}" --data-binary @${config}`
		if [[ "$result" != "201" ]]; then
			echo "unable to create ${db}"
			exit 1
		fi
		echo "creating ${user} for ${db}"
		result=`curl -s -o /dev/null -X POST -w %{http_code} -d "{\"name\": \"${user}\", \"password\": \"${pass}\"}" "http://${host}:${port}/db/${db}/users?u=root&p=${ROOT_PASSWORD}"`
		if [[ "$result" != "200" ]]; then
			echo "unable to create database user ${user}"
			exit 1
		fi
	else
		echo "${db} db already exists"
	fi
}


# main function
function main() {
	sleep 10
	change_root_password
	create_database ${GRAPHITE_DATABASE} ${GRAPHITE_USERNAME} ${GRAPHITE_PASSWORD} ${graphite_config}
	create_database ${DEFAULT_DATABASE} ${DEFAULT_USERNAME} ${DEFAULT_PASSWORD} ${default_config}
	while :; do sleep 60; done
}


# run main
main

