import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/form.dart';

void main() {
  testWidgets('the form refuses empty fields and accepts good ones', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CallBackForm()));

    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('A phone number has 11 digits'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sara');
    await tester.enterText(find.byType(TextFormField).at(1), '01001234567');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'sara@example.com',
    );
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(find.text('Please enter your name'), findsNothing);
    expect(find.text('Thank you, we will call you'), findsOneWidget);
  });
}
