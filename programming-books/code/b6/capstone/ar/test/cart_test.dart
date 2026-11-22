import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/data/models.dart';
import 'package:bit_app/state/providers.dart';

void main() {
  test('السلة تضيف وتحذف وتجمع', () {
    final container = ProviderContainer.test();
    final cart = container.read(cartProvider.notifier)
      ..add('latte')
      ..add('latte')
      ..add('cake')
      ..remove('cake');
    const menu = [
      Drink('latte', 'Latte', '', 45),
      Drink('cake', 'Cherry cake', '', 55),
    ];
    expect(container.read(cartProvider), {'latte': 2});
    expect(totalOf(container.read(cartProvider), menu), 90);
    cart.clear();
    expect(container.read(cartProvider), isEmpty);
  });
}
