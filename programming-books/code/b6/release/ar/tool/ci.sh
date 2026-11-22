#!/bin/sh
# ما يشغّله CI مع كل push، وما تستطيع تشغيله قبل الـ push: توقف عند أول فشل.
set -e
echo "== format"
dart format --output=none --set-exit-if-changed lib test
echo "== analyze"
flutter analyze
echo "== test"
flutter test
echo "== build"
flutter build web --release --dart-define-from-file=config/prod.json -t lib/main_app.dart
