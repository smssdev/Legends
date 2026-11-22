$ flutter build web -t lib/maps_length.dart --dart-define=MAPS_KEY=cafe-maps-key-DEMO-0000
✓ Built build/web
$ grep -c "cafe-maps-key-DEMO-0000" build/web/main.dart.js
0
