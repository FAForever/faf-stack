#!/usr/bin/env bash
#!/bin/bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

docker-compose up -d faf-db
echo -n "Waiting for faf-db "
while ! docker exec -it faf-db sh -c "mysqladmin ping -h 127.0.0.1 -uroot -pbanana" &> /dev/null
do
  echo -n "."
  sleep 1
done
docker-compose run faf-db-migrations migrate
source config/faf-db/faf-db.env

create() {
  database=$1
  username=$2
  password=$3
  db_options=${4:-}

  docker exec -i faf-db mysql --user=root --password=${MYSQL_ROOT_PASSWORD} <<SQL_SCRIPT
    CREATE DATABASE IF NOT EXISTS \`${database}\` ${db_options};
    CREATE USER '${username}'@'%' IDENTIFIED BY '${password}';
    GRANT ALL PRIVILEGES ON \`${database}\`.* TO '${username}'@'%';
SQL_SCRIPT
}

create "${MYSQL_DATABASE}" "faf-java-api" "${MYSQL_JAVA_API_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-python-api" "${MYSQL_PYTHON_API_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-legacy-live-replay-server" "${MYSQL_LEGACY_LIVE_REPLAY_SERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-aio-replayserver" "${MYSQL_AIO_REPLAYSERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-legacy-secondary-server" "${MYSQL_LEGACY_SECONDARY_SERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-legacy-updater" "${MYSQL_LEGACY_UPDATER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-policy-server" "${MYSQL_POLICY_SERVER_PASSWORD}"
create "faf-murmur" "faf-murmur" "${MYSQL_MURMUR_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-java-server" "${MYSQL_JAVA_SERVER_PASSWORD}"
create "${MYSQL_DATABASE}" "faf-python-server" "${MYSQL_PYTHON_SERVER_PASSWORD}"
create "faf-softvote" "faf-softvote" "${MYSQL_SOFTVOTE_PASSWORD}"
create "faf-anope" "faf-anope" "${MYSQL_ANOPE_PASSWORD}"
create "faf-wiki" "faf-wiki" "${MYSQL_WIKI_PASSWORD}"
create "faf-wordpress" "faf-wordpress" "${MYSQL_WORDPRESS_PASSWORD}"
create "faf-phpbb3" "faf-phpbb3" "${MYSQL_PHPBB3_PASSWORD}"
create "faf-mautic" "faf-mautic" "${MYSQL_MAUTIC_PASSWORD}"
create "faf-postal" "faf-postal" "${MYSQL_POSTAL_PASSWORD}" "CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci"

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
  CREATE USER 'faf-mysql-exporter'@'%' IDENTIFIED BY '${MYSQL_MYSQL_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
  GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'faf-mysql-exporter'@'%';
SQL_SCRIPT
