#!/bin/sh
# Everything before a release, in order; stop at the first failure.
set -e
echo "1. No problems in the code"
flutter analyze
echo "2. Every test passes"
flutter test
echo "3. A signed bundle"
flutter build appbundle
echo "4. Signed with our key?"
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner
