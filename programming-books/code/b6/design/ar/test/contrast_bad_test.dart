import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'contrast_test.dart';

void main() {
  test('الزوج غير المقروء يُكتشف', () {
    // نص أبيض على كهرماني التحذير: أول فكرة لوسم «أوشك أن ينفد».
    final ratio = contrast(const Color(0xFFFFFFFF), const Color(0xFFFFB300));
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: 'white on amber is ${ratio.toStringAsFixed(1)} : 1',
    );
  });
}
