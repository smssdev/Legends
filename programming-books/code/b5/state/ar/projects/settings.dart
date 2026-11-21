import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Settings(),
      child: const SettingsApp(),
    ),
  );
}

class Settings extends ChangeNotifier {
  bool _dark = false;
  bool _big = false;
  bool get dark => _dark;
  bool get big => _big;

  set dark(bool value) {
    _dark = value;
    notifyListeners();
  }

  set big(bool value) {
    _big = value;
    notifyListeners();
  }
}

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return MaterialApp(
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: settings.big ? 1.3 : 1,
        maxScaleFactor: settings.big ? 1.3 : 1,
        child: const SettingsPage(),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Settings>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('الوضع الداكن'),
            value: settings.dark,
            onChanged: (v) => context.read<Settings>().dark = v,
          ),
          SwitchListTile(
            title: const Text('نص كبير'),
            value: settings.big,
            onChanged: (v) => context.read<Settings>().big = v,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('مقهى بِت مفتوح كل يوم من 8:00 إلى 22:00.'),
          ),
        ],
      ),
    );
  }
}
