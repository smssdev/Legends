import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../domain/order.dart';
import 'orders_controller.dart';

const names = {'latte': 'Latte', 'tea': 'Mint tea', 'cake': 'Cherry cake'};

// The domain's statuses, in words: the domain has no text.
const statusNames = {
  OrderStatus.pending: 'Pending',
  OrderStatus.preparing: 'Preparing',
  OrderStatus.ready: 'Ready',
  OrderStatus.cancelled: 'Cancelled',
};

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrdersController>();
    final count = c.basket.values.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} EGP'),
              leading: CircleAvatar(child: Text('${c.basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: 'Add ${names[item.id]}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => context.read<OrdersController>().add(item),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: c.placing
                  ? null
                  : context.read<OrdersController>().place,
              child: Text(
                c.placing ? 'Placing…' : 'Place order · Basket: $count',
              ),
            ),
          ),
          if (c.message case final message?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(message),
                ),
              ),
            ),
          ListTile(
            title: Text(
              'Your orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (c.history.isEmpty)
            const ListTile(title: Text('Nothing ordered yet')),
          for (final order in c.history)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Order ${order.id} · ${order.total.pounds} EGP'),
              subtitle: Text(
                'Items: ${order.items} · ${statusNames[order.status]}',
              ),
            ),
        ],
      ),
    );
  }
}
