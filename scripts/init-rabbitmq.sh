#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

MAX_WAIT=60 # max. 1 minute waiting time in loop before timeout

source config/faf-rabbitmq/faf-rabbitmq.env

docker-compose up -d faf-rabbitmq

# Create RabbitMQ users
docker-compose exec faf-rabbitmq rabbitmqctl wait --timeout ${MAX_WAIT} "${RABBITMQ_PID_FILE}"

echo -n "Waiting for rabbitmq status "
current_wait=0
while ! docker-compose exec faf-rabbitmq rabbitmqctl status >/dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of rabbitmq"
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done
echo ok

docker-compose exec faf-rabbitmq rabbitmqctl add_vhost "${RABBITMQ_FAF_VHOST}"
docker-compose exec faf-rabbitmq rabbitmqctl add_user "${RABBITMQ_FAF_LOBBY_USER}" "${RABBITMQ_FAF_LOBBY_PASS}"
docker-compose exec faf-rabbitmq rabbitmqctl set_permissions -p "${RABBITMQ_FAF_VHOST}" "${RABBITMQ_FAF_LOBBY_USER}" ".*" ".*" ".*"
docker-compose exec faf-rabbitmq rabbitmqctl add_user "${RABBITMQ_FAF_API_USER}" "${RABBITMQ_FAF_API_PASS}"
docker-compose exec faf-rabbitmq rabbitmqctl set_permissions -p "${RABBITMQ_FAF_VHOST}" "${RABBITMQ_FAF_API_USER}" ".*" ".*" ".*"
docker-compose exec faf-rabbitmq rabbitmqctl add_user "${RABBITMQ_FAF_LEAGUE_SERVICE_USER}" "${RABBITMQ_FAF_LEAGUE_SERVICE_PASS}"
docker-compose exec faf-rabbitmq rabbitmqctl set_permissions -p "${RABBITMQ_FAF_VHOST}" "${RABBITMQ_FAF_LEAGUE_SERVICE_USER}" ".*" ".*" ".*"
