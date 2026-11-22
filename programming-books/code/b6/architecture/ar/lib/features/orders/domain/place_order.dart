import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';
import 'orders_repository.dart';

// فعل واحد من أفعال التطبيق، بقواعده. ولا يعرف المستودع إلا بواجهته.
class PlaceOrder {
  PlaceOrder(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final OrdersRepository repository;
  final DateTime Function() clock;

  static const maxItems = 20;

  Future<Result<Order, OrderFailure>> call(List<OrderLine> lines) async {
    // القواعد بالترتيب: أرخص الفحوص أولاً، والشبكة أخيراً.
    final items = lines.fold(0, (sum, line) => sum + line.quantity);
    if (items == 0) {
      return const Err(EmptyOrder());
    }
    if (items > maxItems) {
      return const Err(TooLarge(maxItems));
    }
    final hour = clock().hour;
    if (hour < 8 || hour >= 22) {
      return const Err(Closed());
    }
    return repository.place(lines);
  }
}
