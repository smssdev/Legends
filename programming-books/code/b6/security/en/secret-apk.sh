$ flutter build apk --release --obfuscate --split-debug-info=build/symbols -t lib/maps_app.dart --dart-define=MAPS_KEY=cafe-maps-key-DEMO-0000
✓ Built build/app/outputs/flutter-apk/app-release.apk (41.5MB)
$ unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libapp.so | strings | grep cafe-maps-key-DEMO-0000
cafe-maps-key-DEMO-0000
