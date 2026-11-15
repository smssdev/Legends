#!/bin/sh
# [Sprint 15 D1, 2026-11-06; Sprint 71 N2, N3, N7] Builds the Android app (one APK per phone type, obfuscated) and puts
# it on our server's downloads volume, where the site's download page and /api/v1/app/android.apk offer it at once: no
# deploy and no upload from the admin panel. Run from anywhere in the repository, on Suliman's machine:
#
#   sh mobile/tool/ship_apk.sh            build from a clean main, check, upload
#   SHIP_LOCAL=1 sh mobile/tool/ship_apk.sh   build and check only (the files stay in mobile/build/ship)
#   SHIP_ANY=1 ...                        from another branch or with changes not committed (a trial, never for players)
#
# The release is signed with the game's fixed key when GLM_KEYSTORE and its three companions are set (Sprint 62 F1);
# without them the build falls back to the debug key, and this script refuses to upload it.
set -e
cd "$(dirname "$0")/.."
HOST="${LEGENDS_HOST:-root@2.24.47.100}"
KEY="${LEGENDS_KEY:-$HOME/.ssh/legends_vps}"
MAX_MB="${SHIP_MAX_MB:-25}"

# Only what main holds reaches the players: the same code the site was deployed from.
if [ "${SHIP_ANY:-0}" != "1" ]; then
  branch=$(git rev-parse --abbrev-ref HEAD)
  [ "$branch" = "main" ] || { echo "Not on main (on $branch): switch to main, or SHIP_ANY=1 for a trial."; exit 1; }
  [ -z "$(git status --porcelain --untracked-files=no -- .)" ] || { echo "Changes in mobile/ are not committed: commit or stash them first."; exit 1; }
fi
if [ "${SHIP_LOCAL:-0}" != "1" ] && [ "${SHIP_ANY:-0}" != "1" ]; then
  [ -n "$GLM_KEYSTORE" ] && [ -f "$GLM_KEYSTORE" ] || { echo "GLM_KEYSTORE is not set: the build would be signed with the debug key. Set the four GLM_ variables (Sprint 62 F1), or SHIP_LOCAL=1 to only build."; exit 1; }
fi

flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols

full=$(sed -n 's/^version: \([0-9A-Za-z.+-]*\).*/\1/p' pubspec.yaml)
version=${full%%+*}
build=${full#*+}
[ "$build" = "$full" ] && build=0
commit=$(git rev-parse --short=12 HEAD)
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
out=build/ship
rm -rf "$out" && mkdir -p "$out"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$out/GameLegendManager.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$out/GameLegendManager-old-phones.apk"

# [N7] The size limit (it lived only in the disabled CI): over it, the ten largest files say where the weight is.
for f in "$out"/*.apk; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  echo "$(basename "$f"): $((bytes / 1048576)) MB ($bytes bytes)"
  if [ "$bytes" -gt $((MAX_MB * 1048576)) ]; then
    echo "Over ${MAX_MB} MB. Its largest files:"
    unzip -l "$f" | sort -k1 -n -r | head -n 12
    exit 1
  fi
done
size=$(wc -c < "$out/GameLegendManager.apk" | tr -d ' ')
printf '{\n  "version": "%s",\n  "build": %s,\n  "built_at": "%s",\n  "commit": "%s",\n  "size": %s,\n  "file": "GameLegendManager.apk",\n  "old_phones": "GameLegendManager-old-phones.apk",\n  "notes": null\n}\n' \
  "$version" "$build" "$built_at" "$commit" "$size" > "$out/android.json"
echo "Built GameLegendManager $version+$build from $commit."

if [ "${SHIP_LOCAL:-0}" = "1" ]; then
  echo "SHIP_LOCAL=1: not uploaded. The files are in mobile/$out."
  exit 0
fi

# To the server's downloads volume (deploy/vps/compose.yml): the two files first, android.json last, so the page never
# names a version whose file is not whole yet.
ssh_() { ssh -i "$KEY" -o BatchMode=yes "$HOST" "$@"; }
ssh_ 'rm -rf /opt/legends/app.new && mkdir -p /opt/legends/app.new' || { echo "Cannot reach the server (${HOST})."; exit 1; }
scp -i "$KEY" -o BatchMode=yes "$out/GameLegendManager.apk" "$out/GameLegendManager-old-phones.apk" "$out/android.json" "$HOST:/opt/legends/app.new/"
ssh_ 'set -e; d=/app/backend/storage/app/downloads/bundled
docker exec -u root legends-app-1 mkdir -p $d
docker cp /opt/legends/app.new/GameLegendManager.apk legends-app-1:$d/GameLegendManager.apk
docker cp /opt/legends/app.new/GameLegendManager-old-phones.apk legends-app-1:$d/GameLegendManager-old-phones.apk
docker cp /opt/legends/app.new/android.json legends-app-1:$d/android.json
docker exec -u root legends-app-1 chown -R www-data:www-data /app/backend/storage/app/downloads
docker exec legends-app-1 php artisan cache:forget app.latest_version > /dev/null 2>&1 || true
rm -rf /opt/legends/app.new'
echo "On the server: GameLegendManager $version+$build. Check https://gamelegendmanager.online/download"
