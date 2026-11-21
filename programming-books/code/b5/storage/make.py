"""Writes the examples of Book 5, chapter "Saving Data on the Device", in English and Arabic,
photographs them after real taps (and after closing and opening the app again), and runs their tests.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; downloads the packages once)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import flutter_gallery  # noqa: E402

T = {
    "en": dict(
        w_rtl="", w_egp="EGP",
        w_latte="Latte", w_tea="Mint tea", w_juice="Orange juice", w_cake="Cherry cake", w_cookie="Cookie",
        w_settings="Settings", w_dark="Dark mode", w_big="Large text",
        w_sample="Bit Café is open every day from 8:00 to 22:00.",
        w_c_engine="Plugins need the engine ready before runApp.",
        w_c_load="Read what was saved before the first frame: no flash of the wrong theme.",
        w_c_first="Change the screen first, then save: nobody waits for the disk.",
        w_t_settings="a setting survives opening the app again",
        w_favs="Favourites", w_like="Like", w_unlike="Unlike",
        w_c_list="Preferences keep lists of strings: save the ids, not the names.",
        w_t_favs="the hearts survive opening the app again",
        w_c_folder="The folder is given, so tests can give a temporary one.",
        w_c_nofile="The first time there is no file yet: an empty history, not an error.",
        w_c_swap="Write a new file, then swap it in: a crash halfway never leaves half a file.",
        w_t_file="the history is written to a file and read back",
        w_sara="Sara", w_omar="Omar",
        w_c_table="The table is created once, the first time the database is opened.",
        w_c_args="Values go in whereArgs, never inside the SQL text.",
        w_t_db="notes are added, searched, ticked and removed",
        w_n1="Buy milk", w_n2="Call the bakery", w_n3="Buy cups", w_n_word="Buy",
        # Projects
        w_cups="Cups today", w_more="One more", w_reset="Reset",
        w_search="Search the menu", w_recent="Recent searches", w_clear="Clear",
        w_t_recent="the newest first, no repeats, five at most",
        w_c_recent="The newest first, no repeats, five at most.",
        w_q1="tea", w_q2="cake", w_q3="latte",
        w_basket="Basket", w_add="Add", w_items="items", w_total="Total",
        w_c_version="A basket saved by another version of the app is dropped, not misread.",
        w_c_damaged="A damaged value: start with an empty basket, and forget it.",
        w_c_keys="JSON keys are always strings: the ids are written as text.",
        w_t_basket="the basket survives, and a damaged value does not crash",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_egp="جنيه",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_juice="عصير برتقال", w_cake="كيك الكرز", w_cookie="كوكيز",
        w_settings="الإعدادات", w_dark="الوضع الليلي", w_big="نص كبير",
        w_sample="مقهى بِت مفتوح من 8:00 إلى 22:00 كل يوم.",
        w_c_engine="الإضافات تحتاج المحرك جاهزاً قبل runApp.",
        w_c_load="اقرأ ما حُفظ قبل أول إطار: فلا يومض الثيم الخطأ.",
        w_c_first="غيّر الشاشة أولاً، ثم احفظ: فلا ينتظر أحد القرص.",
        w_t_settings="الإعداد يبقى بعد فتح التطبيق من جديد",
        w_favs="المفضلة", w_like="أعجبني", w_unlike="ألغِ الإعجاب",
        w_c_list="التفضيلات تحفظ قوائم نصوص: احفظ الأرقام، لا الأسماء.",
        w_t_favs="القلوب تبقى بعد فتح التطبيق من جديد",
        w_c_folder="المجلد يُعطى من الخارج، فتستطيع الاختبارات أن تعطي مجلداً مؤقتاً.",
        w_c_nofile="في المرة الأولى لا ملف بعد: سجل فارغ، لا خطأ.",
        w_c_swap="اكتب ملفاً جديداً ثم ضعه مكان القديم: فالانهيار في المنتصف لا يترك نصف ملف أبداً.",
        w_t_file="السجل يُكتب في ملف ويُقرأ من جديد",
        w_sara="سارة", w_omar="عمر",
        w_c_table="الجدول يُنشأ مرة واحدة، أول مرة تُفتح فيها قاعدة البيانات.",
        w_c_args="القيم توضع في whereArgs، لا داخل نص SQL أبداً.",
        w_t_db="الملاحظات تُضاف وتُبحث وتُعلَّم وتُحذف",
        w_n1="اشترِ حليباً", w_n2="اتصل بالمخبز", w_n3="اشترِ أكواباً", w_n_word="اشترِ",
        w_cups="أكواب اليوم", w_more="كوب آخر", w_reset="صفّر",
        w_search="ابحث في القائمة", w_recent="عمليات البحث الأخيرة", w_clear="امسح",
        w_t_recent="الأحدث أولاً، بلا تكرار، وخمسة على الأكثر",
        w_c_recent="الأحدث أولاً، بلا تكرار، وخمسة على الأكثر.",
        w_q1="شاي", w_q2="كيك", w_q3="لاتيه",
        w_basket="السلة", w_add="أضف", w_items="قطع", w_total="الإجمالي",
        w_c_version="السلة المحفوظة بنسخة أخرى من التطبيق تُترك، ولا تُقرأ خطأً.",
        w_c_damaged="قيمة تالفة: ابدأ بسلة فارغة، وانسها.",
        w_c_keys="مفاتيح JSON نصوص دائماً: فالأرقام تُكتب نصاً.",
        w_t_basket="السلة تبقى، والقيمة التالفة لا تُسقط التطبيق",
    ),
}

DRINKS = """const drinks = [
  (id: 1, name: '{w_latte}', price: 45),
  (id: 2, name: '{w_tea}', price: 25),
  (id: 3, name: '{w_juice}', price: 40),
  (id: 4, name: '{w_cake}', price: 60),
  (id: 5, name: '{w_cookie}', price: 20),
];
"""

FILES = {
    "lib/settings_app.dart": """import 'package:material_ui/material_ui.dart';
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

  // {w_c_first}
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
  // {w_c_engine}
  WidgetsFlutterBinding.ensureInitialized();
  final settings = Settings(SharedPreferencesAsync());
  // {w_c_load}
  await settings.load();
  runApp(ChangeNotifierProvider.value(value: settings, child: const SettingsApp()));
}

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<Settings, bool>((s) => s.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(colorSchemeSeed: Colors.brown, brightness: Brightness.dark),
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
      appBar: AppBar(title: const Text('{w_settings}')),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('{w_dark}'), value: settings.dark, onChanged: settings.setDark),
          SwitchListTile(title: const Text('{w_big}'), value: settings.big, onChanged: settings.setBig),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('{w_sample}', style: TextStyle(fontSize: settings.big ? 24 : 16)),
          ),
        ],
      ),
    );
  }
}
""",
    "test/settings_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/settings_app.dart';

void main() {
  setUp(() {
    // A pretend disk, in memory: every test starts with nothing saved.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('{w_t_settings}', () async {
    final first = Settings(SharedPreferencesAsync());
    await first.load();
    expect(first.dark, isFalse);
    await first.setDark(true);

    // A new Settings is the app opened again: it reads what the first one saved.
    final again = Settings(SharedPreferencesAsync());
    await again.load();
    expect(again.dark, isTrue);
    expect(again.big, isFalse);
  });
}
""",
    "lib/favourites_app.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

