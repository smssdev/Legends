import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_form.dart';

void main() {
  testWidgets('the order form sums the choices and checks the name', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OrderForm()));
    expect(find.text('Place order · 45 EGP'), findsOneWidget);

    await tester.tap(find.text('Large'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Place order · 130 EGP'), findsOneWidget);

    await tester.tap(find.text('Place order · 130 EGP'));
    await tester.pump();
    expect(find.text('Please enter your name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Mona');
    await tester.tap(find.text('Place order · 130 EGP'));
    await tester.pumpAndSettle();
    expect(find.text('Order for Mona'), findsOneWidget);
  });
}
