import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/routes.dart';

import 'helpers.dart';

void main() {
  testWidgets('الفلتر يأتي من العنوان', (tester) async {
    final router = await pumpCafe(tester, Auth());
    expect(find.text('كيك الكرز'), findsOneWidget);

    router.go(Routes.menuUpTo(50));
    await tester.pumpAndSettle();
    expect(find.text('كيك الكرز'), findsNothing);
    expect(find.text('لاتيه'), findsOneWidget);

    await tester.tap(find.text('حتى 30'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu?max=30');
    expect(find.byType(ListTile), findsOneWidget);
  });
}
