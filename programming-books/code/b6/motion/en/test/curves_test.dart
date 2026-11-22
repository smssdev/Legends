import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('the curves, step by step', () {
    final curves = {
      'linear': Curves.linear,
      'easeInOut': Curves.easeInOut,
      'standard': Easing.standard,
      'emphasizedDecelerate': Easing.emphasizedDecelerate,
    };
    debugPrint(
      '${'time'.padRight(22)}${[
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) t.toStringAsFixed(2).padLeft(6),
      ].join()}',
    );
    curves.forEach((name, curve) {
      final row = [
        for (final t in [0.0, 0.25, 0.5, 0.75, 1.0])
          curve.transform(t).toStringAsFixed(2).padLeft(6),
      ];
      debugPrint('${name.padRight(22)}${row.join()}');
    });
  });
}
