import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const CafePage()),
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

class CafePage extends StatefulWidget {
  const CafePage({super.key});

  @override
  State<CafePage> createState() => _CafePageState();
}

class _CafePageState extends State<CafePage> {
  // The basket lives in the parent; both children get it, and a way to change it.
  final basket = <Drink>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: DrinkList(onAdd: (drink) => setState(() => basket.add(drink))),
      bottomNavigationBar: BasketBar(basket: basket),
    );
  }
}

class DrinkList extends StatelessWidget {
  const DrinkList({super.key, required this.onAdd});

  // The list does not own the basket: it calls back up.
  final ValueChanged<Drink> onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final drink in drinks)
          ListTile(
            title: Text(drink.name),
            subtitle: Text('${drink.price} EGP'),
            trailing: IconButton(
              tooltip: 'Add ${drink.name}',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onAdd(drink),
            ),
          ),
      ],
    );
  }
}

class BasketBar extends StatelessWidget {
  const BasketBar({super.key, required this.basket});

  final List<Drink> basket;

  @override
  Widget build(BuildContext context) {
    final total = basket.fold(0, (sum, d) => sum + d.price);
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Text(
        '${basket.length} items · Total $total EGP',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
