#!/bin/sh
# [X104, 2026-11-15] Builds the Android app on our server from the latest main, signs it with the game's key (kept on
# this server) and puts it on the download page: a phone is enough. Installed as legends-app by deploy.sh. In hPanel →
# VPS → Web console:
#   legends-app          build and publish (in the background: the console may close; about 30 minutes the first
#                        time, while it installs Flutter and the Android SDK, then about 10)
#   legends-app log      follow the build (Ctrl+C stops following, not the build)
#
# The key: /opt/legends/app-key (glm-release.jks and key.env), made here on the first build when it is not there, its
# fingerprint written to ANDROID_CERT_SHA256 (assetlinks.json). legends-backup keeps a copy of it (in B2 too when set):
# losing it means no update installs over the app on the phones. A key made elsewhere goes in the same two files.
# Not while a match is live or due within 45 minutes (the build takes the server's processor); LEGENDS_FORCE=1 anyway.
set -e
LOG=/var/log/legends-app.log
ENV=/opt/legends/.env
KEYDIR=/opt/legends/app-key
REPO=/opt/legends/repo
LOCK=/opt/legends/app-build.lock

if [ "$1" = log ]; then exec tail -n 40 -f "$LOG"; fi
# The build goes on without the console: the same script again, detached, its output in the log.
if [ "${LEGENDS_APP_CHILD:-0}" != 1 ]; then
  [ ! -d "$LOCK" ] || { echo "A build is running already: legends-app log"; exit 1; }
  : > "$LOG"
  LEGENDS_APP_CHILD=1 setsid nohup sh "$0" "$@" >> "$LOG" 2>&1 < /dev/null &
  echo "The build started. Follow it: legends-app log"
  sleep 3; tail -n 20 "$LOG"; exit 0
fi
mkdir "$LOCK" 2>/dev/null || { echo "A build is running already."; exit 1; }
trap 'rmdir "$LOCK"' EXIT
echo "== $(date -u +%Y-%m-%dT%H:%M:%SZ) legends-app"
env_() { grep -m 1 "^$1=" "$ENV" 2>/dev/null | cut -d= -f2-; }
notify() { t=$(env_ NTFY_TOPIC); [ -z "$t" ] || curl -s -m 10 -d "$1" "https://ntfy.sh/$t" > /dev/null || true; }
fail() { echo "$1"; notify "GLM app: $1"; exit 1; }

busy=$(docker exec legends-app-1 php artisan matches:live --soon=45 2>/dev/null | tail -n 1)
if [ "${busy:-0}" -gt 0 ] 2>/dev/null && [ "${LEGENDS_FORCE:-0}" != 1 ]; then
  fail "Not now: ${busy} match(es) live or due within 45 minutes. Try after them (or LEGENDS_FORCE=1 legends-app)."
fi
free=$(df -Pm / | awk 'NR==2 {print $4}')
echo "Disk: ${free} MB free"
[ "$free" -ge 8192 ] || fail "Under 8 GB free: the first build needs about 6 GB (docker image prune -a, docker builder prune)."

# The latest main, with the server's read-only deploy key (legends-deploy makes it, X64).
GH_KEY="$HOME/.ssh/legends_github"
[ -f "$GH_KEY" ] || fail "No GitHub key on the server yet: run legends-deploy once, it says what to add in GitHub."
export GIT_SSH_COMMAND="ssh -i $GH_KEY -o StrictHostKeyChecking=accept-new"
[ -d "$REPO" ] || git clone -q --depth 1 --filter=blob:none git@github.com:smssdev/Legends.git "$REPO"
cd "$REPO" && git fetch -q --depth 1 origin main && git checkout -q -f -B main FETCH_HEAD && git clean -q -fdx -e mobile/build
echo "Building: $(git log --oneline -1)"
FLUTTER_VERSION=$(sed -n 's/^ *flutter-version: *\([0-9.]*\).*/\1/p' .github/workflows/mobile.yml | head -n 1)

