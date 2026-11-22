import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/keys.dart';

void main() {
  testWidgets('بلا مفاتيح تبقى الحالة مكانها؛ ومع المفاتيح تنتقل', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: KeysPage()));
    // المس A ثلاث مرات في الصفين.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('A').first);
      await tester.tap(find.text('A').last);
      await tester.pump();
    }
    await tester.tap(find.text('بدّل'));
    await tester.pump();

    String tapsUnder(Finder label) => (tester.widget<Text>(
      find.descendant(
        of: find.ancestor(of: label, matching: find.byType(Column)),
        matching: find.textContaining(':'),
      ),
    )).data!;
    // بلا مفاتيح: انتقل A إلى الجهة الأخرى، لكن لمساته الثلاث بقيت مكانها.
    expect(tapsUnder(find.text('A').first), 'المس: 0');
    // مع المفاتيح: انتقلت لمسات A الثلاث معه.
    expect(tapsUnder(find.text('A').last), 'المس: 3');
  });
}
