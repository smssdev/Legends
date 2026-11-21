import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/result.dart';

void main() {
  testWidgets('صفحة المشروب تعيد الكمية إلى القائمة', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MenuPage()));

    await tester.tap(find.text('لاتيه'));
    await tester.pumpAndSettle();
    expect(find.text('إسبريسو وحليب مُبخَّر'), findsOneWidget);

    await tester.tap(find.byTooltip('أكثر'));
    await tester.pump();
    await tester.tap(find.text('أضف 2 إلى الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('إسبريسو وحليب مُبخَّر'), findsNothing);
    expect(find.text('أُضيف 2 × لاتيه'), findsOneWidget);
  });
}
