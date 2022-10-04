#!/usr/bin/env bash

if [ ! -f docker-compose.yml ]; then
    echo "You are not inside faf-stack! The working directory must be the root of faf-stack."
    exit 1
fi

docker-compose exec faf-ory-hydra hydra clients create \
    --skip-tls-verify \
    --endpoint http://127.0.0.1:4445 \
    --fake-tls-termination \
    --id faf-lobby-server \
    --name faf-lobby-server \
    --secret banana \
    --scope write_achievements,write_events \
    --token-endpoint-auth-method client_secret_post \
    -g client_credentials

docker-compose exec faf-ory-hydra hydra clients create \
    --skip-tls-verify \
    --endpoint http://127.0.0.1:4445 \
    --fake-tls-termination \
    --id faf-website \
    --secret banana \
    --name faforever.com \
    --logo-uri https://faforever.com/images/faf-logo.png \
    --grant-types authorization_code,refresh_token \
    --response-types code \
    --scope openid,offline,public_profile,write_account_data,create_user \
    --callbacks https://test.faforever.com/callback,http://localhost:3000/callback,http://localhost:8020/callback

docker-compose exec faf-ory-hydra hydra clients create \
    --skip-tls-verify \
    --endpoint http://127.0.0.1:4445 \
    --fake-tls-termination \
    --id faf-java-client \
    --name fafClient \
    --logo-uri https://faforever.com/images/faf-logo.png \
    --grant-types authorization_code,refresh_token \
    --response-types code \
    --scope openid,offline,public_profile,lobby,upload_map,upload_mod \
    --callbacks http://localhost,http://localhost:57728,http://localhost:59573,http://localhost:58256,http://localhost:53037,http://localhost:51360 \
    --token-endpoint-auth-method none
	
docker-compose exec faf-ory-hydra hydra clients create \
    --skip-tls-verify \
    --endpoint http://127.0.0.1:4445 \
    --fake-tls-termination \
    --id faf-moderator-client \
    --name faf-moderator-client \
    --logo-uri https://faforever.com/images/faf-logo.png \
    --grant-types authorization_code,refresh_token \
    --response-types code \
    --scope upload_avatar,administrative_actions,read_sensible_userdata,manage_vault \
    --callbacks http://localhost \
    --token-endpoint-auth-method none

docker-compose exec faf-ory-hydra hydra clients create \
    --skip-tls-verify \
    --endpoint http://127.0.0.1:4445 \
    --fake-tls-termination \
    --id faf-forum \
    --name forum.faforever.com \
    --logo-uri https://faforever.com/images/faf-logo.png \
    --grant-types authorization_code,refresh_token \
    --response-types code \
    --token-endpoint-auth-method client_secret_post \
    --scope openid,public_profile \
    --callbacks http://localhost:4567/auth/faf-nodebb/callback
