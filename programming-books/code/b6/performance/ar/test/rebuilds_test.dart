import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_fast.dart';
import 'package:bit_app/order_slow.dart';
import 'package:bit_app/rows.dart';

Future<int> rowsRebuiltByOneTap(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: page));
  rowBuilds = 0;
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
  return rowBuilds;
}

void main() {
  testWidgets('ضغطة واحدة، كم صفاً يُعاد بناؤه', (tester) async {
    final slow = await rowsRebuiltByOneTap(tester, const SlowOrderPage());
    final fast = await rowsRebuiltByOneTap(tester, const FastOrderPage());
    debugPrint('rows rebuilt by one tap: slow page $slow, fast page $fast');
    expect(fast, 0);
  });
}
