import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/tokens.dart';
import '../../state/providers.dart';

// Each feature in its own folder: its pages, and nothing else's.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider);
    final count = ref.watch(cartProvider).values.fold(0, (a, b) => a + b);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            tooltip: 'Open your order',
            onPressed: () => context.go('/cart'),
            // The badge moves only if the person allows motion (Chapter 8).
            icon: AnimatedSwitcher(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: Badge.count(
                key: ValueKey(count),
                count: count,
                isLabelVisible: count > 0,
                child: const Icon(Icons.local_cafe),
              ),
            ),
          ),
        ],
      ),
      body: switch (menu) {
        AsyncData(value: (final drinks, fresh: _)) => ListView.builder(
          // Only the rows on screen are built (Chapter 9).
          itemCount: drinks.length,
          itemBuilder: (context, i) {
            final drink = drinks[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Space.m,
                vertical: Space.s,
              ),
              title: Text(drink.name),
              subtitle: Text('${drink.about}\n${drink.price} EGP'),
              isThreeLine: true,
              trailing: IconButton.filled(
                tooltip: 'Add ${drink.name}',
                onPressed: () => ref.read(cartProvider.notifier).add(drink.id),
                // Inside a ListTile, the tile's icon colour wins over the button's: say it explicitly.
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            );
          },
        ),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Space.m,
            children: [
              const Text('The menu could not be loaded.'),
              FilledButton(
                onPressed: () => ref.invalidate(menuProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
