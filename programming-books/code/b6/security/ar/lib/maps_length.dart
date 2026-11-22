import 'package:material_ui/material_ui.dart';

const mapsKey = String.fromEnvironment('MAPS_KEY');

// The first version: it shows only the key's length.
void main() => runApp(
  MaterialApp(
    home: Scaffold(
      body: Center(child: Text('طول مفتاح الخرائط: ${mapsKey.length}')),
    ),
  ),
);
