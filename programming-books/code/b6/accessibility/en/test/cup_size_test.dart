import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/cup_size.dart';

void main() {
  testWidgets('the cup sizes are buttons in a group, one selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      cafe(const Scaffold(body: Center(child: CupSize()))),
    );
    final medium = find.bySemanticsLabel('Cup size: Medium');
    final large = find.bySemanticsLabel('Cup size: Large');
    expect(
      tester.getSemantics(medium),
      isSemantics(
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(large),
      isSemantics(isButton: true, isSelected: false),
    );
    tester.semantics.tap(find.semantics.byLabel('Cup size: Large'));
    await tester.pump();
    expect(tester.getSemantics(large), isSemantics(isSelected: true));
    expect(tester.getSemantics(medium), isSemantics(isSelected: false));
    debugPrint(
      'a screen reader double-tap on Large selected it, and Medium is no longer selected',
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
