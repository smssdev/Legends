import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('unknown addresses and ids get a page that says so', (
    tester,
  ) async {
    final router = await pumpCafe(tester, Auth());
    router.go('/nothing/here');
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);

    router.go('/orders/abc');
    await tester.pumpAndSettle();
    expect(find.text('No order number ?'), findsOneWidget);

    router.go('/menu/coffee');
    await tester.pumpAndSettle();
    expect(find.text('No drink called "coffee"'), findsOneWidget);
  });
}
