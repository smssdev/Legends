import 'package:material_ui/material_ui.dart';

import '../data/menu.dart';
import '../domain/pricing.dart';

class MenuScreen extends StatefulWidget {
  // The clock is a parameter, so a test can choose the time.
  const MenuScreen({
    super.key,
    required this.repository,
    this.now = DateTime.now,
  });

  final MenuRepository repository;
  final DateTime Function() now;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Drink>> drinks = widget.repository.menu();
  final order = <String, int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: FutureBuilder(
        future: drinks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  const Text('The menu could not be loaded.'),
                  FilledButton(
                    onPressed: () => setState(() {
                      drinks = widget.repository.menu();
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final menu = snapshot.data!;
          final lines = [
            for (final drink in menu)
              if (order[drink.id] case final quantity?)
                Line(drink.name, drink.price, quantity),
          ];
          final at = widget.now();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final drink in menu)
                      DrinkTile(
                        drink: drink,
                        quantity: order[drink.id] ?? 0,
                        onAdd: () => setState(
                          () => order[drink.id] = (order[drink.id] ?? 0) + 1,
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                title: Text(
                  'Total: ${total(lines, at)} EGP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: isHappyHour(at)
                    ? const Text('Happy hour: 20% off')
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DrinkTile extends StatelessWidget {
  const DrinkTile({
    super.key,
    required this.drink,
    required this.quantity,
    required this.onAdd,
  });

  final Drink drink;
  final int quantity;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text('$quantity'),
      ),
      title: Text(drink.name),
      subtitle: Text('${drink.price} EGP'),
      trailing: Icon(Icons.add_circle, color: colors.primary),
      onTap: onAdd,
    );
  }
}
