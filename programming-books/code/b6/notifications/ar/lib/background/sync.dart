import 'orders_api.dart';

// مهمة الخلفية: Dart خالصة، آمنة إن جرت مرتين، وسريعة.
Future<int> syncOrders(OrdersApi api, Seen seen, Notify notify) async {
  var sent = 0;
  for (final order in await api.mine()) {
    // أشعر مرة واحدة لكل طلب، حتى لو جرت المهمة مرة أخرى.
    if (order.ready && !await seen.contains(order.id)) {
      await notify.orderReady(order.id);
      await seen.add(order.id);
      sent++;
    }
  }
  return sent;
}
