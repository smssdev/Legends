import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'basket.dart';

void main() {
  runApp(
    // Provide one basket above the whole app.
    ChangeNotifierProvider(
      create: (context) => Basket(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const MenuPage(),
      ),
    ),
  );
}

class Drink {
  const Drink(this.name, this.price);

  final String name;
  final int price;
}

const drinks = [
  Drink('Latte', 45),
  Drink('Mint tea', 25),
  Drink('Orange juice', 40),
  Drink('Cherry cake', 60),
];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: const [BasketButton()],
      ),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} EGP'),
              trailing: IconButton(
                tooltip: 'Add ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                // read: use the basket once, without listening (in callbacks).
                onPressed: () =>
                    context.read<Basket>().add(drink.name, drink.price),
              ),
            ),
        ],
      ),
    );
  }
}

class BasketButton extends StatelessWidget {
  const BasketButton({super.key});

  @override
  Widget build(BuildContext context) {
    // select: rebuild only when this one number changes.
    final count = context.select<Basket, int>((b) => b.count);
    return IconButton(
      tooltip: 'Basket',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BasketPage()),
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag),
      ),
    );
  }
}

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: read the basket, and rebuild when it changes.
    final basket = context.watch<Basket>();
    return Scaffold(
      appBar: AppBar(title: const Text('Basket')),
      body: basket.count == 0
          ? const Center(child: Text('Your basket is empty'))
          : ListView(
              children: [
                for (final MapEntry(key: name, value: n)
                    in basket.counts.entries)
                  ListTile(
                    title: Text('$n × $name'),
                    trailing: IconButton(
                      tooltip: 'Remove $name',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => basket.remove(name),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: basket.count == 0 ? null : () {},
          child: Text('Check out · ${basket.total} EGP'),
        ),
      ),
    );
  }
}
