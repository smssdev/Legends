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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            value: settings.dark,
            onChanged: (v) => context.read<Settings>().dark = v,
          ),
          SwitchListTile(
            title: const Text('Large text'),
            value: settings.big,
            onChanged: (v) => context.read<Settings>().big = v,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bit Café is open every day from 8:00 to 22:00.'),
          ),
        ],
      ),
    );
  }
}
