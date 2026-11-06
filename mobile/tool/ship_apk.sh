#!/bin/sh
# [Sprint 15 D1, 2026-11-06] Builds the Android app (one APK per phone type, obfuscated) and puts it inside the site
# (web/public/downloads), with its version from pubspec.yaml: after the next deploy the download page and
# /api/v1/app/android.apk offer it directly, without an upload from the admin panel. Run from the repository root.
set -e
cd "$(dirname "$0")/.."
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols
version=$(sed -n 's/^version: \([0-9.]*\).*/\1/p' pubspec.yaml)
out=../web/public/downloads
mkdir -p "$out"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$out/GameLegendManager.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$out/GameLegendManager-old-phones.apk"
printf '{\n  "version": "%s",\n  "file": "GameLegendManager.apk",\n  "old_phones": "GameLegendManager-old-phones.apk",\n  "notes": null\n}\n' "$version" > "$out/android.json"
echo "web/public/downloads: GameLegendManager $version"
