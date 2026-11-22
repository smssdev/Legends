import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/domain/pricing.dart';

void main() {
  final morning = DateTime(2026, 11, 23, 10);
  final afternoon = DateTime(2026, 11, 23, 15, 30);
  const order = [Line('latte', 45, 2), Line('cake', 55, 1)];

  test('مجموع طلب', () {
    expect(total(order, morning), 145);
  });

  test('ساعة السعادة تخصم 20%', () {
    expect(total(order, afternoon), 116);
  });

  test('الطلب الفارغ لا يكلّف شيئاً', () {
    expect(total(const [], afternoon), 0);
  });
}
