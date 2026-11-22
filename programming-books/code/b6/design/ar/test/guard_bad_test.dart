import 'package:flutter_test/flutter_test.dart';

import 'guard_test.dart';

void main() {
  test('الشاشة ذات القيم الخام تُكتشف', () {
    expect(violations('test/fixtures'), isEmpty);
  });
}
