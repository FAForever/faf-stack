#!/usr/bin/env bash
#!/bin/bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

MAX_WAIT=360 # max. 5 minute waiting time in loop before timeout

docker network create outside
docker-compose up -d faf-db
docker-compose logs -f faf-db &
log_process_id=$!

echo -n "Waiting for faf-db "
current_wait=0
while ! docker exec -i faf-db sh -c "mysqladmin ping -h 127.0.0.1 -uroot -pbanana" >/dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of faf-db"
    kill -TERM ${log_process_id}
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done

kill -TERM ${log_process_id}


echo "Waiting for faf-db-migrations"
docker-compose run --rm faf-db-migrations migrate || { echo "Failed migrate database"; exit 1; }

source config/faf-db/faf-db.env

create() {
  database=$1
  username=$2
  password=$3
  db_options=${4:-}

  echo "Create database ${database} and create + assign user ${username}"

  docker exec -i faf-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
    CREATE DATABASE IF NOT EXISTS \`${database}\` ${db_options};
    CREATE USER IF NOT EXISTS '${username}'@'%' IDENTIFIED BY '${password}';
    GRANT ALL PRIVILEGES ON \`${database}\`.* TO '${username}'@'%';
SQL_SCRIPT
}

create "${MYSQL_DATABASE}" "faf-java-api" "${MYSQL_JAVA_API_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-python-api" "${MYSQL_PYTHON_API_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-aio-replayserver" "${MYSQL_AIO_REPLAYSERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-policy-server" "${MYSQL_POLICY_SERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-python-server" "${MYSQL_PYTHON_SERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-user-service" "${MYSQL_USER_SERVICE_PASSWORD}"
create "faf-anope" "faf-anope" "${MYSQL_ANOPE_PASSWORD}"
create "faf-wiki" "faf-wiki" "${MYSQL_WIKI_PASSWORD}"
create "faf-wordpress" "faf-wordpress" "${MYSQL_WORDPRESS_PASSWORD}"
create "faf-mautic" "faf-mautic" "${MYSQL_MAUTIC_PASSWORD}"
create "faf-postal" "faf-postal" "${MYSQL_POSTAL_PASSWORD}" "CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci"
create "${LEAGUE_DATABASE}" "faf-java-api" "${MYSQL_JAVA_API_PASSWORD}"
create "${LEAGUE_DATABASE}" "faf-league-service" "${LEAGUE_SERVICE_PASSWORD}"
create "hydra" "hydra" "${HYDRA_PASSWORD}" "CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci"

# To update the IRC password, we give the server/api full bloated access to all of anope's tables.
docker exec -i faf-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
    GRANT ALL PRIVILEGES ON \`${POSTAL_MESSAGE_DATABASE_PREFIX}-%\`.* to 'faf-postal'@'%';
SQL_SCRIPT

# To update the IRC password, we give the server/api full bloated access to all of anope's tables.
docker exec -i faf-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
    GRANT ALL PRIVILEGES ON \`faf-anope\`.* TO 'faf-python-server'@'%';
    GRANT ALL PRIVILEGES ON \`faf-anope\`.* TO 'faf-java-api'@'%';
SQL_SCRIPT

# Allows faf-mysql-exporter to read metrics. It is recommended to set a max connection limit for the user to avoid
# overloading the server with monitoring scrapes under heavy load.
docker exec -i faf-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
  CREATE USER IF NOT EXISTS 'faf-mysql-exporter'@'%' IDENTIFIED BY '${MYSQL_MYSQL_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
  GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'faf-mysql-exporter'@'%';
SQL_SCRIPT
