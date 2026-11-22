import 'package:material_ui/material_ui.dart';

import 'cafe/auth.dart';
import 'cafe/router.dart';

void main() {
  final router = buildRouter(Auth());
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: router,
    ),
  );
}
