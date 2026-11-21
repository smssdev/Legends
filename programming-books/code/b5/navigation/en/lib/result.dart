import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: const MenuPage()),
  );
}

class Drink {
  const Drink(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final int price;
  final String image;
}

const drinks = [
  Drink('Latte', 'Espresso and steamed milk', 45, 'assets/images/latte.png'),
  Drink('Mint tea', 'Black tea with fresh mint', 25, 'assets/images/tea.png'),
  Drink('Orange juice', 'Freshly squeezed', 40, 'assets/images/juice.png'),
  Drink('Cherry cake', 'Sponge, jam and cream', 60, 'assets/images/cake.png'),
];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Future<void> open(BuildContext context, Drink drink) async {
    // push returns a Future: the page's answer, when it closes.
    final count = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => OrderPage(drink: drink)),
    );
    // null: the customer went back without adding anything.
    if (count == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added $count × ${drink.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          for (final drink in drinks)
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
              title: Text(drink.name),
              subtitle: Text('${drink.price} EGP'),
              onTap: () => open(context, drink),
            ),
        ],
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.drink});

  final Drink drink;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(widget.drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.drink.description),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Fewer',
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontSize: 22)),
              ),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  // pop closes this page and gives the answer back.
                  onPressed: () => Navigator.pop(context, quantity),
                  child: Text('Add $quantity to order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
