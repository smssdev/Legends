import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_routes.dart';

void main() {
  testWidgets('an unknown drink shows the not-found page', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router('/drinks/99')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);

    await tester.tap(find.text('Back to the menu'));
    await tester.pumpAndSettle();
    expect(find.text('Latte'), findsOneWidget);
  });
}
