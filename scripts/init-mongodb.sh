#!/bin/sh

# fail on errors
set -e

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack. The working directory must be the root of faf-stack."
    exit 1
fi

MAX_WAIT=360 # max. 5 minute waiting time in loop before timeout

docker-compose up -d faf-mongodb
docker-compose logs -f faf-mongodb &
log_process_id=$!

echo "Waiting for faf-mongodb"
current_wait=0
while ! docker exec -it faf-mongodb mongo --eval 'quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)' >/dev/null 2>&1
do
  if [ ${current_wait} -ge ${MAX_WAIT} ]; then
    echo "Timeout on startup of faf-mongodb"
    kill -TERM ${log_process_id}
    exit 1
  fi
  current_wait=$((current_wait+1))
  sleep 1
done

kill -TERM ${log_process_id}

echo "Create mongodb database and user for nodebb"
. config/faf-mongodb/faf-mongodb.env
docker exec -i faf-mongodb mongo -u "${MONGO_INITDB_ROOT_USERNAME}" -p "${MONGO_INITDB_ROOT_PASSWORD}" <<MONGODB_SCRIPT
    use ${MONGO_NODEBB_DATABASE};
    db.createUser( { user: "${MONGO_NODEBB_USERNAME}", pwd: "${MONGO_NODEBB_PASSWORD}", roles: [ "readWrite" ] } );
    db.grantRolesToUser("${MONGO_NODEBB_USERNAME}",[{ role: "clusterMonitor", db: "admin" }]);
MONGODB_SCRIPT
