import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order.dart';
import 'providers.dart';

// مشتق من الطلبات: لا شيء يجب إبقاؤه متزامناً.
final pendingProvider = Provider<int>(
  (ref) => (ref.watch(ordersProvider).value ?? const [])
      .where((o) => o.sync == SyncState.queued)
      .length,
);
