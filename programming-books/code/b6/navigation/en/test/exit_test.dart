import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/pages.dart';

import 'helpers.dart';

void main() {
  testWidgets('unsaved changes are not lost by accident', (tester) async {
    EditNamePage.unsaved = false;
    final router = await pumpCafe(tester, Auth()..signIn());
    router.go('/account/edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sara');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(where(router), '/account/edit');

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu');
  });
}
