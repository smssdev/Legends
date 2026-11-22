import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('AnimatedOpacity، إطاراً إطاراً', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrderPage()));
    final total = find
        .ancestor(
          of: find.textContaining('جنيه'),
          matching: find.byType(FadeTransition),
        )
        .first;
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    for (var ms = 0; ms <= 300; ms += 50) {
      final opacity = tester.widget<FadeTransition>(total).opacity.value;
      final height = tester.getSize(find.byKey(const ValueKey('card'))).height;
      debugPrint(
        '${'$ms ms'.padRight(8)}opacity ${opacity.toStringAsFixed(2)}   height ${height.toStringAsFixed(0)}',
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
}
