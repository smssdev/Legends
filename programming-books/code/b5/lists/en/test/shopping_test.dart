import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_shopping.dart';

void main() {
  testWidgets('swiping removes an item, and Undo brings it back', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ShoppingPage()));
    final first = 'Milk,Coffee beans,Sugar,Cups,Napkins,Oranges'
        .split(',')
        .first;
    expect(find.text(first), findsOneWidget);

    await tester.drag(find.text(first), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text(first), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text(first), findsOneWidget);
  });
}
