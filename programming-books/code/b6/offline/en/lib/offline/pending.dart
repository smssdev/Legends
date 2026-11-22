import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order.dart';
import 'providers.dart';

// Derived from the orders: nothing to keep in step.
final pendingProvider = Provider<int>(
  (ref) => (ref.watch(ordersProvider).value ?? const [])
      .where((o) => o.sync == SyncState.queued)
      .length,
);
