import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'cafe_api.dart';
import 'menu_app.dart';

// The same app, pointed at an address where the server answers 500.
void main() => runApp(
  CafeApp(api: CafeApi(http.Client(), base: 'http://localhost:8080/broken')),
);
