import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('الشاشات الرئيسية تحقق إرشادات الإتاحة', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      cafe(
        overrides: [
          apiProvider.overrideWithValue(FakeApi()),
          prefsProvider.overrideWithValue(memoryPrefs()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('أضف Latte'));
    for (final page in ['menu', 'cart']) {
      if (page == 'cart') {
        await tester.tap(find.byTooltip('افتح طلبك'));
        await tester.pumpAndSettle();
      }
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      debugPrint('$page: labels, tap targets and contrast pass');
    }
    semantics.dispose();
  });
}
