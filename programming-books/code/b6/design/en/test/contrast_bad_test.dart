import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'contrast_test.dart';

void main() {
  test('a pair that is not readable is caught', () {
    // White text on the warning amber: the first idea for the "almost sold out" tag.
    final ratio = contrast(const Color(0xFFFFFFFF), const Color(0xFFFFB300));
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: 'white on amber is ${ratio.toStringAsFixed(1)} : 1',
    );
  });
}
