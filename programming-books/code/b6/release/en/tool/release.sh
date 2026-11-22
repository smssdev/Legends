#!/bin/sh
# A release build only from a safe state: signing password present, build number higher than the last.
set -e
BUILD_NUMBER=${1:?usage: tool/release.sh BUILD_NUMBER}
if [ -z "$STORE_PASSWORD" ]; then
  echo "refusing: STORE_PASSWORD is not set, the build could not be signed" >&2
  exit 1
fi
LAST=$(cat release/last_build_number 2>/dev/null || echo 0)
if [ "$BUILD_NUMBER" -le "$LAST" ]; then
  echo "refusing: build $BUILD_NUMBER is not higher than the last release, $LAST" >&2
  exit 1
fi
flutter build apk --release --flavor prod --dart-define-from-file=config/prod.json \
  -t lib/main_app.dart --build-name=1.4.0 --build-number="$BUILD_NUMBER"
mkdir -p release
echo "$BUILD_NUMBER" > release/last_build_number
