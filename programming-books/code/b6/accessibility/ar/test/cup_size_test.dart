import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/cup_size.dart';

void main() {
  testWidgets('أحجام الكوب أزرار في مجموعة، واحد منها مختار', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      cafe(const Scaffold(body: Center(child: CupSize()))),
    );
    final medium = find.bySemanticsLabel('حجم الكوب: وسط');
    final large = find.bySemanticsLabel('حجم الكوب: كبير');
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
    tester.semantics.tap(find.semantics.byLabel('حجم الكوب: كبير'));
    await tester.pump();
    expect(tester.getSemantics(large), isSemantics(isSelected: true));
    expect(tester.getSemantics(medium), isSemantics(isSelected: false));
    debugPrint(
      'a screen reader double-tap on كبير selected it, and وسط is no longer selected',
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
