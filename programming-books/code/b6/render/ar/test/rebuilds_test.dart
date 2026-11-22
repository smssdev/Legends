import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/rebuilds.dart';

void main() {
  testWidgets('setState تعيد بناء الـ Widget وكل جديد تحته', (tester) async {
    builds.clear();
    await tester.pumpWidget(const MaterialApp(home: RebuildsPage()));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
    }
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
    }
    debugPrint('$builds');
    expect(builds, {'page': 4, 'const': 1, 'plain': 4, 'local': 6});
  });
}
