import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';

class BasketNotifier extends Notifier<Map<MenuItem, int>> {
  @override
  Map<MenuItem, int> build() => const {};

  // A new map every time: Riverpod notifies when state is a different object.
  void add(MenuItem item) => state = {...state, item: (state[item] ?? 0) + 1};

  void clear() => state = const {};
}

final basketProvider = NotifierProvider<BasketNotifier, Map<MenuItem, int>>(
  BasketNotifier.new,
);

// Derived state: recomputed only when the basket changes.
final basketCountProvider = Provider<int>(
  (ref) => ref.watch(basketProvider).values.fold(0, (a, b) => a + b),
);
