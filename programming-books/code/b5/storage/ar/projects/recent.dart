import 'package:material_ui/material_ui.dart';
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
    // الأحدث أولاً، بلا تكرار، وخمسة على الأكثر.
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
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

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
      appBar: AppBar(title: const Text('ابحث في القائمة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: field,
            decoration: const InputDecoration(
              labelText: 'ابحث في القائمة',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (text) {
              context.read<Recent>().add(text);
              field.clear();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'عمليات البحث الأخيرة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: recent.words.isEmpty ? null : recent.clear,
                child: const Text('امسح'),
              ),
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
