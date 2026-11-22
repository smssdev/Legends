import 'package:flutter_test/flutter_test.dart';

import 'guard_test.dart';

void main() {
  test('a screen with raw values is caught', () {
    expect(violations('test/fixtures'), isEmpty);
  });
}
