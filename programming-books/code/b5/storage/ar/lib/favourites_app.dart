import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const drinks = [
  (id: 1, name: 'لاتيه', price: 45),
  (id: 2, name: 'شاي بالنعناع', price: 25),
  (id: 3, name: 'عصير برتقال', price: 40),
  (id: 4, name: 'كيك الكرز', price: 60),
  (id: 5, name: 'كوكيز', price: 20),
];

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
    // التفضيلات تحفظ قوائم نصوص: احفظ الأرقام، لا الأسماء.
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
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

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
      appBar: AppBar(title: Text('المفضلة: ${favourites.count}')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} جنيه'),
              trailing: IconButton(
                tooltip:
                    '${favourites.has(drink.id) ? 'ألغِ الإعجاب' : 'أعجبني'} ${drink.name}',
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
