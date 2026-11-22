import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/domain/orders_repository.dart';
import 'package:bit_app/features/orders/domain/place_order.dart';

class FakeRepository implements OrdersRepository {
  final placed = <List<OrderLine>>[];

  @override
  Future<Result<Order, OrderFailure>> place(List<OrderLine> lines) async {
    placed.add(lines);
    return Ok(
      Order(
        id: placed.length,
        lines: lines,
        status: OrderStatus.pending,
        placedAt: DateTime(2026, 11, 22, 10),
      ),
    );
  }

  @override
  Future<List<Order>> history() async => [];
}

void main() {
  test('إرسال الطلب يتبع القواعد، بالترتيب', () async {
    final repo = FakeRepository();
    var hour = 10;
    final place = PlaceOrder(repo, clock: () => DateTime(2026, 11, 22, hour));
    final latte = OrderLine(menu.first, 2);

    expect(
      await place([]),
      isA<Err<Order, OrderFailure>>().having(
        (e) => e.failure,
        'failure',
        isA<EmptyOrder>(),
      ),
    );
    expect(
      (await place([OrderLine(menu.first, 21)]) as Err).failure,
      isA<TooLarge>(),
    );
    hour = 23;
    expect((await place([latte]) as Err).failure, isA<Closed>());
    expect(repo.placed, isEmpty);

    hour = 10;
    final ok = await place([latte]) as Ok<Order, OrderFailure>;
    expect(ok.value.total.pounds, 90);
    expect(repo.placed, hasLength(1));
  });
}
