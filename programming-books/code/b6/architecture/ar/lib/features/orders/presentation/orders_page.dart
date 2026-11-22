import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../domain/order.dart';
import 'orders_controller.dart';

const names = {'latte': 'لاتيه', 'tea': 'شاي بالنعناع', 'cake': 'كيك الكرز'};

// حالات المجال، بالكلمات: فالمجال بلا نصوص.
const statusNames = {
  OrderStatus.pending: 'معلّق',
  OrderStatus.preparing: 'قيد التحضير',
  OrderStatus.ready: 'جاهز',
  OrderStatus.cancelled: 'ملغى',
};

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrdersController>();
    final count = c.basket.values.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('اطلب')),
      body: ListView(
        children: [
          for (final item in menu)
            ListTile(
              title: Text(names[item.id]!),
              subtitle: Text('${item.price.pounds} جنيه'),
              leading: CircleAvatar(child: Text('${c.basket[item] ?? 0}')),
              trailing: IconButton(
                tooltip: 'أضف ${names[item.id]}',
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
                c.placing ? 'جارٍ الإرسال…' : 'أرسل الطلب · السلة: $count',
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
              'طلباتك',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (c.history.isEmpty)
            const ListTile(title: Text('لم تطلب شيئاً بعد')),
          for (final order in c.history)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('الطلب ${order.id} · ${order.total.pounds} جنيه'),
              subtitle: Text(
                'القطع: ${order.items} · ${statusNames[order.status]}',
              ),
            ),
        ],
      ),
    );
  }
}
