import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('الكتابة تصفّي القائمة', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    expect(find.byType(ListTile), findsNWidgets(drinks.length));

    await tester.enterText(find.byType(TextField), 'شاي');
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('لا مشروب مطابق'), findsOneWidget);
  });
}
