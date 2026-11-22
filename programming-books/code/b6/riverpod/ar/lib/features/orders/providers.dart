import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/orders_repository_impl.dart';
import 'data/orders_source.dart';
import 'domain/order.dart';
import 'domain/orders_repository.dart';
import 'domain/place_order.dart';

// توصيل الميزة: الملف الوحيد في الميزة الذي يعرف طبقة البيانات.

// الاعتماديات providers أيضاً: التطبيق يقرؤها، والاختبارات تستبدلها.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final ordersSourceProvider = Provider<OrdersSource>(
  (ref) => FakeOrdersSource(),
);

// الـ providers يبني بعضها بعضاً: غيّر المصدر، فيُعاد بناء كل ما فوقه.
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(ref.watch(ordersSourceProvider)),
);
final placeOrderProvider = Provider<PlaceOrder>(
  (ref) => PlaceOrder(
    ref.watch(ordersRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

// تحميل أو جاهز أو فاشل: FutureProvider تعطي الشاشة AsyncValue.
final historyProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(ordersRepositoryProvider).history(),
);
