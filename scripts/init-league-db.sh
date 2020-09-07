#!/usr/bin/env bash
#!/bin/bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

MAX_WAIT=360 # max. 5 minute waiting time in loop before timeout

docker network create outside
docker-compose up -d faf-league-db
docker-compose logs -f faf-league-db &
log_process_id=$!

echo -n "Waiting for faf-league-db "
current_wait=0
while ! docker exec -i faf-league-db sh -c "mysqladmin ping -h 127.0.0.1 -uroot -pbanana" >/dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of faf-league-db"
    kill -TERM ${log_process_id}
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done

kill -TERM ${log_process_id}


echo "Waiting for faf-league-db-migrations"
docker-compose run --rm faf-league-db-migrations migrate || { echo "Failed migrate database"; exit 1; }

source config/faf-league-db/faf-league-db.env

create() {
  database=$1
  username=$2
  password=$3
  db_options=${4:-}

  docker exec -i faf-league-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
    CREATE DATABASE IF NOT EXISTS \`${database}\` ${db_options};
    CREATE USER '${username}'@'%' IDENTIFIED BY '${password}';
    GRANT ALL PRIVILEGES ON \`${database}\`.* TO '${username}'@'%';
SQL_SCRIPT
}

create "${MYSQL_DATABASE}" "faf-java-api" "${MYSQL_JAVA_API_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-league-service" "${MYSQL_LEAGUE_SERVICE_PASSWORD}"
