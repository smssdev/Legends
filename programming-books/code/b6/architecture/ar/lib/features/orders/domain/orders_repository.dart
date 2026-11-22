import '../../../core/result.dart';
import 'failures.dart';
import 'order.dart';

// ما يحتاجه المجال من العالم الخارجي. وطبقة البيانات ستقدّمه.
abstract interface class OrdersRepository {
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines);
  Future<List<Order>> history();
}
