import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_reorder.dart';

void main() {
  testWidgets('إعادة الترتيب تُبقي حالة كل عدّاد', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksPage()));
    await tester.tap(find.text('اكتب الاختبارات'));
    await tester.pump();

    // على الجوال، الضغط المطوّل يرفع المهمة؛ ثم اسحبها تحت الأخيرة.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('اكتب الاختبارات')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final titles = [
      for (final t in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      ))
        (t.title! as Text).data,
    ];
    expect(titles.last, 'اكتب الاختبارات');
    final moved = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'اكتب الاختبارات'),
    );
    expect(moved.value, isTrue);
  });
}
