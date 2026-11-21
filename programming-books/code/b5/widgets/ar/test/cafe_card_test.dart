import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_card.dart';

void main() {
  testWidgets('الكمية تغيّر الإجمالي', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrinkCard(name: 'X', description: 'Y', price: 45),
        ),
      ),
    );
    expect(find.text('الإجمالي: 45'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('الإجمالي: 135'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('الإجمالي: 90'), findsOneWidget);
  });
}
