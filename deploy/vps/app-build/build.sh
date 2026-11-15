#!/bin/sh
# [X104] Inside the builder (Dockerfile beside it): the repository on /src, the game's key on /key (read only), the
# caches on /cache. Installs Flutter and the Android SDK once, builds with mobile/tool/ship_apk.sh (SHIP_LOCAL: the
# server publishes, not the script), then checks the two APKs are signed with that key and nothing else.
set -e
: "${FLUTTER_VERSION:?FLUTTER_VERSION}"
git config --global --add safe.directory '*'

# Flutter at the version CI names (.github/workflows/mobile.yml), cloned once per version.
if [ "$(git -C /cache/flutter describe --tags --exact-match 2>/dev/null)" != "$FLUTTER_VERSION" ]; then
  echo "Installing Flutter $FLUTTER_VERSION (once)..."
  rm -rf /cache/flutter
  git -c advice.detachedHead=false clone -q --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git /cache/flutter
fi
flutter --disable-analytics > /dev/null 2>&1 || true
flutter --version | head -n 1

# The Android SDK's command-line tools, once; Gradle fetches the platform, build tools and NDK the project asks for.
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "Installing the Android SDK tools (once)..."
  mkdir -p "$ANDROID_HOME/cmdline-tools" && cd /tmp
  curl -fsSL -o tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  rm -rf cmdline-tools && unzip -q tools.zip && rm tools.zip
  rm -rf "$ANDROID_HOME/cmdline-tools/latest" && mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  yes | sdkmanager --licenses > /dev/null 2>&1 || true
  sdkmanager "platform-tools" > /dev/null
fi

# The server is small and the game runs beside the build: Gradle's memory from the host (app.sh), not the project's 8 GB,
# and the Kotlin compiler inside Gradle's own process (no second JVM). The user home's properties win over the project's.
mkdir -p "$GRADLE_USER_HOME"
cat > "$GRADLE_USER_HOME/gradle.properties" <<PROPS
org.gradle.jvmargs=-Xmx${GRADLE_XMX:-1536m} -XX:MaxMetaspaceSize=512m -XX:+UseSerialGC
org.gradle.daemon=false
org.gradle.workers.max=${GRADLE_WORKERS:-2}
kotlin.compiler.execution.strategy=in-process
PROPS

cd /src/mobile
flutter pub get > /dev/null
# Once more after a failure: a download refused on the way (Maven Central's "too many requests") is fetched again,
# and what came the first time is in the cache already.
GLM_KEYSTORE=/key/glm-release.jks SHIP_LOCAL=1 sh tool/ship_apk.sh \
  || { echo "Failed: trying once more in a minute..."; sleep 60; GLM_KEYSTORE=/key/glm-release.jks SHIP_LOCAL=1 sh tool/ship_apk.sh; }

# Signed with the game's key, its fingerprint the one assetlinks.json gives (app.sh writes it to the server's settings).
signer=$(ls -d "$ANDROID_HOME"/build-tools/*/ | sort -V | tail -n 1)apksigner
want=$(keytool -list -v -keystore /key/glm-release.jks -storepass "$GLM_KEYSTORE_PASSWORD" -alias "$GLM_KEY_ALIAS" \
  | sed -n 's/^[[:space:]]*SHA256: *//p' | head -n 1)
for f in build/ship/*.apk; do
  got=$("$signer" verify --print-certs "$f" | sed -n 's/.*certificate SHA-256 digest: *//p')
  [ "$(echo "$got" | wc -l)" = 1 ] || { echo "$f: not one signer."; exit 1; }
  [ "$(echo "$got" | tr -d ':' | tr a-f A-F)" = "$(echo "$want" | tr -d ':' | tr a-f A-F)" ] \
    || { echo "$f is not signed with the game's key ($got)."; exit 1; }
done
echo "$want" > build/ship/cert-sha256.txt
echo "Signed with the game's key: $want"
