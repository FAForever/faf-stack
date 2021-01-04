#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

docker-compose run --rm faf-ory-hydra clients create \
    --skip-tls-verify \
    --endpoint https://faf-ory-hydra:4445 \
    --id faf-website \
    --name faforever.com \
    --logo-uri https://faforever.com/images/faf-logo.png \
    --secret banana \
    --grant-types authorization_code,refresh_token \
    --response-types code \
    --scope openid,offline,public_profile,write_account_data,create_user \
    --callbacks https://test.faforever.com/callback,http://localhost:3000/callback
