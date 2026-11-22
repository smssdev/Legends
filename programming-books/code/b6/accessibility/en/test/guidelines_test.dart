import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/menu_careful.dart';
import 'package:bit_app/menu_hurried.dart';

const guidelines = {
  'labeled tap targets': labeledTapTargetGuideline,
  'Android tap targets (48 x 48)': androidTapTargetGuideline,
  'iOS tap targets (44 x 44)': iOSTapTargetGuideline,
  'text contrast': textContrastGuideline,
};

Future<int> check(WidgetTester tester, String name, Widget menu) async {
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(cafe(menu));
  var failed = 0;
  debugPrint('$name menu:');
  for (final MapEntry(key: rule, value: guideline) in guidelines.entries) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) {
      failed++;
    }
    final first = result.reason?.split('\n').first ?? '';
    debugPrint(
      '  ${result.passed ? 'pass' : 'FAIL'}  ${rule.padRight(30)}${first.length > 70 ? '${first.substring(0, 70)}...' : first}',
    );
  }
  semantics.dispose();
  return failed;
}

void main() {
  testWidgets('four accessibility guidelines, hurried and careful menus', (
    tester,
  ) async {
    final hurried = await check(tester, 'hurried', const HurriedMenu());
    final careful = await check(tester, 'careful', const CarefulMenu());
    expect(hurried, greaterThan(0));
    expect(careful, 0);
  });
}
