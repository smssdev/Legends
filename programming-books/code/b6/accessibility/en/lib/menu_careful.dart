import 'package:material_ui/material_ui.dart';

import 'cafe.dart';

void main() => runApp(cafe(const CarefulMenu()));

class CarefulMenu extends StatelessWidget {
  const CarefulMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final (name, about, price) in drinks)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          // One stop for the screen reader: name, description and price, read together.
                          child: MergeSemantics(
                            child: Row(
                              spacing: 12,
                              children: [
                                // The photo is decoration: the name already says what it is.
                                ExcludeSemantics(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.brown,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_cafe,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: text.titleMedium),
                                      Text(
                                        about,
                                        style: text.bodySmall!.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      // Under the name, not beside it: at large sizes a row has no width to spare.
                                      Text(
                                        '$price EGP',
                                        style: text.labelLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Every icon button says what it does, and to which drink.
                        IconButton(
                          tooltip: 'Save $name',
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border),
                        ),
                        IconButton.filled(
                          tooltip: 'Add $name',
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: colors.primaryContainer,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            // Big text wraps to a second line instead of running off the screen.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text('Total: 90 EGP', style: text.titleLarge),
                FilledButton(onPressed: () {}, child: const Text('Check out')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
