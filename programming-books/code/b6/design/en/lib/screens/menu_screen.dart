import 'package:material_ui/material_ui.dart';

import '../design/components.dart';
import '../design/context.dart';
import '../design/tokens.dart';

// A real screen: nothing but components, tokens and the theme.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Latte',
        'Espresso and steamed milk',
        45,
        const StatusTag(label: 'New', kind: TagKind.success),
      ),
      ('Mint tea', 'Fresh mint, a little sugar', 25, null),
      (
        'Cherry cake',
        'Baked this morning',
        60,
        const StatusTag(label: 'Almost sold out', kind: TagKind.warning),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Menu'), actions: actions),
      body: ListView.separated(
        padding: const EdgeInsets.all(Space.m),
        itemCount: items.length,
        separatorBuilder: (context, i) => const Gap(Space.m),
        itemBuilder: (context, i) {
          final (name, description, price, tag) = items[i];
          return MenuCard(
            name: name,
            description: description,
            price: price,
            tag: tag,
          );
        },
      ),
    );
  }
}

// Each card is its own widget, so it reads the theme from its own context, and rebuilds when the theme changes.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    this.tag,
  });

  final String name;
  final String description;
  final int price;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: context.text.titleLarge)),
              ?tag,
            ],
          ),
          const Gap(Space.xs),
          Text(
            description,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const Gap(Space.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$price EGP',
                  style: context.text.titleMedium!.copyWith(
                    color: context.brand.accent,
                  ),
                ),
              ),
              AppButton(label: 'Order', icon: Icons.add, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
