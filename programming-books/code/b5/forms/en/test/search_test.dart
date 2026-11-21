import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('typing filters the list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    expect(find.byType(ListTile), findsNWidgets(drinks.length));

    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('No drink matches'), findsOneWidget);
  });
}
