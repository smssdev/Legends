import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';

typedef Outcome = Result<Order, OrderFailure>;

// Placing an order: loading while it runs, then the result.
class PlaceController extends AsyncNotifier<Outcome?> {
  @override
  Future<Outcome?> build() async => null;

  Future<void> place() async {
    state = const AsyncLoading();
    final lines = [
      for (final e in ref.read(basketProvider).entries)
        OrderLine(e.key, e.value),
    ];
    final result = await ref.read(placeOrderProvider)(lines);
    // The screen may have closed while waiting.
    if (!ref.mounted) {
      return;
    }
    if (result is Ok) {
      ref.read(basketProvider.notifier).clear();
      // The history is stale now: throw it away, and it loads again for whoever watches it.
      ref.invalidate(historyProvider);
    }
    state = AsyncData(result);
  }
}

final placeControllerProvider =
    AsyncNotifierProvider<PlaceController, Outcome?>(PlaceController.new);
