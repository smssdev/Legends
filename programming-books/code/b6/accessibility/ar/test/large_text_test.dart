import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/menu_careful.dart';
import 'package:bit_app/menu_hurried.dart';

Future<void> atTwice(WidgetTester tester, String name, Widget menu) async {
  tester.view.physicalSize = const Size(1170, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(cafe(menu, textScale: 2));
  final problem = tester.takeException();
  debugPrint(
    '$name menu at 200%: ${problem == null ? 'fits' : problem.toString().split('\n').first}',
  );
}

void main() {
  testWidgets('القائمتان والنص بضعف حجمه', (tester) async {
    await atTwice(tester, 'hurried', const HurriedMenu());
    await atTwice(tester, 'careful', const CarefulMenu());
  });
}
