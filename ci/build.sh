#!/bin/sh

if [ -z $CI ]; then
    echo "This script is only intended for Travis CI use. Do not run it on production. IT WILL DELETE YOUR DATABASE."
    exit 1
fi

cp -r config.template config
cp .env.template .env
wget "https://raw.githubusercontent.com/FAForever/db/$(grep -oP 'faforever/faf-db-migrations:\K(.*)$' ./docker-compose.yml)/test-data.sql"

scripts/init-db.sh
MAX_WAIT=360 # max. 5 minute waiting time in loop before timeout

docker-compose up -d faf-traefik
docker-compose up -d faf-java-api
docker-compose logs -f faf-java-api &
log_process_id=$!

echo "Waiting for faf-java-api"
current_wait=0
while ! curl -s --max-time 1 http://localhost:8010 > /dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of faf-java-api"
    kill ${log_process_id}
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done

kill ${log_process_id}

echo "Creating test-data in faf-db"
docker exec -i faf-db mysql -uroot -pbanana faf < test-data.sql

docker-compose -f k8s-archive/docker-compose.yml up -d faf-website
docker-compose -f k8s-archive/docker-compose.yml logs -f faf-website &
log_process_id=$!

echo "Waiting for faf-website"
current_wait=0
while ! curl -s --max-time 1 http://localhost:8020 >/dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of faf-website"
    kill ${log_process_id}
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done

kill ${log_process_id}

echo "Running test collection"
docker run --network="host" -t postman/newman:alpine run "https://raw.githubusercontent.com/FAForever/faf-stack/$(urlencode "${GITHUB_REF#refs/*/}")/tests/postman-collection.json"
