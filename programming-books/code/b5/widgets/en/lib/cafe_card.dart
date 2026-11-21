import 'package:material_ui/material_ui.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: DrinkCard(
            name: 'Latte',
            description: 'Espresso with steamed milk',
            price: 45,
          ),
        ),
      ),
    ),
  );
}

class DrinkCard extends StatefulWidget {
  const DrinkCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
  });

  final String name;
  final String description;
  final int price;

  @override
  State<DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<DrinkCard> {
  // How many the customer wants: starts at 1.
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.coffee, size: 48, color: Colors.brown),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(widget.description),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // The minus button is off at 1: no zero or negative cups.
                IconButton.outlined(
                  onPressed: quantity > 1
                      ? () => setState(() => quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => quantity++),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  'Total: ${widget.price * quantity}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Add to order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
