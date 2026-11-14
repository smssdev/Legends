import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/ui/widgets/target.dart';

void main() {
  // [Sprint 65 F3] A 32-high pill keeps its drawn size, and the finger and the screen reader find it over 48.
  testWidgets('a small control answers over 48 and reads as one named 48 target', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlmTarget(
              key: const Key('target'),
              child: Semantics(
                button: true,
                label: 'Wallet: 120',
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++, child: const SizedBox(width: 60, height: 32)),
              ),
            ),
          ),
        ),
      ),
    );
    final box = t.getRect(find.byKey(const Key('target')));
    expect(box.size, const Size(60, 32));

    // 7px above the drawn box, inside the 48 around its centre: it answers.
    await t.tapAt(box.topCenter - const Offset(0, 7));
    expect(taps, 1);
    // 9px above: outside the 48, nothing.
    await t.tapAt(box.topCenter - const Offset(0, 9));
    expect(taps, 1);

    final reader = t.ensureSemantics();
    await t.pump();
    expect(t.getSemantics(find.byKey(const Key('target'))), matchesSemantics(label: 'Wallet: 120', isButton: true, hasTapAction: true));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    reader.dispose();
  });
}
