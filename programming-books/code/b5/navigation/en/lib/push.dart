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
              // push puts a new page on top; the bar gets a back button by itself.
              onTap: () => Navigator.push(
                context,
                // MaterialPageRoute: the page, with the platform's own animation.
                MaterialPageRoute(
                  builder: (context) => DrinkPage(drink: drink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  drink.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(drink.description),
                Text(
                  '${drink.price} EGP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
