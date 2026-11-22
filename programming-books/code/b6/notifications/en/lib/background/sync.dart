import 'orders_api.dart';

// The background job: plain Dart, safe to run twice, and quick.
Future<int> syncOrders(OrdersApi api, Seen seen, Notify notify) async {
  var sent = 0;
  for (final order in await api.mine()) {
    // Notify once per order, even if the job runs again.
    if (order.ready && !await seen.contains(order.id)) {
      await notify.orderReady(order.id);
      await seen.add(order.id);
      sent++;
    }
  }
  return sent;
}
