import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'menu.dart';

// بدائل لعمل حقيقي: قراءة الإعدادات، وفتح قاعدة البيانات، وجلب القائمة.
Future<void> readSettings() =>
    Future.delayed(const Duration(milliseconds: 300));
Future<void> openDatabase() =>
    Future.delayed(const Duration(milliseconds: 200));
Future<void> fetchMenu() => Future.delayed(const Duration(milliseconds: 400));

Future<void> startOneByOne() async {
  await readSettings();
  await openDatabase();
  await fetchMenu();
}

// الخطوات الثلاث لا تعتمد على بعضها: ابدأها معاً.
Future<void> startTogether() =>
    Future.wait([readSettings(), openDatabase(), fetchMenu()]).then((_) {});

// اعرض شيئاً فوراً؛ وحمّل الباقي خلفه.
void main() {
  final ready = startTogether();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: FutureBuilder(
        future: ready,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
            ? const MenuPage()
            : const Splash(),
      ),
    ),
  );
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [CircularProgressIndicator(), Text('نجهّز القائمة')],
      ),
    ),
  );
}
