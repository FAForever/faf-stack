#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

MAX_WAIT=60 # max. 1 minute waiting time in loop before timeout

docker-compose run --rm faf-ory-hydra migrate sql -c ./hydra.yaml --read-from-env --yes
docker-compose up -d faf-ory-hydra
