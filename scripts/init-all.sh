#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

if [ ! -d config ]; then
    echo "NOTE: symlinking config.template into config (make a copy to make local changes)"
    ln -s config.template config
fi
if [ ! -f .env ]; then
    echo "NOTE: symlinking .env.template into .env (make a copy to make local changes)"
    ln -s .env.template .env
fi

echo "initializing database"
scripts/init-db.sh
echo "initializing rabbitmq"
scripts/init-rabbitmq.sh
echo "initializing hydra"
scripts/init-hydra.sh
echo "creating hydra test clients"
sleep 0.1
scripts/create-hydra-test-clients.sh
