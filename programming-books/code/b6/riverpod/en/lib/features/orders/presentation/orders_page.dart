import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';
import 'messages.dart';
import 'place_controller.dart';

const names = {'latte': 'Latte', 'tea': 'Mint tea', 'cake': 'Cherry cake'};

// The domain's statuses, in words: the domain has no text.
const statusNames = {
  OrderStatus.pending: 'Pending',
  OrderStatus.preparing: 'Preparing',
  OrderStatus.ready: 'Ready',
  OrderStatus.cancelled: 'Cancelled',
};

class OrdersApp extends StatelessWidget {
  const OrdersApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,

    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: const OrdersPage(),
  );
}

// Watches only the count, so it rebuilds only when the count changes.
class BasketBadge extends ConsumerWidget {
  const BasketBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(basketCountProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        child: const Icon(Icons.shopping_basket),
      ),
    );
  }
}

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final outcome = ref.watch(placeControllerProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
        actions: const [BasketBadge()],
      ),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} EGP'),
              leading: CircleAvatar(child: Text('${basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: 'Add ${names[item.id]}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => ref.read(basketProvider.notifier).add(item),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: outcome.isLoading
                  ? null
                  : () => ref.read(placeControllerProvider.notifier).place(),
              child: Text(outcome.isLoading ? 'Placing…' : 'Place order'),
            ),
          ),
          if (outcome.value case final result?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(switch (result) {
                    Ok(:final value) => 'Order placed: Order ${value.id}',
                    Err(:final failure) => describe(failure),
                  }),
                ),
              ),
            ),
          ListTile(
            title: Text(
              'Your orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Every state of the history, in one switch.
          ...switch (history) {
            AsyncValue(:final value?) when value.isEmpty => [
              const ListTile(title: Text('Nothing ordered yet')),
            ],
            AsyncValue(:final value?) => [
              for (final order in value)
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('Order ${order.id} · ${order.total.pounds} EGP'),
                  subtitle: Text(
                    'Items: ${order.items} · ${statusNames[order.status]}',
                  ),
                ),
            ],
            AsyncValue(hasError: true) => [
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('Could not load your orders'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }
}
