#!/bin/sh
# Test certificates for the pinning tests: self-signed, for localhost, made on every run, never committed.
mkdir -p test/certs
for name in pinned next other; do
  openssl req -x509 -newkey rsa:2048 -nodes -days 2 -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost" -keyout test/certs/$name.key -out test/certs/$name.pem 2>/dev/null
done
ls test/certs
