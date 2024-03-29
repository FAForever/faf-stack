#!/bin/sh

# fail on errors
set -e

if [ ! -f faf-extra.yml ]; then
    echo "You are not inside faf-stack. The working directory must be the root of faf-stack."
    exit 1
fi


if [ -d "./data/nodebb" ]; then
    echo "nodebb directory already exists! Installation aborted."
    exit 1
fi

echo "Fixing config permissions"
sudo chown -R 1000:1000 ./config/extra/nodebb
sudo chmod -R g+w ./config/extra/nodebb

echo "Setting up nodebb data directories (using sudo)"
sudo mkdir -p ./data/nodebb/build
sudo mkdir -p ./data/nodebb/node_modules
sudo mkdir -p ./data/nodebb/uploads
sudo chown -R 1000:1000 ./data/nodebb

#docker-compose run --rm faf-nodebb sh -c "npm install && npm cache clean --force"
docker-compose -f faf-extra.yml run --rm -u node nodebb sh -c "./nodebb setup \
&& npm install nodebb-plugin-sso-oauth-faforever \
&& ./nodebb activate nodebb-plugin-sso-oauth-faforever \
&& ./nodebb build"

echo "NodeBB setup done! Don't forget to write down the admin accounts password!"
