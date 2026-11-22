import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';
import 'package:bit_app/checkout.dart';

Future<List<String>> tabs(WidgetTester tester, {required bool ordered}) async {
  await tester.pumpWidget(
    cafe(Checkout(key: ValueKey(ordered), ordered: ordered)),
  );
  final visited = <String>[];
  for (var i = 0; i < 3; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    visited.add(FocusManager.instance.primaryFocus?.debugLabel ?? '?');
  }
  return visited;
}

void main() {
  testWidgets('the order of the Tab key', (tester) async {
    debugPrint(
      'by position: ${(await tabs(tester, ordered: false)).join(' -> ')}',
    );
    final ordered = await tabs(tester, ordered: true);
    debugPrint('in order:    ${ordered.join(' -> ')}');
    expect(ordered, ['name', 'phone', 'pay']);
  });
}
