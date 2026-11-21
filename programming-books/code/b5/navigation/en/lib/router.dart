import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp.router(debugShowCheckedModeBanner: false, routerConfig: router),
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

// Every screen has an address, like a website.
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuPage(),
      routes: [
        // :id is a parameter: /drinks/2 shows drink number 2.
        GoRoute(
          path: 'drinks/:id',
          builder: (context, state) =>
              DrinkPage(index: int.parse(state.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          for (var i = 0; i < drinks.length; i++)
            ListTile(
              title: Text(drinks[i].name),
              // go: change the address; the router shows the page for it.
              onTap: () => context.go('/drinks/$i'),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final drink = drinks[index];
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(drink.image, height: 240, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(drink.description),
          ),
        ],
      ),
    );
  }
}
