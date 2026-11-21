import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/form.dart';

void main() {
  testWidgets('النموذج يرفض المربعات الفارغة ويقبل السليمة', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CallBackForm()));

    await tester.tap(find.text('أرسل'));
    await tester.pump();
    expect(find.text('من فضلك اكتب اسمك'), findsOneWidget);
    expect(find.text('رقم الهاتف من 11 رقماً'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'سارة');
    await tester.enterText(find.byType(TextFormField).at(1), '01001234567');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'sara@example.com',
    );
    await tester.tap(find.text('أرسل'));
    await tester.pump();
    expect(find.text('من فضلك اكتب اسمك'), findsNothing);
    expect(find.text('شكراً، سنتصل بك'), findsOneWidget);
  });
}
