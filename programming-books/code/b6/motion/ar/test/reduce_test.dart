import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/order_card.dart';

void main() {
  testWidgets('مع تقليل الحركة يكون التغيير فورياً', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: OrderPage()),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();
    final height = tester.getSize(find.byKey(const ValueKey('card'))).height;
    debugPrint('one frame after the tap: height ${height.toStringAsFixed(0)}');
    expect(height, 180);
  });
}
