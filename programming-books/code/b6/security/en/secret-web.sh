$ flutter build web -t lib/maps_app.dart --dart-define=MAPS_KEY=cafe-maps-key-DEMO-0000
✓ Built build/web
$ grep -o "cafe-maps-key-DEMO-0000" build/web/main.dart.js
cafe-maps-key-DEMO-0000
