import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/basket.dart';
import 'package:bit_app/provided.dart';

void main() {
  testWidgets('adding on the menu shows up in the basket page', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => Basket(),
        child: const MaterialApp(home: MenuPage()),
      ),
    );
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Cherry cake'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('Basket'));
    await tester.pumpAndSettle();
    expect(find.text('2 × Latte'), findsOneWidget);
    expect(find.text('Check out · 150 EGP'), findsOneWidget);
  });
}
