import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_stars.dart';

void main() {
  testWidgets('tapping the fourth star gives 4', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RatePage()));
    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pump();
    expect(find.text('4 out of 5'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });
}
