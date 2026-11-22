import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe/auth.dart';

import 'helpers.dart';

void main() {
  testWidgets('الحساب يحتاج تسجيل الدخول، ويعود إلى حيث طُلب', (tester) async {
    final auth = Auth();
    final router = await pumpCafe(tester, auth);

    router.go('/account');
    await tester.pumpAndSettle();
    debugPrint('signed out, asked /account: ${where(router)}');

    auth.signIn();
    await tester.pumpAndSettle();
    debugPrint('after signing in:           ${where(router)}');
    expect(where(router), '/account');

    auth.signOut();
    await tester.pumpAndSettle();
    debugPrint('after signing out:          ${where(router)}');

    router.go('/signin?from=https://evil.example');
    auth.signIn();
    await tester.pumpAndSettle();
    debugPrint('from an outside address:    ${where(router)}');
    expect(where(router), '/menu');
  });
}
