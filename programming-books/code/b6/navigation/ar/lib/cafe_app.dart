import 'package:material_ui/material_ui.dart';

import 'cafe/auth.dart';
import 'cafe/router.dart';

void main() {
  final router = buildRouter(Auth());
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      routerConfig: router,
    ),
  );
}