""" + DRINKS + """
class Favourites extends ChangeNotifier {
  Favourites(this.prefs);

  final SharedPreferencesAsync prefs;
  final _ids = <int>{};

  bool has(int id) => _ids.contains(id);
  int get count => _ids.length;

  Future<void> load() async {
    final saved = await prefs.getStringList('favourites') ?? [];
    _ids.addAll(saved.map(int.parse));
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    if (!_ids.remove(id)) {
      _ids.add(id);
    }
    notifyListeners();
    // {w_c_list}
    await prefs.setStringList('favourites', [for (final id in _ids) '$id']);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final favourites = Favourites(SharedPreferencesAsync());
  await favourites.load();
  runApp(
    ChangeNotifierProvider.value(
      value: favourites,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const FavouritesPage(),
      ),
    ),
  );
}

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favourites = context.watch<Favourites>();
    return Scaffold(
      appBar: AppBar(title: Text('{w_favs}: ${favourites.count}')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              trailing: IconButton(
                tooltip: '${favourites.has(drink.id) ? '{w_unlike}' : '{w_like}'} ${drink.name}',
                icon: favourites.has(drink.id)
                    ? const Icon(Icons.favorite, color: Colors.red)
                    : const Icon(Icons.favorite_border),
                onPressed: () => context.read<Favourites>().toggle(drink.id),
              ),
            ),
        ],
      ),
    );
  }
}
""",
    "test/favourites_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/favourites_app.dart';

void main() {
  test('{w_t_favs}', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final first = Favourites(SharedPreferencesAsync());
    await first.load();
    await first.toggle(2);
    await first.toggle(4);
    await first.toggle(2);

    final again = Favourites(SharedPreferencesAsync());
    await again.load();
    expect(again.has(4), isTrue);
    expect(again.has(2), isFalse);
    expect(await SharedPreferencesAsync().getStringList('favourites'), ['4']);
  });
}
""",
    "lib/order_book.dart": """import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Order {
  const Order(this.name, this.total);

  factory Order.fromJson(Map<String, dynamic> json) => Order(json['name'] as String, json['total'] as int);

  final String name;
  final int total;

  Map<String, Object> toJson() => {'name': name, 'total': total};
}

// The order history, in one JSON file in the app's own folder.
class OrderBook {
  // {w_c_folder}
  OrderBook({Future<Directory> Function()? folder}) : folder = folder ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() folder;

  Future<File> get _file async => File('${(await folder()).path}/orders.json');

  Future<List<Order>> load() async {
    final file = await _file;
    // {w_c_nofile}
    if (!await file.exists()) {
      return [];
    }
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return [for (final item in list) Order.fromJson(item as Map<String, dynamic>)];
  }

  Future<void> add(Order order) async {
    final all = [...await load(), order];
    final file = await _file;
    // {w_c_swap}
    final next = File('${file.path}.new');
    await next.writeAsString(jsonEncode([for (final o in all) o.toJson()]));
    await next.rename(file.path);
  }
}
""",
    "test/order_book_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/order_book.dart';

