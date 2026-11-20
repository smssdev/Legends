#!/bin/sh
# توقف عند أول خطوة تفشل، وقل أيها
set -e
step() {
  printf '%s: ' "$1"
  shift
  if out=$("$@" 2>&1); then echo "ok"; else echo "FAILED"; echo "$out" | tail -4; echo "فشل الخط عند: $STEP"; exit 1; fi
}
STEP="فحص الأنواع";    step "$STEP" npx tsc
STEP="اختبارات العقد";    step "$STEP" node --test
# العقد على main: ما يستعمله العملاء اليوم
git show main:openapi.yaml > /tmp/openapi.main.yaml
STEP="التغييرات الكاسرة"; step "$STEP" node breaking.ts /tmp/openapi.main.yaml openapi.yaml
echo "نجح الخط"
