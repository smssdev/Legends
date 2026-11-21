import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_cart_badge.dart';

void main() {
  testWidgets('الشارة تعدّ الأكواب', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CartPage()));
    expect(find.text('0'), findsNothing);
    for (var i = 1; i <= 10; i++) {
      await tester.tap(find.text('أضف كوباً'));
      await tester.pump();
    }
    expect(find.text('9+'), findsOneWidget);
  });
}
