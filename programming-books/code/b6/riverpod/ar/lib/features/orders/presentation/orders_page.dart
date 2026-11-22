import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/result.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';
import 'messages.dart';
import 'place_controller.dart';

const names = {'latte': 'لاتيه', 'tea': 'شاي بالنعناع', 'cake': 'كيك الكرز'};

// حالات المجال، بالكلمات: فالمجال بلا نصوص.
const statusNames = {
  OrderStatus.pending: 'معلّق',
  OrderStatus.preparing: 'قيد التحضير',
  OrderStatus.ready: 'جاهز',
  OrderStatus.cancelled: 'ملغى',
};

class OrdersApp extends StatelessWidget {
  const OrdersApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    // من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),

    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: const OrdersPage(),
  );
}

// يشاهد العدد وحده، فلا يُعاد بناؤه إلا حين يتغير العدد.
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
      appBar: AppBar(title: const Text('اطلب'), actions: const [BasketBadge()]),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} جنيه'),
              leading: CircleAvatar(child: Text('${basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: 'أضف ${names[item.id]}',
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
              child: Text(outcome.isLoading ? 'جارٍ الإرسال…' : 'أرسل الطلب'),
            ),
          ),
          if (outcome.value case final result?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(switch (result) {
                    Ok(:final value) => 'أُرسل الطلب: الطلب ${value.id}',
                    Err(:final failure) => describe(failure),
                  }),
                ),
              ),
            ),
          ListTile(
            title: Text(
              'طلباتك',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // كل حالات السجل، في switch واحد.
          ...switch (history) {
            AsyncValue(:final value?) when value.isEmpty => [
              const ListTile(title: Text('لم تطلب شيئاً بعد')),
            ],
            AsyncValue(:final value?) => [
              for (final order in value)
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('الطلب ${order.id} · ${order.total.pounds} جنيه'),
                  subtitle: Text(
                    'القطع: ${order.items} · ${statusNames[order.status]}',
                  ),
                ),
            ],
            AsyncValue(hasError: true) => [
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('تعذّر تحميل طلباتك'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('أعد المحاولة'),
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
