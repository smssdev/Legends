#!/bin/sh
# [Sprint 11 X1] Puts the Unity web build on our server, from the repository's root on Suliman's machine, after
# `unity\build.ps1 webgl`:
#   sh deploy/vps/unity.sh              the build named by today's date and the commit (2026.11.18-6fd7bc3)
#   sh deploy/vps/unity.sh NAME         under a name of its own (letters, digits, dots and dashes)
# The build (about 55 MB) goes over SSH into the downloads volume (downloads/unity/<build>/, served at /unity/<build>/:
# the Dockerfile links public/unity there, and Caddy sends it with a year's cache, each build under its own name), the
# last three builds stay, and UNITY_BUILD in /opt/legends/.env names the new one (GET /health unity_build), so the
# match screen loads it. The game restarts to read it (about 30 seconds): run it when the admin panel says it is safe.
# The code is not touched (deploy.sh does that); the volume is kept across deploys.
set -e
HOST="${LEGENDS_HOST:-root@2.24.47.100}"
KEY="${LEGENDS_KEY:-$HOME/.ssh/legends_vps}"
ssh_() { ssh -i "$KEY" -o BatchMode=yes "$HOST" "$@"; }
[ "$HOST" = local ] && ssh_() { sh -c "$1"; }

WEB=unity/Builds/WebGL
[ -f "$WEB/Build/WebGL.loader.js" ] || { echo "No web build in $WEB. Run first: powershell -ExecutionPolicy Bypass -File unity\\build.ps1 webgl"; exit 1; }
BUILD="${1:-$(date -u +%Y.%m.%d)-$(git rev-parse --short HEAD)}"
# The same rule as the server's (HealthController::unityBuild): it is a path on the site.
echo "$BUILD" | grep -Eq '^[A-Za-z0-9._-]{1,40}$' && ! echo "$BUILD" | grep -q '\.\.' || { echo "Not a build name: $BUILD"; exit 1; }

busy=$(ssh_ 'docker exec legends-app-1 php artisan matches:live --soon=30 2>/dev/null || echo 0' | tail -n 1)
[ -n "$busy" ] || { echo "Cannot reach the server (${HOST})."; exit 1; }
if [ "${busy:-0}" -gt 0 ] 2>/dev/null && [ "${LEGENDS_FORCE:-0}" != "1" ]; then
  echo "Not safe: ${busy} match(es) live or kicking off within 30 minutes (the game restarts). Try after them (or LEGENDS_FORCE=1)."
  exit 2
fi

DIR=/app/backend/storage/app/downloads/unity
echo "Uploading the build as $BUILD..."
tar -C "$WEB" -czf - Build $( [ -d "$WEB/StreamingAssets" ] && echo StreamingAssets ) |
  ssh_ "docker exec -i -u root legends-app-1 sh -c 'mkdir -p $DIR/$BUILD && tar -xzf - -C $DIR/$BUILD && chown -R www-data:www-data $DIR'"
# The last three builds stay (a screen still on the one before keeps loading it); the older ones go.
ssh_ "docker exec -u root legends-app-1 sh -c 'cd $DIR && ls -1t | tail -n +4 | xargs -r rm -rf'"

ssh_ "f=/opt/legends/.env; grep -v '^UNITY_BUILD=' \$f > \$f.tmp || true; echo UNITY_BUILD=$BUILD >> \$f.tmp; chmod 600 \$f.tmp; mv \$f.tmp \$f; cd /opt/legends/src/deploy/vps && docker compose --env-file \$f up -d > /dev/null 2>&1"
echo "UNITY_BUILD=$BUILD. Waiting for the game to come back..."
for i in $(seq 1 30); do
  got=$(ssh_ "docker exec legends-app-1 php -r 'echo json_decode(@file_get_contents(\"http://127.0.0.1:8000/api/v1/health\"), true)[\"unity_build\"] ?? \"\";'" 2>/dev/null || true)
  if [ "$got" = "$BUILD" ]; then
    echo "Done: the match screen loads /unity/$BUILD/ (the coach picks «المطوّر»)."
    exit 0
  fi
  sleep 5
done
echo "The game did not report the new build in time: docker logs --tail 50 legends-app-1"
exit 1
