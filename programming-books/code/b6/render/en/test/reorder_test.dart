import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_reorder.dart';

void main() {
  testWidgets('reordering keeps the state of each task', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksPage()));
    await tester.tap(find.text('Write tests'));
    await tester.pump();

    // On a phone, a long press picks the task up; then drag it below the last one.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Write tests')),
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
    expect(titles.last, 'Write tests');
    final moved = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Write tests'),
    );
    expect(moved.value, isTrue);
  });
}
