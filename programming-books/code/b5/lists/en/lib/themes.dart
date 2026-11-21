import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemesApp());
}

class ThemesApp extends StatefulWidget {
  const ThemesApp({super.key});

  @override
  State<ThemesApp> createState() => _ThemesAppState();
}

class _ThemesAppState extends State<ThemesApp> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Two themes from the same seed: one light, one dark.
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.brown,
        brightness: Brightness.dark,
      ),
      // themeMode chooses which of the two is used.
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Bit Café')),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Dark mode'),
              secondary: const Icon(Icons.dark_mode),
              value: dark,
              onChanged: (value) => setState(() => dark = value),
            ),
            const Divider(),
            for (final drink in drinks)
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(drink.image)),
                title: Text(drink.name),
                trailing: Text('${drink.price} EGP'),
              ),
          ],
        ),
      ),
    );
  }
}

class Drink {
  const Drink(this.name, this.description, this.price, this.image);

  final String name;
  final String description;
  final int price;
  final String image;
}

// The data: one object per drink, in a const list.
const drinks = [
  Drink('Latte', 'Espresso and steamed milk', 45, 'assets/images/latte.png'),
  Drink('Mint tea', 'Black tea with fresh mint', 25, 'assets/images/tea.png'),
  Drink('Orange juice', 'Freshly squeezed', 40, 'assets/images/juice.png'),
  Drink('Cherry cake', 'Sponge, jam and cream', 60, 'assets/images/cake.png'),
  Drink('Cookie', 'With chocolate chips', 20, 'assets/images/cookie.png'),
  Drink('Muffin', 'Chocolate, baked today', 35, 'assets/images/muffin.png'),
];
