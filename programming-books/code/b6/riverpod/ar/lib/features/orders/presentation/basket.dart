import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/order.dart';

class BasketNotifier extends Notifier<Map<MenuItem, int>> {
  @override
  Map<MenuItem, int> build() => const {};

  // خريطة جديدة في كل مرة: يبلّغ Riverpod حين تكون الحالة كائناً مختلفاً.
  void add(MenuItem item) => state = {...state, item: (state[item] ?? 0) + 1};

  void clear() => state = const {};
}

final basketProvider = NotifierProvider<BasketNotifier, Map<MenuItem, int>>(
  BasketNotifier.new,
);

// حالة مشتقة: تُحسب من جديد فقط حين تتغير السلة.
final basketCountProvider = Provider<int>(
  (ref) => ref.watch(basketProvider).values.fold(0, (a, b) => a + b),
);
