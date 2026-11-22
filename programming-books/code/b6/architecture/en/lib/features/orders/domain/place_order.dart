import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';
import 'orders_repository.dart';

// One action of the app, with its rules. It knows the repository only by its interface.
class PlaceOrder {
  PlaceOrder(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final OrdersRepository repository;
  final DateTime Function() clock;

  static const maxItems = 20;

  Future<Result<Order, OrderFailure>> call(List<OrderLine> lines) async {
    // The rules, in order: cheapest checks first, the network last.
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
