import '../../../core/result.dart';
import 'order.dart';

sealed class CancelFailure {
  const CancelFailure();
}

final class NotPending extends CancelFailure {
  const NotPending();
}

final class TooLate extends CancelFailure {
  const TooLate();
}

// حالة استخدام جديدة: لا شاشة ولا شبكة، القواعد وحدها.
class CancelOrder {
  CancelOrder({DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final DateTime Function() clock;

  static const window = Duration(minutes: 5);

  Result<Order, CancelFailure> call(Order order) {
    if (order.status != OrderStatus.pending) {
      return const Err(NotPending());
    }
    if (clock().difference(order.placedAt) > window) {
      return const Err(TooLate());
    }
    return Ok(
      Order(
        id: order.id,
        lines: order.lines,
        status: OrderStatus.cancelled,
        placedAt: order.placedAt,
      ),
    );
  }
}
