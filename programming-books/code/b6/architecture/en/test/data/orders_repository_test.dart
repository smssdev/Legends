import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test(
    'the repository turns data into entities, and errors into failures',
    () async {
      final repo = OrdersRepositoryImpl(FakeOrdersSource());
      final placed = await repo.place([
        OrderLine(menu[0], 2),
        OrderLine(menu[2], 1),
      ]) as Ok;
      final order = placed.value as Order;
      expect(order.total.pounds, 150);
      expect(order.status, OrderStatus.pending);
      expect((await repo.history()).single.items, 3);

      final offline = OrdersRepositoryImpl(FakeOrdersSource(fails: true));
      expect(
        (await offline.place([OrderLine(menu[0], 1)]) as Err).failure,
        isA<NetworkFailure>(),
      );
    },
  );
}