docker build -q -t legends-appbuild deploy/vps/app-build > /dev/null

# The game's key: made once, here, when there is none (no app signed with a fixed key was ever published before it).
if [ ! -f "$KEYDIR/glm-release.jks" ]; then
  echo "Making the game's signing key (once)..."
  mkdir -p "$KEYDIR" && chmod 700 "$KEYDIR"
  pass=$(openssl rand -hex 24)
  docker run --rm -v "$KEYDIR:/key" --entrypoint keytool legends-appbuild -genkeypair -keystore /key/glm-release.jks \
    -storetype PKCS12 -alias glm -keyalg RSA -keysize 4096 -validity 10000 -storepass "$pass" -keypass "$pass" \
    -dname "CN=Game Legend Manager, O=Legends" > /dev/null
  printf 'GLM_KEYSTORE_PASSWORD=%s\nGLM_KEY_PASSWORD=%s\nGLM_KEY_ALIAS=glm\n' "$pass" "$pass" > "$KEYDIR/key.env"
  chmod 600 "$KEYDIR"/*
  /usr/local/bin/legends-backup > /dev/null 2>&1 || true
fi

# Memory: what is free now, less a margin for the game; the build is the one stopped if it runs out, never the game.
avail=$(awk '/MemAvailable/ {print int($2 / 1024)}' /proc/meminfo)
limit=$((avail - 400)); [ "$limit" -le 3584 ] || limit=3584
[ "$limit" -ge 1800 ] || fail "Only ${avail} MB of memory free: not enough to build beside the game."
xmx=$((limit * 45 / 100))
echo "Memory for the build: ${limit} MB (Gradle ${xmx} MB)"

rm -rf mobile/build/ship
docker run --rm --name legends-appbuild --memory "${limit}m" --memory-swap "${limit}m" --cpu-shares 128 \
  -e FLUTTER_VERSION="$FLUTTER_VERSION" -e GRADLE_XMX="${xmx}m" --env-file "$KEYDIR/key.env" \
  -v "$REPO:/src" -v "$KEYDIR:/key:ro" -v legends-appbuild-cache:/cache legends-appbuild \
  || fail "The build failed: legends-app log shows why."

# Its fingerprint in the server's settings (assetlinks.json): the game restarts once, the first time only.
print=$(cat mobile/build/ship/cert-sha256.txt)
old=$(env_ ANDROID_CERT_SHA256)
case ",$old," in *",$print,"*) ;; *)
  grep -v '^ANDROID_CERT_SHA256=' "$ENV" > "$ENV.tmp" || true
  echo "ANDROID_CERT_SHA256=$print${old:+,$old}" >> "$ENV.tmp"; chmod 600 "$ENV.tmp"; mv "$ENV.tmp" "$ENV"
  (cd /opt/legends/src/deploy/vps && docker compose --env-file "$ENV" up -d --wait --wait-timeout 300 > /dev/null 2>&1) || true
  echo "ANDROID_CERT_SHA256 set: the game restarted." ;;
esac

# To the downloads volume (as mobile/tool/ship_apk.sh): the two files first, android.json last.
d=/app/backend/storage/app/downloads/bundled
docker exec -u root legends-app-1 mkdir -p $d
for f in GameLegendManager.apk GameLegendManager-old-phones.apk android.json; do
  docker cp "mobile/build/ship/$f" "legends-app-1:$d/$f"
done
docker exec -u root legends-app-1 chown -R www-data:www-data /app/backend/storage/app/downloads
docker exec legends-app-1 php artisan cache:forget app.latest_version > /dev/null 2>&1 || true
version=$(sed -n 's/.*"version": "\(.*\)".*/\1/p' mobile/build/ship/android.json)
echo "Published: GameLegendManager $version. https://gamelegendmanager.online/download"
notify "GLM app $version is on the download page."
