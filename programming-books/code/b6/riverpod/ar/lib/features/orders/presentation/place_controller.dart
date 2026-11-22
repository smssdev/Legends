import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../providers.dart';
import 'basket.dart';

typedef Outcome = Result<Order, OrderFailure>;

// إرسال الطلب: تحميل أثناء العمل، ثم النتيجة.
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
    // ربما أُغلقت الشاشة أثناء الانتظار.
    if (!ref.mounted) {
      return;
    }
    if (result is Ok) {
      ref.read(basketProvider.notifier).clear();
      // السجل قديم الآن: ارمه، فيُحمَّل من جديد لمن يشاهده.
      ref.invalidate(historyProvider);
    }
    state = AsyncData(result);
  }
}

final placeControllerProvider =
    AsyncNotifierProvider<PlaceController, Outcome?>(PlaceController.new);
