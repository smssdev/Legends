import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'offline/order.dart';
import 'offline/providers.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

        theme: ThemeData(colorSchemeSeed: Colors.teal),
        home: const OrdersPage(),
      ),
    ),
  );
}

const titles = {'Latte': 'لاتيه', 'Cherry cake': 'كيك الكرز'};
const statuses = {'new': 'جديد', 'ready': 'جاهز'};

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final orders = ref.watch(ordersProvider).value ?? const [];
    final last = ref.watch(lastSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        actions: [
          const ExcludeSemantics(child: Text('متصل')),
          // المفتاح له اسم لقارئات الشاشة (ولصور الكتاب): فالنص بجانبه ليس اسمه.
          Semantics(
            label: 'متصل',
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
                'أنت غير متصل. الطلبات الجديدة تُحفظ هنا وتُرسل حين تعود.',
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
                  child: const Text('اطلب لاتيه'),
                ),
                FilledButton(
                  onPressed: () =>
                      ref.read(ordersActionsProvider).place('Cherry cake'),
                  child: const Text('اطلب كيكة'),
                ),
                OutlinedButton(
                  onPressed: ref.read(lastSyncProvider.notifier).run,
                  child: const Text('زامن الآن'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final remote = ref.read(remoteProvider);
                    if (remote.orders.isNotEmpty) {
                      remote.setStatus(remote.orders.keys.first, 'ready');
                    }
                  },
                  child: const Text('المقهى: أول طلب جاهز'),
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
                SyncState.queued => 'ينتظر الإرسال',
                SyncState.synced =>
                  'أُرسل · ${statuses[order.status] ?? order.status}',
                SyncState.failed => 'لم يُرسل: ${order.error}',
              }),
            ),
          if (last != null)
            ListTile(
              title: Text(
                'آخر مزامنة: $last',
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