void main() {
  test('{w_t_file}', () async {
    // A real folder on the disk, made for this test and removed after it.
    final dir = await Directory.systemTemp.createTemp('orders');
    addTearDown(() => dir.delete(recursive: true));

    final book = OrderBook(folder: () async => dir);
    expect(await book.load(), isEmpty);
    await book.add(const Order('{w_sara}', 105));
    await book.add(const Order('{w_omar}', 40));

    final again = OrderBook(folder: () async => dir);
    expect([for (final o in await again.load()) o.name], ['{w_sara}', '{w_omar}']);
    expect(
      File('${dir.path}/orders.json').readAsStringSync(),
      '[{"name":"{w_sara}","total":105},{"name":"{w_omar}","total":40}]',
    );
  });
}
""",
    "lib/notes_db.dart": """import 'package:sqflite/sqflite.dart';

class Note {
  const Note({this.id, required this.text, this.done = false});

  factory Note.fromRow(Map<String, Object?> row) =>
      Note(id: row['id'] as int, text: row['text'] as String, done: row['done'] == 1);

  final int? id;
  final String text;
  final bool done;

  // SQLite has no true or false: 1 and 0.
  Map<String, Object?> toRow() => {'id': id, 'text': text, 'done': done ? 1 : 0};
}

class NotesDb {
  NotesDb._(this.db);

  final Database db;

