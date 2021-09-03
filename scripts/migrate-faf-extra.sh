#!/usr/bin/env bash

# Run this script to migrate all apps from the new faf-extra.yml into the new directories

pushd /opt/faf

echo "Creating network faf-extra"
docker network create faf_faf-extra

echo "Add faf-db to network faf-extra"
docker network connect faf_faf-extra faf-db

echo "Stop faf-extra services"
docker stop faf-wiki faf-mongodb faf-nodebb faf-phpbb3-archive faf-unitdb faf_faf-voting_1
docker rm faf-wiki faf-mongodb faf-nodebb faf-phpbb3-archive faf-unitdb faf_faf-voting_1

mkdir config/extra

echo "Moving faf-wiki"
mv config/faf-wiki config/extra/mediawiki
mv config/extra/mediawiki/faf-wiki.env config/extra/mediawiki/mediawiki.env
mv data/faf-wiki data/mediawiki

echo "Moving faf-mongodb"
mv config/faf-mongodb config/extra/mongodb
mv data/faf-mongodb data/mongodb
mv config/extra/mongodb/faf-mongodb.env config/extra/mongodb/mongodb.env

echo "Moving faf-nodebb"
mv config/faf-nodebb config/extra/nodebb
mv config/extra/nodebb/faf-nodebb.env config/extra/nodebb/nodebb.env
sed -i 's/"host": "faf-mongodb"/"host": "mongodb"/g' config/extra/nodebb/config.json
mv data/faf-nodebb data/nodebb

echo "Moving faf-phpbb3-archive"
mv config/faf-phpbb3-archive config/extra/phpbb3-archive
mv data/faf-phpbb3-archive data/phpbb3-archive

echo "Moving config for faf-unitdb"
mv config/faf-unitdb config/extra/unitdb
mv config/extra/unitdb/faf-unitdb.env config/extra/unitdb/unitdb.env

echo "Moving config for faf-voting"
mv config/faf-voting config/extra/voting
mv config/extra/voting/faf-voting.env config/extra/voting/voting.env

echo "Restart faf-extra services"
docker-compose -f faf-extra.yml up -d mediawiki mongodb nodebb phpbb3-archive unitdb voting

popd