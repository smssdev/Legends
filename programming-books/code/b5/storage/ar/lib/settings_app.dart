import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  Settings(this.prefs);

  final SharedPreferencesAsync prefs;
  var dark = false;
  var big = false;

  Future<void> load() async {
    dark = await prefs.getBool('dark') ?? false;
    big = await prefs.getBool('big') ?? false;
    notifyListeners();
  }

  // غيّر الشاشة أولاً، ثم احفظ: فلا ينتظر أحد القرص.
  Future<void> setDark(bool value) async {
    dark = value;
    notifyListeners();
    await prefs.setBool('dark', value);
  }

  Future<void> setBig(bool value) async {
    big = value;
    notifyListeners();
    await prefs.setBool('big', value);
  }
}

void main() async {
  // الإضافات تحتاج المحرك جاهزاً قبل runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final settings = Settings(SharedPreferencesAsync());
  // اقرأ ما حُفظ قبل أول إطار: فلا يومض الثيم الخطأ.
  await settings.load();
  runApp(
    ChangeNotifierProvider.value(value: settings, child: const SettingsApp()),
  );
}

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<Settings, bool>((s) => s.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),

      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.brown,
        brightness: Brightness.dark,
      ),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const SettingsPage(),
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
            title: const Text('الوضع الليلي'),
            value: settings.dark,
            onChanged: settings.setDark,
          ),
          SwitchListTile(
            title: const Text('نص كبير'),
            value: settings.big,
            onChanged: settings.setBig,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'مقهى بِت مفتوح من 8:00 إلى 22:00 كل يوم.',
              style: TextStyle(fontSize: settings.big ? 24 : 16),
            ),
          ),
        ],
      ),
    );
  }
}
