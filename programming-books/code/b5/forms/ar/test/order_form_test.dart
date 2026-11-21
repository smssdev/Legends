import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_form.dart';

void main() {
  testWidgets('نموذج الطلب يجمع الاختيارات ويفحص الاسم', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderForm()));
    expect(find.text('أرسل الطلب · 45 جنيه'), findsOneWidget);

    await tester.tap(find.text('كبير'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('أرسل الطلب · 130 جنيه'), findsOneWidget);

    await tester.tap(find.text('أرسل الطلب · 130 جنيه'));
    await tester.pump();
    expect(find.text('من فضلك اكتب اسمك'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'منى');
    await tester.tap(find.text('أرسل الطلب · 130 جنيه'));
    await tester.pumpAndSettle();
    expect(find.text('طلب باسم منى'), findsOneWidget);
  });
}
