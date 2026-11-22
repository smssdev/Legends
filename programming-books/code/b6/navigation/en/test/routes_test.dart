import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe/routes.dart';

void main() {
  test('links are built in one place, and encoded correctly', () {
    expect(Routes.order(3), '/orders/3');
    expect(Routes.menuUpTo(40), '/menu?max=40');
    expect(
      Routes.signIn(from: '/account?tab=2'),
      '/signin?from=%2Faccount%3Ftab%3D2',
    );
  });
}
