import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/basket.dart';
import 'package:bit_app/features/orders/presentation/place_controller.dart';
import 'package:bit_app/features/orders/providers.dart';

class CountingSource extends FakeOrdersSource {
  var posts = 0;

  @override
  Future<Map<String, dynamic>> post(Map<String, int> items) {
    posts++;
    return super.post(items);
  }
}

void main() {
  test('استبدال واحد، والقواعد تعمل بلا شبكة', () async {
    final source = CountingSource();
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 23)),
        ordersSourceProvider.overrideWithValue(source),
      ],
    );
    container.read(basketProvider.notifier).add(menu.first);
    await container.read(placeControllerProvider.notifier).place();

    final outcome = container.read(placeControllerProvider).value;
    expect((outcome! as Err).failure, isA<Closed>());
    expect(source.posts, 0);
    expect(container.read(basketCountProvider), 1);
  });
}
