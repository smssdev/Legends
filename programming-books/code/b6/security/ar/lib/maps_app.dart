import 'package:material_ui/material_ui.dart';

// مترجَم داخل التطبيق: يستطيع قراءته كل من يملك التطبيق.
const mapsKey = String.fromEnvironment('MAPS_KEY');

final tiles = Uri.https('maps.example.com', '/tiles', {'key': mapsKey});

void main() => runApp(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          'طول مفتاح الخرائط: ${tiles.queryParameters['key']!.length}',
        ),
      ),
    ),
  ),
);
