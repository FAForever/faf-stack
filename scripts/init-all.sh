#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

[ ! -d config ] && ln -s config.template config
[ ! -f .env ] && ln -s .env.template .env

echo "initializing database"
scripts/init-db.sh
echo "initializing rabbitmq"
scripts/init-rabbitmq.sh
echo "initializing hydra"
scripts/init-hydra.sh
echo "creating hydra test clients"
sleep 0.1
scripts/create-hydra-test-clients.sh
