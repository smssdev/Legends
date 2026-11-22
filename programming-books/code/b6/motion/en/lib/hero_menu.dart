import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const MenuPage(),
    ),
  );
}

const drinks = [
  ('latte', 'Latte', Colors.brown),
  ('tea', 'Mint tea', Colors.green),
  ('juice', 'Orange juice', Colors.orange),
];

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          for (final (id, name, color) in drinks)
            ListTile(
              // The same tag on both pages: Flutter flies the circle from one to the other.
              leading: Hero(
                tag: id,
                child: CircleAvatar(
                  backgroundColor: color,
                  child: const Icon(Icons.local_cafe, color: Colors.white),
                ),
              ),
              title: Text(name),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DrinkPage(id: id, name: name, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DrinkPage extends StatelessWidget {
  const DrinkPage({
    super.key,
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Hero(
              tag: id,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: color,
                child: const Icon(
                  Icons.local_cafe,
                  color: Colors.white,
                  size: 96,
                ),
              ),
            ),
            Text(
              'Espresso and steamed milk, in a big cup.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
