import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';

// What the domain needs from the outside world. The data layer will provide it.
abstract interface class OrdersRepository {
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines);
  Future<List<Order>> history();
}
