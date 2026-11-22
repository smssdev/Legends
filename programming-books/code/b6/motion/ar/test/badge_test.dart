import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('الرقمان على الشاشة معاً وهما يتقاطعان', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderPage()));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    debugPrint(
      'halfway: "0" ${find.text('0').evaluate().length}, "1" ${find.text('1').evaluate().length}',
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
  });
}
