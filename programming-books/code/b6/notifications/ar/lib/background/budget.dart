import 'dart:async';

import 'orders_api.dart';
import 'sync.dart';

enum Outcome { done, retry }

// توقف مبكراً واطلب أن تُشغَّل مرة أخرى، بدل أن تُقتل في المنتصف.
Future<Outcome> syncWithin(
  Duration budget,
  OrdersApi api,
  Seen seen,
  Notify notify,
) async {
  try {
    await syncOrders(api, seen, notify).timeout(budget);
    return Outcome.done;
  } on TimeoutException {
    return Outcome.retry;
  }
}
