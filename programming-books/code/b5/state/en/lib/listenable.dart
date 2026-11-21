import 'package:material_ui/material_ui.dart';

import 'basket.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CafePage(basket: Basket()),
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

class CafePage extends StatelessWidget {
  const CafePage({super.key, required this.basket});

  final Basket basket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              title: Text(drink.name),
              subtitle: Text('${drink.price} EGP'),
              trailing: IconButton(
                tooltip: 'Add ${drink.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => basket.add(drink.name, drink.price),
              ),
            ),
        ],
      ),
      // ListenableBuilder rebuilds its builder whenever the basket notifies.
      bottomNavigationBar: ListenableBuilder(
        listenable: basket,
        builder: (context, child) => Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(20),
          child: Text('${basket.count} items · Total ${basket.total} EGP'),
        ),
      ),
    );
  }
}
