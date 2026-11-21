import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        // As many columns as fit, each at most 200 pixels wide.
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: drinks.length,
          itemBuilder: (context, i) => Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BoxFit.cover fills the box and crops what does not fit.
                Expanded(
                  child: Image.asset(drinks[i].image, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    drinks[i].name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text('${drinks[i].price} EGP'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
