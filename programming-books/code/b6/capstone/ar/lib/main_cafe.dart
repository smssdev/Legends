import 'package:material_ui/material_ui.dart';

import 'cafe_app.dart';
import 'observe/crashes.dart';

// كل شيء يبدأ هنا: البلاغات أولاً، ثم التطبيق باعتماداته الحقيقية.
void main() {
  Crashes((report) => debugPrint('report: $report')).install();
  runApp(cafe());
}
