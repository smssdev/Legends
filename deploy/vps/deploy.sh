#!/bin/sh
# [X48] Deploys the committed code (HEAD) to our server, from the repository's root on Suliman's machine:
#   sh deploy/vps/deploy.sh
# The code goes over SSH (the repository is private, the server needs no GitHub key), then the image is rebuilt and
# the game restarted. The database stays in its volume. Deploy when the admin panel says it is safe (no live match).
set -e
HOST="${LEGENDS_HOST:-root@2.24.47.100}"
KEY="${LEGENDS_KEY:-$HOME/.ssh/legends_vps}"
ssh_() { ssh -i "$KEY" -o BatchMode=yes "$HOST" "$@"; }

git archive --format=tar HEAD | ssh_ 'rm -rf /opt/legends/src.new && mkdir -p /opt/legends/src.new && tar -x -C /opt/legends/src.new \
  && rm -rf /opt/legends/src && mv /opt/legends/src.new /opt/legends/src'

# The secrets, made once on the server: the database password and the app key's seed.
ssh_ 'test -f /opt/legends/.env || { umask 077; {
  echo "PUBLIC_URL=https://srv2100776.hstgr.cloud"
  echo "DB_PASSWORD=$(openssl rand -hex 24)"
  echo "APP_KEY_SEED=$(openssl rand -hex 32)"
} > /opt/legends/.env; echo "Made /opt/legends/.env"; }'

ssh_ 'cd /opt/legends/src/deploy/vps && docker compose --env-file /opt/legends/.env up -d --build && docker image prune -f > /dev/null'
ssh_ 'sleep 20; docker logs --tail 30 legends-app-1'
