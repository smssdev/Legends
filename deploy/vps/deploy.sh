#!/bin/sh
# [X48] Deploys the committed code (HEAD) to our server, from the repository's root on Suliman's machine:
#   sh deploy/vps/deploy.sh
# The code goes over SSH (the repository is private, the server needs no GitHub key), then the image is rebuilt and
# the game restarted. The database stays in its volume. Deploy when the admin panel says it is safe (no live match).
set -e
HOST="${LEGENDS_HOST:-root@2.24.47.100}"
KEY="${LEGENDS_KEY:-$HOME/.ssh/legends_vps}"
ssh_() { ssh -i "$KEY" -o BatchMode=yes "$HOST" "$@"; }
# [X64] LEGENDS_HOST=local: run on the server itself (legends-deploy), the same steps without SSH.
[ "$HOST" = local ] && ssh_() { sh -c "$1"; }

# The admin panel's "safe to deploy" [X33], asked of the running game: no match live now or kicking off within 30
# minutes (a rebuild restarts the game). LEGENDS_FORCE=1 deploys anyway. A first deploy (no game yet) goes on.
busy=$(ssh_ 'docker exec legends-app-1 php artisan matches:live --soon=30 2>/dev/null || echo 0' | tail -n 1)
# No answer at all is no way to the server (the key, SSH), not a safe one.
[ -n "$busy" ] || { echo "Cannot reach the server (${HOST})."; exit 1; }
if [ "${busy:-0}" -gt 0 ] 2>/dev/null && [ "${LEGENDS_FORCE:-0}" != "1" ]; then
  echo "Not safe to deploy: ${busy} match(es) live or kicking off within 30 minutes. Try again after them (or LEGENDS_FORCE=1)."
  exit 2
fi
echo "Safe to deploy: no match live or due within 30 minutes."

# [Sprint 21 E8.7] The disk first: a build needs room, and a full disk stops the database. Under 2 GB free, stop here.
ssh_ 'free=$(df -Pm / | awk "NR==2 {print \$4}"); echo "Disk: ${free} MB free"; [ "$free" -ge 2048 ] || {
  echo "Under 2 GB free: clean up first (docker image prune -a, docker builder prune). The pgdata volume is never touched."; exit 1; }'

# Only what the image is built from (Dockerfile), not the audio, Unity and logo sources (hundreds of MB).
git archive --format=tar.gz HEAD Dockerfile .dockerignore backend data web docs/design docs/api/frame-golden.json deploy | ssh_ 'rm -rf /opt/legends/src.new && mkdir -p /opt/legends/src.new && tar -xz -C /opt/legends/src.new \
  && rm -rf /opt/legends/src && mv /opt/legends/src.new /opt/legends/src'

# The secrets, made once on the server: the database password and the app key's seed.
ssh_ 'test -f /opt/legends/.env || { umask 077; {
  echo "PUBLIC_URL=https://srv2100776.hstgr.cloud"
  echo "DB_PASSWORD=$(openssl rand -hex 24)"
  echo "APP_KEY_SEED=$(openssl rand -hex 32)"
} > /opt/legends/.env; echo "Made /opt/legends/.env"; }
grep -q "^REVERB_APP_SECRET=" /opt/legends/.env || echo "REVERB_APP_SECRET=$(openssl rand -hex 24)" >> /opt/legends/.env'

# The server's tools: legends-set (a secret, typed on the server), legends-deploy (a deploy from the server itself, X64)
# and legends-backup (daily at 03:00 Cairo, 01:00 UTC).
ssh_ 'install -m 755 /opt/legends/src/deploy/vps/set.sh /usr/local/bin/legends-set \
  && install -m 755 /opt/legends/src/deploy/vps/server-deploy.sh /usr/local/bin/legends-deploy \
  && install -m 755 /opt/legends/src/deploy/vps/backup.sh /usr/local/bin/legends-backup \
  && { command -v rclone > /dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq rclone > /dev/null; } \
  && echo "0 1 * * * root /usr/local/bin/legends-backup >> /var/log/legends-backup.log 2>&1" > /etc/cron.d/legends-backup \
  && echo "*/5 * * * * root docker exec legends-app-1 php artisan server:health --notify > /dev/null 2>&1" > /etc/cron.d/legends-health'
# [Sprint 21 E8.7] Every 5 minutes the health check (the disk among it) alerts the phones by ntfy when NTFY_TOPIC is set.

ssh_ 'cd /opt/legends/src/deploy/vps && docker compose --env-file /opt/legends/.env up -d --build && docker image prune -f > /dev/null'
# The backups volume is made by Docker as root: the game (www-data) writes its copies there before each migrate.
ssh_ 'docker exec -u root legends-app-1 chown www-data:www-data /app/backend/database/backups'
ssh_ 'sleep 20; docker logs --tail 30 legends-app-1'
