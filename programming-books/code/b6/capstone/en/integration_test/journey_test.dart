import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('from the menu to an order that is ready', (tester) async {
    await tester.pumpWidget(cafe());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Cherry cake'));
    await tester.tap(find.byTooltip('Open your order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Being prepared'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    final ready = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Ready at the counter'),
    );
    debugPrint(
      'order 41: ${ready.selected ? 'ready' : 'not ready'} after a pull to refresh',
    );
    expect(ready.selected, isTrue);
  });
}
