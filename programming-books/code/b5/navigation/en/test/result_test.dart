import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/result.dart';

void main() {
  testWidgets('the drink page sends the quantity back to the menu', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MenuPage()));

    await tester.tap(find.text('Latte'));
    await tester.pumpAndSettle();
    expect(find.text('Espresso and steamed milk'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    await tester.tap(find.text('Add 2 to order'));
    await tester.pumpAndSettle();

    expect(find.text('Espresso and steamed milk'), findsNothing);
    expect(find.text('Added 2 × Latte'), findsOneWidget);
  });
}
