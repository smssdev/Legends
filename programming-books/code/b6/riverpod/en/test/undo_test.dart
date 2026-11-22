import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/domain/order.dart';
import 'package:bit_app/features/orders/presentation/undo_basket.dart';

void main() {
  test('undo goes back one state at a time', () {
    final container = ProviderContainer.test();
    final basket = container.read(undoBasketProvider.notifier);
    final latte = menu[0];
    final cake = menu[2];
    final seen = <Map<MenuItem, int>>[];
    container.listen(undoBasketProvider, (previous, next) => seen.add(next));

    basket.add(latte);
    basket.add(latte);
    basket.add(cake);
    basket.remove(latte);
    expect(container.read(undoBasketProvider), {latte: 1, cake: 1});

    basket.undo();
    expect(container.read(undoBasketProvider), {latte: 2, cake: 1});
    basket.undo();
    basket.undo();
    expect(container.read(undoBasketProvider), {latte: 1});
    basket.undo();
    expect(container.read(undoBasketProvider), isEmpty);
    expect(basket.canUndo, isFalse);
    expect(seen, hasLength(8));
  });
}
