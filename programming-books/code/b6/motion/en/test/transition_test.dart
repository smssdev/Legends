import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/transitions.dart';

Future<double?> opacityHalfway(
  WidgetTester tester, {
  required bool reduced,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: MaterialApp(
        key: ValueKey(reduced),
        theme: themed(ThemeData()),
        home: const StepPage(n: 1),
      ),
    ),
  );
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final fades = find.ancestor(
    of: find.text('2'),
    matching: find.byType(FadeTransition),
  );
  return fades.evaluate().isEmpty
      ? null
      : tester.widget<FadeTransition>(fades.first).opacity.value;
}

void main() {
  testWidgets('the page transition fades and slides, unless motion is reduced', (
    tester,
  ) async {
    final normal = await opacityHalfway(tester, reduced: false);
    final reduced = await opacityHalfway(tester, reduced: true);
    debugPrint(
      'halfway through the push: normal ${normal?.toStringAsFixed(2)}, reduced motion: ${reduced ?? 'no fade at all'}',
    );
    expect(normal, inExclusiveRange(0, 1));
    expect(reduced, isNull);
  });
}
