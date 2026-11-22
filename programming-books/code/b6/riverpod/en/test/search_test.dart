import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('only the last query is searched', (tester) async {
    searches = [];
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SearchPage())),
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (final text in ['t', 'te', 'tea']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, ['', 'tea']);
    expect(find.text('Mint tea'), findsOneWidget);
  });
}
