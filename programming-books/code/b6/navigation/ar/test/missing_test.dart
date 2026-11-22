import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('العناوين والأرقام المجهولة تجد صفحة تقول ذلك', (tester) async {
    final router = await pumpCafe(tester, Auth());
    router.go('/nothing/here');
    await tester.pumpAndSettle();
    expect(find.text('الصفحة غير موجودة'), findsOneWidget);

    router.go('/orders/abc');
    await tester.pumpAndSettle();
    expect(find.text('لا طلب برقم ?'), findsOneWidget);

    router.go('/menu/coffee');
    await tester.pumpAndSettle();
    expect(find.text('لا مشروب باسم "coffee"'), findsOneWidget);
  });
}
