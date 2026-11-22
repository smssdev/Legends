import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'offline/order.dart';
import 'offline/providers.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const OrdersPage(),
      ),
    ),
  );
}

const titles = {'Latte': 'Latte', 'Cherry cake': 'Cherry cake'};
const statuses = {'new': 'new', 'ready': 'ready'};

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final orders = ref.watch(ordersProvider).value ?? const [];
    final last = ref.watch(lastSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          const ExcludeSemantics(child: Text('Online')),
          // The switch is named for screen readers (and for the screenshots): the text beside it is not its name.
          Semantics(
            label: 'Online',
            child: Switch(
              value: online,
              onChanged: ref.read(onlineProvider.notifier).set,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (!online)
            const MaterialBanner(
              leading: Icon(Icons.cloud_off),
              content: Text(
                'You are offline. New orders are kept here and sent when you are back.',
              ),
              actions: [SizedBox()],
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      ref.read(ordersActionsProvider).place('Latte'),
                  child: const Text('Order a latte'),
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(ordersActionsProvider).place('Cherry cake'),
                  child: const Text('Order a cake'),
                ),
                OutlinedButton(
                  onPressed: ref.read(lastSyncProvider.notifier).run,
                  child: const Text('Sync now'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final remote = ref.read(remoteProvider);
                    if (remote.orders.isNotEmpty) {
                      remote.setStatus(remote.orders.keys.first, 'ready');
                    }
                  },
                  child: const Text('Café: first order ready'),
                ),
              ],
            ),
          ),
          for (final order in orders)
            ListTile(
              leading: Icon(switch (order.sync) {
                SyncState.queued => Icons.schedule,
                SyncState.synced => Icons.cloud_done,
                SyncState.failed => Icons.error_outline,
              }),
              title: Text(titles[order.title] ?? order.title),
              subtitle: Text(switch (order.sync) {
                SyncState.queued => 'Waiting to send',
                SyncState.synced =>
                  'Sent · ${statuses[order.status] ?? order.status}',
                SyncState.failed => 'Not sent: ${order.error}',
              }),
            ),
          if (last != null)
            ListTile(
              title: Text(
                'Last sync: $last',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