  static Future<NotesDb> open(String path, {DatabaseFactory? factory}) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        // {w_c_table}
        onCreate: (db, version) => db.execute(
          'CREATE TABLE notes (id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, done INTEGER NOT NULL)',
        ),
      ),
    );
    return NotesDb._(db);
  }

  Future<int> add(String text) => db.insert('notes', Note(text: text).toRow());

  Future<List<Note>> all() async => [for (final row in await db.query('notes', orderBy: 'id')) Note.fromRow(row)];

  // {w_c_args}
  Future<List<Note>> search(String word) async => [
    for (final row in await db.query('notes', where: 'text LIKE ?', whereArgs: ['%$word%'])) Note.fromRow(row),
  ];

  Future<void> setDone(int id, bool done) =>
      db.update('notes', {'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  Future<void> remove(int id) => db.delete('notes', where: 'id = ?', whereArgs: [id]);

  Future<void> close() => db.close();
}
""",
    "test/notes_db_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bit_app/notes_db.dart';

void main() {
  // On a computer, tests reach SQLite through FFI; on a phone, sqflite uses the system's own SQLite.
  setUpAll(sqfliteFfiInit);

  test('{w_t_db}', () async {
    final notes = await NotesDb.open(inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(notes.close);

    final milk = await notes.add('{w_n1}');
    await notes.add('{w_n2}');
    await notes.add('{w_n3}');
    expect(milk, 1);

    expect([for (final n in await notes.search('{w_n_word}')) n.text], ['{w_n1}', '{w_n3}']);

    await notes.setDone(milk, true);
    await notes.remove(2);
    final all = await notes.all();
    expect([for (final n in all) n.text], ['{w_n1}', '{w_n3}']);
    expect(all.first.done, isTrue);
  });
}
""",
    # Projects
    "projects/cups.dart": """import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: const CupsPage(),
    ),
  );
}

class CupsPage extends StatefulWidget {
  const CupsPage({super.key});

  @override
  State<CupsPage> createState() => _CupsPageState();
}

class _CupsPageState extends State<CupsPage> {
  final prefs = SharedPreferencesAsync();
  int? cups;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final saved = await prefs.getInt('cups') ?? 0;
    if (mounted) {
      setState(() => cups = saved);
    }
  }

  Future<void> change(int value) async {
    setState(() => cups = value);
    await prefs.setInt('cups', value);
  }

  @override
  Widget build(BuildContext context) {
    final cups = this.cups;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_cups}')),
      // Until the saved number arrives, show nothing rather than a wrong 0.
      body: cups == null
          ? const SizedBox()
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Text('$cups', style: Theme.of(context).textTheme.displayLarge),
                  FilledButton.icon(
                    onPressed: () => change(cups + 1),
                    icon: const Icon(Icons.coffee),
                    label: const Text('{w_more}'),
                  ),
                  TextButton(onPressed: () => change(0), child: const Text('{w_reset}')),
                ],
              ),
            ),
    );
  }
}
""",
    "projects/recent.dart": """import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Recent extends ChangeNotifier {
  Recent(this.prefs);

  final SharedPreferencesAsync prefs;
  var words = <String>[];

  Future<void> load() async {
    words = await prefs.getStringList('recent') ?? [];
    notifyListeners();
  }

  Future<void> add(String word) async {
    final w = word.trim();
    if (w.isEmpty) {
      return;
    }
    // {w_c_recent}
    words = [w, ...words.where((old) => old != w)].take(5).toList();
    notifyListeners();
    await prefs.setStringList('recent', words);
  }

  Future<void> clear() async {
    words = [];
    notifyListeners();
    await prefs.remove('recent');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recent = Recent(SharedPreferencesAsync());
  await recent.load();
  runApp(
    ChangeNotifierProvider.value(
      value: recent,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const SearchPage(),
      ),
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<Recent>();
    return Scaffold(
      appBar: AppBar(title: const Text('{w_search}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: field,
            decoration: const InputDecoration(labelText: '{w_search}', prefixIcon: Icon(Icons.search)),
            onSubmitted: (text) {
              context.read<Recent>().add(text);
              field.clear();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('{w_recent}', style: Theme.of(context).textTheme.titleMedium)),
              TextButton(onPressed: recent.words.isEmpty ? null : recent.clear, child: const Text('{w_clear}')),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final word in recent.words)
                ActionChip(
                  avatar: const Icon(Icons.history),
                  label: Text(word),
                  onPressed: () => field.text = word,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
""",
    "test/recent_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/projects_recent.dart';

void main() {
  test('{w_t_recent}', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final recent = Recent(SharedPreferencesAsync());
    await recent.load();
    for (final word in ['a', 'b', 'c', 'd', 'e', 'f', 'b', ' ']) {
      await recent.add(word);
    }
    expect(recent.words, ['b', 'f', 'e', 'd', 'c']);

    final again = Recent(SharedPreferencesAsync());
    await again.load();
    expect(again.words, ['b', 'f', 'e', 'd', 'c']);
  });
}
""",
    "projects/saved_basket.dart": """import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

""" + DRINKS + """
class Basket extends ChangeNotifier {
  Basket(this.prefs);

