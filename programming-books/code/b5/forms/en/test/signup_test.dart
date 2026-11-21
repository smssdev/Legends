import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_signup.dart';

void main() {
  testWidgets('the sign-up form checks that the passwords match', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'sara@example.com');
    await tester.enterText(fields.at(1), 'coffee2026');
    await tester.enterText(fields.at(2), 'coffee2025');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('The passwords do not match'), findsOneWidget);
    expect(find.text('Please accept the terms'), findsOneWidget);

    await tester.enterText(fields.at(2), 'coffee2026');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Account created'), findsOneWidget);
  });
}
