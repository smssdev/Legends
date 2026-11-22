import 'package:material_ui/material_ui.dart';

import 'config.dart';

void main() => runApp(const CafeApp());

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      title: 'بت كافيه',
      theme: ThemeData(
        colorSchemeSeed: AppConfig.isProduction ? Colors.brown : Colors.indigo,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('القائمة')),
        body: ListView(
          children: [
            const ListTile(
              leading: Icon(Icons.dns),
              title: Text('الخادم'),
              subtitle: Text(AppConfig.apiUrl),
            ),
            const ListTile(
              leading: Icon(Icons.layers),
              title: Text('النسخة'),
              subtitle: Text(AppConfig.flavor),
            ),
            if (AppConfig.showDebug)
              const ListTile(
                leading: Icon(Icons.bug_report),
                title: Text('أدوات التصحيح مفعّلة'),
              ),
          ],
        ),
      ),
    );
    // كل نسخة ليست للإنتاج تقول ذلك، في زاوية لا تفوت أحداً ولا يستخدمها شيء آخر.
    return AppConfig.isProduction
        ? app
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(
              message: AppConfig.flavor.toUpperCase(),
              location: BannerLocation.bottomEnd,
              child: app,
            ),
          );
  }
}
