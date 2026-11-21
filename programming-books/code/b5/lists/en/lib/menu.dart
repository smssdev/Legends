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

// The data: one object per drink, in a const list.
const drinks = [
  Drink('Latte', 'Espresso and steamed milk', 45, 'assets/images/latte.png'),
  Drink('Mint tea', 'Black tea with fresh mint', 25, 'assets/images/tea.png'),
  Drink('Orange juice', 'Freshly squeezed', 40, 'assets/images/juice.png'),
  Drink('Cherry cake', 'Sponge, jam and cream', 60, 'assets/images/cake.png'),
  Drink('Cookie', 'With chocolate chips', 20, 'assets/images/cookie.png'),
  Drink('Muffin', 'Chocolate, baked today', 35, 'assets/images/muffin.png'),
];

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Which drinks the customer likes: a Set, each name once.
  final favourites = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu · ${favourites.length} favourites')),
      // separated: a Divider between two items, never after the last one.
      body: ListView.separated(
        itemCount: drinks.length,
        separatorBuilder: (context, i) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final drink = drinks[i];
          final liked = favourites.contains(drink.name);
          return ListTile(
            // A picture from the app itself, declared in pubspec.yaml.
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                drink.image,
                width: 64,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(drink.name),
            subtitle: Text('${drink.description} · ${drink.price} EGP'),
            trailing: IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () => setState(() {
                liked
                    ? favourites.remove(drink.name)
                    : favourites.add(drink.name);
              }),
            ),
          );
        },
      ),
    );
  }
}
