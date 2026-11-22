#!/bin/sh
set -e
echo "== format"
dart format --output=none --set-exit-if-changed lib test
echo "== analyze"
flutter analyze
echo "== test"
flutter test --coverage
echo "== build"
flutter build web --release -t lib/main_cafe.dart
