import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/domain/cancel_order.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test('an order can be cancelled only while pending, within five minutes', () {
    final placed = DateTime(2026, 11, 22, 10);
    Order order(OrderStatus s) => Order(
      id: 1,
      lines: [OrderLine(menu.first, 1)],
      status: s,
      placedAt: placed,
    );
    CancelOrder at(int minutes) =>
        CancelOrder(clock: () => placed.add(Duration(minutes: minutes)));

    expect(
      (at(2)(order(OrderStatus.pending)) as Ok).value,
      isA<Order>().having((o) => o.status, 'status', OrderStatus.cancelled),
    );
    expect((at(2)(order(OrderStatus.ready)) as Err).failure, isA<NotPending>());
    expect((at(5)(order(OrderStatus.pending)) as Ok).value, isA<Order>());
    expect((at(6)(order(OrderStatus.pending)) as Err).failure, isA<TooLate>());
  });
}
