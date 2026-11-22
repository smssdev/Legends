#!/bin/sh
# شهادات لاختبارات التثبيت: موقَّعة ذاتياً، لـ localhost، تُصنع في كل تشغيل، ولا تُحفظ في المستودع.
mkdir -p test/certs
for name in pinned next other; do
  openssl req -x509 -newkey rsa:2048 -nodes -days 2 -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost" -keyout test/certs/$name.key -out test/certs/$name.pem 2>/dev/null
done
ls test/certs
