import 'dart:convert';

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

class Basket extends ChangeNotifier {
  Basket(this.prefs);

  final SharedPreferencesAsync prefs;
  final counts = <int, int>{};

  int get count => counts.values.fold(0, (sum, n) => sum + n);
  int get total =>
      drinks.fold(0, (sum, d) => sum + d.price * (counts[d.id] ?? 0));

  Future<void> load() async {
    final text = await prefs.getString('basket');
    if (text == null) {
      return;
    }
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      // السلة المحفوظة بنسخة أخرى من التطبيق تُترك، ولا تُقرأ خطأً.
      if (json['version'] != 1) {
        return;
      }
      final known = {for (final d in drinks) d.id};
      for (final MapEntry(:key, :value)
          in (json['items'] as Map<String, dynamic>).entries) {
        final id = int.parse(key);
        // A drink that left the menu leaves the basket too.
        if (known.contains(id)) {
          counts[id] = value as int;
        }
      }
    } catch (e) {
      // قيمة تالفة: ابدأ بسلة فارغة، وانسها.
      counts.clear();
      await prefs.remove('basket');
    }
    notifyListeners();
  }

  Future<void> add(int id) async {
    counts[id] = (counts[id] ?? 0) + 1;
    notifyListeners();
    // مفاتيح JSON نصوص دائماً: فالأرقام تُكتب نصاً.
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
        // من اليمين إلى اليسار: يشرح الفصل 13 الطريقة الكاملة.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

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
        title: const Text('السلة'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Badge(
              label: Text('${basket.count}'),
              child: const Icon(Icons.shopping_basket),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} جنيه'),
              leading: CircleAvatar(
                child: Text('${basket.counts[drink.id] ?? 0}'),
              ),
              trailing: IconButton(
                tooltip: 'أضف ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => context.read<Basket>().add(drink.id),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'الإجمالي: ${basket.total} جنيه',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
