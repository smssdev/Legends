import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';

String hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

void main() {
  test('تبديل الثيم يحرّك ألوان العلامة أيضاً', () {
    for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final b = Brand.light.lerp(Brand.dark, t);
      debugPrint('t = $t   accent ${hex(b.accent)}   muted ${hex(b.muted)}');
    }
    expect(Brand.light.lerp(Brand.dark, 1).accent, Brand.dark.accent);
  });
}