  final SharedPreferencesAsync prefs;
  final counts = <int, int>{};

  int get count => counts.values.fold(0, (sum, n) => sum + n);
  int get total => drinks.fold(0, (sum, d) => sum + d.price * (counts[d.id] ?? 0));

  Future<void> load() async {
    final text = await prefs.getString('basket');
    if (text == null) {
      return;
    }
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      // {w_c_version}
      if (json['version'] != 1) {
        return;
      }
      final known = {for (final d in drinks) d.id};
      for (final MapEntry(:key, :value) in (json['items'] as Map<String, dynamic>).entries) {
        final id = int.parse(key);
        // A drink that left the menu leaves the basket too.
        if (known.contains(id)) {
          counts[id] = value as int;
        }
      }
    } catch (e) {
      // {w_c_damaged}
      counts.clear();
      await prefs.remove('basket');
    }
    notifyListeners();
  }

  Future<void> add(int id) async {
    counts[id] = (counts[id] ?? 0) + 1;
    notifyListeners();
    // {w_c_keys}
    await prefs.setString(
      'basket',
      jsonEncode({
        'version': 1,
        'items': {for (final e in counts.entries) '${e.key}': e.value},
      }),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final basket = Basket(SharedPreferencesAsync());
  await basket.load();
  runApp(
    ChangeNotifierProvider.value(
      value: basket,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        {w_rtl}
        theme: ThemeData(colorSchemeSeed: Colors.brown),
        home: const BasketPage(),
      ),
    ),
  );
}

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final basket = context.watch<Basket>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('{w_basket}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Badge(label: Text('${basket.count}'), child: const Icon(Icons.shopping_basket)),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} {w_egp}'),
              leading: CircleAvatar(child: Text('${basket.counts[drink.id] ?? 0}')),
              trailing: IconButton(
                tooltip: '{w_add} ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => context.read<Basket>().add(drink.id),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '{w_total}: ${basket.total} {w_egp}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
""",
    "test/saved_basket_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:bit_app/projects_saved_basket.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('{w_t_basket}', () async {
    final first = Basket(SharedPreferencesAsync());
    await first.load();
    await first.add(1);
    await first.add(1);
    await first.add(4);

    final again = Basket(SharedPreferencesAsync());
    await again.load();
    expect(again.count, 3);
    expect(again.total, 150);
  });

  test('a damaged value, or one from another version, gives an empty basket', () async {
    for (final saved in ['not json', '[1, 2]', '{"version": 2, "items": {"1": 3}}', '{"version": 1, "items": {"1": "x"}}']) {
      await SharedPreferencesAsync().setString('basket', saved);
      final basket = Basket(SharedPreferencesAsync());
      await basket.load();
      expect(basket.count, 0, reason: saved);
    }
  });
}
""",
}

SHOTS = [
    ("settings.png", "lib/settings_app.dart", "switch={w_dark}|switch={w_big}|reload=1"),
    ("favourites.png", "lib/favourites_app.dart", "button={w_like} {w_tea}|button={w_like} {w_cake}|reload=1"),
    ("cups.png", "projects/cups.dart", "button={w_more}|button={w_more}|button={w_more}|reload=1"),
    ("recent.png", "projects/recent.dart",
     "type={w_search}=>{w_q1}\n|type={w_search}=>{w_q2}\n|type={w_search}=>{w_q3}\n|type={w_search}=>{w_q1}\n|reload=1"),
    ("saved-basket.png", "projects/saved_basket.dart",
     "button={w_add} {w_latte}|button={w_add} {w_latte}|button={w_add} {w_cake}|reload=1"),
]

TESTS = [
    ("settings-test.sh", "test/settings_test.dart"),
    ("favourites-test.sh", "test/favourites_test.dart"),
    ("order-book-test.sh", "test/order_book_test.dart"),
    ("notes-db-test.sh", "test/notes_db_test.dart"),
    ("projects/recent-test.sh", "test/recent_test.dart"),
    ("projects/saved-basket-test.sh", "test/saved_basket_test.dart"),
]


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=[
        "provider", "shared_preferences", "path_provider", "sqflite",
        "dev:sqflite_common_ffi", "dev:shared_preferences_platform_interface",
    ])


if __name__ == "__main__":
    main()
