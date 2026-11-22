import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/order.dart';
import 'providers.dart';

// provider لكل رقم: orderProvider(1) وorderProvider(2) منفصلان، وكل منهما محفوظ.
final orderProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final all = await ref.watch(historyProvider.future);
  return all.firstWhereOrNull((o) => o.id == id);
});
