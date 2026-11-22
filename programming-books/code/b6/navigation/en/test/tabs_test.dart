import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('tabs keep their pages, and deep links have a way back', (
    tester,
  ) async {
    final router = await pumpCafe(tester, Auth());
    await tester.tap(find.text('Cherry cake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    expect(where(router), '/menu/cake');

    // A deep link straight to an order: the stack is built, so back returns to the list.
    router.go('/orders/2');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(where(router), '/orders');
  });
}
