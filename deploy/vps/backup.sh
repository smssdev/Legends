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

set -a; . /opt/legends/.env; set +a
if [ -n "${B2_BUCKET:-}" ] && [ -n "${B2_KEY_ID:-}" ] && [ -n "${B2_APPLICATION_KEY:-}" ]; then
  export RCLONE_CONFIG_B2_TYPE=b2 RCLONE_CONFIG_B2_ACCOUNT="$B2_KEY_ID" RCLONE_CONFIG_B2_KEY="$B2_APPLICATION_KEY"
  rclone copy "$file" "b2:$B2_BUCKET/vps-backups/"
  rclone delete "b2:$B2_BUCKET/vps-backups/" --min-age 30d
  echo "Backup: copied to B2 ($B2_BUCKET/vps-backups)"
else
  echo "Backup: on this server only (B2_BUCKET, B2_KEY_ID and B2_APPLICATION_KEY in /opt/legends/.env for a copy in B2)"
fi
