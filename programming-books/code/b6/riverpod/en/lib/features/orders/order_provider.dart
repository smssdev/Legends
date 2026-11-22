import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/order.dart';
import 'providers.dart';

// One provider per id: orderProvider(1) and orderProvider(2) are separate, each cached.
final orderProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final all = await ref.watch(historyProvider.future);
  return all.firstWhereOrNull((o) => o.id == id);
});
