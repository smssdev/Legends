import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_search.dart';

void main() {
  testWidgets('آخر بحث وحده يُنفَّذ', (tester) async {
    searches = [];
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SearchPage())),
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (final text in ['ش', 'شا', 'شاي']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(searches, ['', 'شاي']);
    expect(find.text('شاي بالنعناع'), findsOneWidget);
  });
}
