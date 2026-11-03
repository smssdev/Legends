#!/bin/sh
# [X95] The game from zero, the owner's (2026-11-03), typed on the server only. Installed as legends-reset by
# deploy.sh. In hPanel → VPS → Web console:
#   legends-reset
# Says what goes and who stays, backs the whole database up first (legends-backup), then asks to type RESET GLM.
# Everything goes except the admins' accounts (they sign in again with their Gmail) and the game data (the clubs and
# players, the data editor's log, the admin's settings, the house ads). Back: the backup's line printed below.
set -e
docker exec legends-app-1 php artisan game:reset
echo
echo "A backup first..."
/usr/local/bin/legends-backup
# Kept apart from the daily copies (those keep 14 days): the game before the reset stays until deleted by hand.
latest=/opt/legends/backups/before-reset-$(date -u +%Y-%m-%dT%H%M).sql.gz
cp "$(ls -1t /opt/legends/backups/legends-*.sql.gz | head -n 1)" "$latest"
echo "Backup: $latest"
echo
printf "To empty the game for good, type RESET GLM: "
read -r words
[ "$words" = "RESET GLM" ] || { echo "Not typed: nothing changed."; exit 1; }
docker exec legends-app-1 php artisan game:reset --force
echo
echo "Done. To bring the old game back: gunzip -c $latest | docker exec -i legends-db-1 psql -U legends legends (into an empty database)."
