import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';
import 'package:bit_app/design/brands.dart';
import 'package:bit_app/design/theme.dart';

import 'contrast_test.dart';

void main() {
  test('two brands, the same components, both readable', () {
    final theme = buildTheme(
      Brightness.light,
      brand: bakeryLight,
      seed: bakerySeed,
    );
    final brand = theme.extension<Brand>()!;
    final c = theme.colorScheme;
    for (final (name, ratio) in [
      ('text on accent', contrast(brand.onAccent, brand.accent)),
      ('price on surface', contrast(brand.accent, c.surface)),
      ('text on muted', contrast(c.onSurface, brand.muted)),
      ('text on primary', contrast(c.onPrimary, c.primary)),
    ]) {
      debugPrint('bakery  ${name.padRight(18)}${ratio.toStringAsFixed(1)} : 1');
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });
}
