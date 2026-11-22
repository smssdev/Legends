import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/tokens.dart';
import '../../state/providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final menu = ref.watch(menuProvider).value?.$1 ?? const [];
    final lines = [
      for (final drink in menu)
        if (cart[drink.id] case final count?) (drink, count),
    ];
    final total = totalOf(cart, menu);
    return Scaffold(
      appBar: AppBar(title: const Text('طلبك')),
      body: lines.isEmpty
          ? const Center(child: Text('لا شيء في طلبك بعد.'))
          : ListView(
              children: [
                for (final (drink, count) in lines)
                  ListTile(
                    title: Text(drink.name),
                    subtitle: Text('$count × ${drink.price} جنيه'),
                    trailing: IconButton(
                      tooltip: 'احذف ${drink.name}',
                      onPressed: () =>
                          ref.read(cartProvider.notifier).remove(drink.id),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Space.m),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: Space.s,
                  children: [
                    Text(
                      'المجموع: $total جنيه',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    FilledButton(
                      onPressed: () async {
                        final order = await ref.read(apiProvider).place(cart);
                        ref.read(cartProvider.notifier).clear();
                        if (context.mounted) {
                          context.go('/orders/${order.id}');
                        }
                      },
                      child: const Text('أرسل الطلب'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
