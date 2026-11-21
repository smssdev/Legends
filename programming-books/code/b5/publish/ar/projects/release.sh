#!/bin/sh
# كل ما قبل الإصدار، بالترتيب؛ وتوقف عند أول فشل.
set -e
echo "1. لا مشكلات في الكود"
flutter analyze
echo "2. كل الاختبارات تنجح"
flutter test
echo "3. حزمة موقّعة"
flutter build appbundle
echo "4. موقّعة بمفتاحنا؟"
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner
