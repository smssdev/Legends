#!/bin/sh
# What CI runs on every push, and what you can run before pushing: stop at the first failure.
set -e
echo "== format"
dart format --output=none --set-exit-if-changed lib test
echo "== analyze"
flutter analyze
echo "== test"
flutter test
echo "== build"
flutter build web --release --dart-define-from-file=config/prod.json -t lib/main_app.dart
