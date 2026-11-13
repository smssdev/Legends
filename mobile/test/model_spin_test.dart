import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/widgets/console.dart';

void main() {
  testWidgets('[Sprint 61 F2] a model turns as pictures: its strip read, the fallback gone, the finger turns it', (t) async {
    GlmModelSpin.enabled = true;
    addTearDown(() => GlmModelSpin.enabled = false);
    const fallback = Text('fallback');
    await t.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          // Still: the test's clock does not run a ticker for ever.
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox.square(
              dimension: 120,
              child: GlmModelSpin(model: 'trophy', label: 'trophy', fallback: fallback),
            ),
          ),
        ),
      ),
    );
    expect(find.text('fallback'), findsOneWidget, reason: 'the drawn stand-in until the strip is read');
    await t.runAsync(() async {
      for (var i = 0; i < 50 && find.text('fallback').evaluate().isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await t.pump();
      }
    });
    expect(find.text('fallback'), findsNothing);
    expect(find.bySemanticsLabel('trophy'), findsOneWidget);
    await t.drag(find.byType(GlmModelSpin), const Offset(-80, 0));
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
