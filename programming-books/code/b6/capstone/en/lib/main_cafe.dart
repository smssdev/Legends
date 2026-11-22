import 'package:material_ui/material_ui.dart';

import 'cafe_app.dart';
import 'observe/crashes.dart';

// Everything starts here: reporting first, then the app with its real dependencies.
void main() {
  Crashes((report) => debugPrint('report: $report')).install();
  runApp(cafe());
}
