#!/bin/sh

if [ ! -f docker-compose.yml ]; then
  echo "This script needs to be executed from the directory that contains the docker-compose.yml"
  exit 1;
fi

function init_volume() {
  directory=${1}
  user=${2}

  echo "Creating directory ${directory}"
  mkdir -p ${directory}

  echo "Changing owner of directory '${directory}' to '${user}'"
  chown ${user} ${directory}
}

. .env

init_volume data/faf-db ${FAF_DB_USER}
init_volume data/faf-prometheus ${FAF_PROMETHEUS_USER}
init_volume data/faf-grafana ${FAF_GRAFANA_USER}
init_volume data/faf-wordpress ${FAF_WORDPRESS_USER}
init_volume data/faf-phpbb3 ${FAF_PHPBB3_USER}
init_volume data/faf-mediawiki ${FAF_MEDIAWIKI_USER}
init_volume data/faf-nginx ${FAF_NGINX_USER}
init_volume data/faf-java-server ${FAF_JAVA_SERVER_USER}
init_volume data/faf-java-api ${FAF_JAVA_API_USER}
