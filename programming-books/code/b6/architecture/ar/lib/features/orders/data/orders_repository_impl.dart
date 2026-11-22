import '../../../core/result.dart';
import '../domain/failures.dart';
import '../domain/order.dart';
import '../domain/orders_repository.dart';
import 'order_dto.dart';
import 'orders_source.dart';

// يترجم بين العالمين: من DTO إلى كيانات، ومن الاستثناءات إلى حالات فشل.
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this.source);

  final OrdersSource source;

  @override
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines) async {
    try {
      final json = await source.post({
        for (final l in lines) l.item.id: l.quantity,
      });
      return Ok(_toOrder(OrderDto.fromJson(json)));
    } catch (_) {
      // أي فشل في المصدر يصير NetworkFailure: فالمجال لا يرى استثناءً أبداً.
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<List<Order>> history() async => [
    for (final json in await source.list()) _toOrder(OrderDto.fromJson(json)),
  ];

  Order _toOrder(OrderDto dto) => Order(
    id: dto.id,
    lines: [
      for (final MapEntry(:key, :value) in dto.items.entries)
        OrderLine(menu.firstWhere((m) => m.id == key), value),
    ],
    status: OrderStatus.values.byName(dto.status),
    placedAt: DateTime.parse(dto.placedAt),
  );
}
