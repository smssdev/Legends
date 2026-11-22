import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';
import 'package:bit_app/cafe/pages.dart';

import 'helpers.dart';

void main() {
  testWidgets('التغييرات غير المحفوظة لا تضيع خطأً', (tester) async {
    EditNamePage.unsaved = false;
    final router = await pumpCafe(tester, Auth()..signIn());
    router.go('/account/edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sara');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('تغادر دون حفظ؟'), findsOneWidget);
    await tester.tap(find.text('ابقَ'));
    await tester.pumpAndSettle();
    expect(where(router), '/account/edit');

    await tester.tap(find.text('القائمة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تجاهل'));
    await tester.pumpAndSettle();
    expect(where(router), '/menu');
  });
}
