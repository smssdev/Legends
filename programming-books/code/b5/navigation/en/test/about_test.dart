import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_about.dart';

void main() {
  testWidgets('the about page opens and closes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.tap(find.text('About Bit Café'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'A small café on the Nile, open since 2020. We roast our own coffee and bake every morning.',
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'A small café on the Nile, open since 2020. We roast our own coffee and bake every morning.',
      ),
      findsNothing,
    );
  });
}
