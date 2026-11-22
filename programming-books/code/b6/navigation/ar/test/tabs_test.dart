import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('الألسنة تحفظ صفحاتها، والروابط العميقة لها طريق رجوع', (
    tester,
  ) async {
    final router = await pumpCafe(tester, Auth());
    await tester.tap(find.text('كيك الكرز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الطلبات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('القائمة').last);
    await tester.pumpAndSettle();
    expect(where(router), '/menu/cake');

    // رابط عميق إلى طلب مباشرة: تُبنى الكومة، فيعود زر الرجوع إلى القائمة.
    router.go('/orders/2');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(where(router), '/orders');
  });
}
