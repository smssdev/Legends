import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/order_provider.dart';
import 'package:bit_app/features/orders/providers.dart';

void main() {
  test('لكل رقم طلب provider خاص به، محفوظ', () async {
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
      ],
    );
    final place = container.read(placeOrderProvider);
    await place([OrderLine(menu[0], 1)]);
    await place([OrderLine(menu[1], 2)]);

    final first = await container.read(orderProvider(1).future);
    final second = await container.read(orderProvider(2).future);
    expect(first!.total.pounds, 45);
    expect(second!.total.pounds, 50);
    expect(await container.read(orderProvider(3).future), isNull);
    // الرقم نفسه يعطي القيمة المحفوظة نفسها.
    expect(
      identical(await container.read(orderProvider(1).future), first),
      isTrue,
    );
  });
}
