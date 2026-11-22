import 'package:flutter_test/flutter_test.dart';

import 'architecture_test.dart' as rules;

void main() {
  test('ملف في المجال يستورد Flutter يُكتشف', () {
    expect(rules.violations('test/fixtures'), isEmpty);
  });
}
