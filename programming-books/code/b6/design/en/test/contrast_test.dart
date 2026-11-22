import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/design/brand.dart';
import 'package:bit_app/design/theme.dart';

/// WCAG contrast ratio: from 1 (the same colour) to 21 (black on white).
double contrast(Color a, Color b) {
  final (hi, lo) = (
    max(a.computeLuminance(), b.computeLuminance()),
    min(a.computeLuminance(), b.computeLuminance()),
  );
  return (hi + 0.05) / (lo + 0.05);
}

Map<String, double> pairs(Brightness brightness) {
  final theme = buildTheme(brightness);
  final brand = theme.extension<Brand>()!;
  final c = theme.colorScheme;
  return {
    'text on surface': contrast(c.onSurface, c.surface),
    'text on primary': contrast(c.onPrimary, c.primary),
    'text on accent': contrast(brand.onAccent, brand.accent),
    'text on success': contrast(brand.onSuccess, brand.success),
    'text on warning': contrast(brand.onWarning, brand.warning),
    'text on muted': contrast(c.onSurface, brand.muted),
    'price (accent on surface)': contrast(brand.accent, c.surface),
  };
}

void main() {
  test('every colour pair is readable in both themes', () {
    for (final b in Brightness.values) {
      debugPrint(b.name);
      pairs(b).forEach((name, ratio) {
        debugPrint('  ${name.padRight(28)}${ratio.toStringAsFixed(1)} : 1');
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$name in ${b.name}');
      });
    }
  });
}
