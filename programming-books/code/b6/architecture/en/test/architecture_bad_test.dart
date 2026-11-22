import 'package:flutter_test/flutter_test.dart';

import 'architecture_test.dart' as rules;

void main() {
  test('a domain file that imports Flutter is caught', () {
    expect(rules.violations('test/fixtures'), isEmpty);
  });
}
