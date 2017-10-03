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
  chown -R "${user}" "${directory}"
}

. .env

# Permissions could be set like this:

# init_volume data/faf-db ${FAF_DB_USER}

# But for now we don't mess with any permissions unless we know what we're doing
