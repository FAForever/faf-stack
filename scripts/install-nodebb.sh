#!/bin/sh

# fail on errors
set -e

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack. The working directory must be the root of faf-stack."
    exit 1
fi


if [ -d "./data/faf-nodebb" ]; then
    echo "faf-nodebb directory already exists! Installation aborted."
    exit 1
fi

#docker-compose run --rm faf-nodebb sh -c "npm install && npm cache clean --force"
docker-compose run --rm faf-nodebb sh -c "./nodebb setup"

echo "faf-nodebb setup done! Don't forget to write down the admin accounts password!"
