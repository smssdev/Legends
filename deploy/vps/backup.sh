#!/bin/sh
# [X48] The daily copy of the game: the whole PostgreSQL database, compressed, in /opt/legends/backups (the last 14),
# and in Backblaze B2 too when its four B2_* keys are in /opt/legends/.env (a copy off the server, the last 30 there).
# Installed as legends-backup with a daily cron by deploy.sh. Back: gunzip -c FILE | docker exec -i legends-db-1 psql
# -U legends legends, into an empty database only.
set -e
dir=/opt/legends/backups
mkdir -p "$dir"
file="$dir/legends-$(date -u +%Y-%m-%dT%H%M).sql.gz"
docker exec legends-db-1 pg_dump -U legends --no-owner legends | gzip -9 > "$file.tmp"
mv "$file.tmp" "$file"
ls -1t "$dir"/legends-*.sql.gz | tail -n +15 | xargs -r rm -f
echo "Backup: $file ($(du -h "$file" | cut -f1))"
# [X104] The app's signing key (legends-app): small, and without it no update installs over the app on the phones.
key=""
if [ -f /opt/legends/app-key/glm-release.jks ]; then
  key="$dir/app-key.tar.gz"
  tar -czf "$key" -C /opt/legends app-key && chmod 600 "$key"
  echo "Backup: the app's signing key in $key"
fi

# [X96] Read only the three B2 keys, never the file as shell: a value with spaces (a Gmail app password is shown in
# groups of four) would run as a command and stop the backup there.
env_() { grep -m 1 "^$1=" /opt/legends/.env 2>/dev/null | cut -d= -f2- | sed 's/^["'"'"']//; s/["'"'"']$//'; }
B2_BUCKET=$(env_ B2_BUCKET); B2_KEY_ID=$(env_ B2_KEY_ID); B2_APPLICATION_KEY=$(env_ B2_APPLICATION_KEY)
if [ -n "${B2_BUCKET:-}" ] && [ -n "${B2_KEY_ID:-}" ] && [ -n "${B2_APPLICATION_KEY:-}" ]; then
  export RCLONE_CONFIG_B2_TYPE=b2 RCLONE_CONFIG_B2_ACCOUNT="$B2_KEY_ID" RCLONE_CONFIG_B2_KEY="$B2_APPLICATION_KEY"
  rclone copy "$file" "b2:$B2_BUCKET/vps-backups/"
  rclone delete "b2:$B2_BUCKET/vps-backups/" --min-age 30d
  [ -z "$key" ] || rclone copy "$key" "b2:$B2_BUCKET/app-key/"
  echo "Backup: copied to B2 ($B2_BUCKET/vps-backups)"
else
  echo "Backup: on this server only (B2_BUCKET, B2_KEY_ID and B2_APPLICATION_KEY in /opt/legends/.env for a copy in B2)"
fi
