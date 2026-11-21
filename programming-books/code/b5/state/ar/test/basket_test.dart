import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/basket.dart';

void main() {
  test('السلة تضيف وتعدّ وتجمع', () {
    final basket = Basket();
    var told = 0;
    basket.addListener(() => told++);

    basket.add('لاتيه', 45);
    basket.add('لاتيه', 45);
    basket.add('كيك الكرز', 60);
    expect(basket.count, 3);
    expect(basket.total, 150);
    expect(basket.counts['لاتيه'], 2);

    basket.remove('لاتيه');
    expect(basket.total, 105);
    expect(told, 4);
  });
}
