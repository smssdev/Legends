import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'delegates.dart';
import 'l10n/app_localizations.dart';

// اللغة التي اختارها الشخص، محفوظة على الجهاز.
class LanguageChoice extends ChangeNotifier {
  LanguageChoice(this.prefs);

  final SharedPreferencesAsync prefs;
  // null: اتبع لغة الجوال.
  Locale? locale;

  Future<void> load() async {
    final code = await prefs.getString('language');
    locale = code == null ? null : Locale(code);
    notifyListeners();
  }

  Future<void> choose(String? code) async {
    locale = code == null ? null : Locale(code);
    notifyListeners();
    if (code == null) {
      await prefs.remove('language');
    } else {
      await prefs.setString('language', code);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final choice = LanguageChoice(SharedPreferencesAsync());
  await choice.load();
  runApp(ChangeNotifierProvider.value(value: choice, child: const CafeApp()));
}

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // العنوان في قائمة التطبيقات المفتوحة، مترجماً هو أيضاً.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // نصوصنا، ونصوص Material نفسها (النوافذ، ومنتقي التاريخ، والتلميحات).
      localizationsDelegates: delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // null تترك Flutter يختار من لغات الجوال.
      locale: context.watch<LanguageChoice>().locale,
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  var count = 0;
  DateTime? day;

  Future<void> pick() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, 12, 3),
      firstDate: DateTime(2026, 11, 1),
      lastDate: DateTime(2027, 1, 31),
    );
    if (chosen != null) {
      setState(() => day = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    // كل نصوص الشاشة، باللغة الحالية.
    final l = AppLocalizations.of(context);
    final drinks = [(l.latte, 45), (l.tea, 25), (l.juice, 40), (l.cake, 60)];
    final day = this.day;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.language,
            icon: const Icon(Icons.translate),
            onSelected: (code) => context.read<LanguageChoice>().choose(
              code.isEmpty ? null : code,
            ),
            itemBuilder: (context) => [
              // كل لغة تُكتب بكلماتها هي، أياً كانت اللغة الآن.
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ar', child: Text('العربية')),
              PopupMenuItem(value: '', child: Text(l.system)),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            child: Text(
              l.welcome('Bit'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          for (final (name, price) in drinks)
            ListTile(
              leading: const Icon(Icons.local_cafe),
              title: Text(name),
              subtitle: Text(l.price(price)),
              trailing: IconButton(
                tooltip: l.addDrink(name),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => count++),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shopping_basket),
            title: Text(l.items(count)),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(day == null ? l.pickUp : l.pickUpOn(day)),
            trailing: const Icon(Icons.arrow_forward),
            onTap: pick,
          ),
        ],
      ),
    );
  }
}
