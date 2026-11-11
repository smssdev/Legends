#!/bin/sh
# [X48] Sets one secret in /opt/legends/.env and restarts the game with it, typed on the server so it never passes
# through a chat or the repository. Installed as legends-set by deploy.sh. In hPanel → VPS → Web console:
#   legends-set GOOGLE_CLIENT_SECRET
set -e
key="$1"
[ -n "$key" ] || { echo "Usage: legends-set NAME"; exit 1; }
printf "%s = " "$key"; stty -echo 2>/dev/null || true; read -r value; stty echo 2>/dev/null || true; echo
[ -n "$value" ] || { echo "Empty, nothing changed"; exit 1; }
f=/opt/legends/.env
grep -v "^$key=" "$f" > "$f.tmp" || true
printf "%s=%s\n" "$key" "$value" >> "$f.tmp"
chmod 600 "$f.tmp"; mv "$f.tmp" "$f"
# [Sprint 52] Every service reads the secrets: each one whose settings changed restarts.
cd /opt/legends/src/deploy/vps && docker compose --env-file "$f" up -d > /dev/null 2>&1
echo "Saved $key. The game is restarting (about 30 seconds)."
