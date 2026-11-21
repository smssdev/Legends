import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const drinks = [
  (id: 1, name: 'Latte', price: 45),
  (id: 2, name: 'Mint tea', price: 25),
  (id: 3, name: 'Orange juice', price: 40),
  (id: 4, name: 'Cherry cake', price: 60),
  (id: 5, name: 'Cookie', price: 20),
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
      // A basket saved by another version of the app is dropped, not misread.
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
      // A damaged value: start with an empty basket, and forget it.
      counts.clear();
      await prefs.remove('basket');
    }
    notifyListeners();
  }

  Future<void> add(int id) async {
    counts[id] = (counts[id] ?? 0) + 1;
    notifyListeners();
    // JSON keys are always strings: the ids are written as text.
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
        title: const Text('Basket'),
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
              subtitle: Text('${drink.price} EGP'),
              leading: CircleAvatar(
                child: Text('${basket.counts[drink.id] ?? 0}'),
              ),
              trailing: IconButton(
                tooltip: 'Add ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => context.read<Basket>().add(drink.id),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Total: ${basket.total} EGP',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
