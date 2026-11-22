import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe.dart';

void main() {
  testWidgets('the grey description, checked on its own', (tester) async {
    final semantics = tester.ensureSemantics();
    final grey = Text(
      'Espresso and steamed milk',
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
    );
    await tester.pumpWidget(cafe(Scaffold(body: Center(child: grey))));
    final result = await textContrastGuideline.evaluate(tester);
    debugPrint('text contrast: ${result.passed ? 'pass' : 'FAIL'}');
    debugPrint(
      result.reason!
          .split('\n')
          .where((line) => line.contains('ratio'))
          .join('\n'),
    );
    expect(result.passed, isFalse);
    semantics.dispose();
  });
}
