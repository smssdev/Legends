import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/stagger.dart';

void main() {
  testWidgets('each item arrives a little after the one before', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StaggerPage()));
    for (var ms = 0; ms <= 800; ms += 200) {
      final row = [
        for (final name in items)
          tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: find.text(name),
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value,
      ];
      debugPrint(
        '${'$ms ms'.padRight(8)}${row.map((o) => o.toStringAsFixed(2).padLeft(6)).join()}',
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  });
}
