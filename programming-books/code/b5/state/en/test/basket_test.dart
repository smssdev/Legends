import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/basket.dart';

void main() {
  test('the basket adds, counts and totals', () {
    final basket = Basket();
    var told = 0;
    basket.addListener(() => told++);

    basket.add('Latte', 45);
    basket.add('Latte', 45);
    basket.add('Cherry cake', 60);
    expect(basket.count, 3);
    expect(basket.total, 150);
    expect(basket.counts['Latte'], 2);

    basket.remove('Latte');
    expect(basket.total, 105);
    expect(told, 4);
  });
}
