import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/routes.dart';

import 'helpers.dart';

void main() {
  testWidgets('the filter comes from the address', (tester) async {
    final router = await pumpCafe(tester, Auth());
    expect(find.text('Cherry cake'), findsOneWidget);

    router.go(Routes.menuUpTo(50));
    await tester.pumpAndSettle();
    expect(find.text('Cherry cake'), findsNothing);
    expect(find.text('Latte'), findsOneWidget);

    await tester.tap(find.text('Up to 30'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu?max=30');
    expect(find.byType(ListTile), findsOneWidget);
  });
}
