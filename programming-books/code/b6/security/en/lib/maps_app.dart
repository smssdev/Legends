import 'package:material_ui/material_ui.dart';

// Compiled into the app: anyone with the app can read it.
const mapsKey = String.fromEnvironment('MAPS_KEY');

final tiles = Uri.https('maps.example.com', '/tiles', {'key': mapsKey});

void main() => runApp(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Maps key length: ${tiles.queryParameters['key']!.length}'),
      ),
    ),
  ),
);
