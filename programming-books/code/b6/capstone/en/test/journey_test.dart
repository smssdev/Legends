import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('from the menu to an order that is ready', (tester) async {
    final api = FakeApi();
    await tester.pumpWidget(
      cafe(
        overrides: [
          apiProvider.overrideWithValue(api),
          prefsProvider.overrideWithValue(memoryPrefs()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Cherry cake'));
    await tester.tap(find.byTooltip('Open your order'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 145 EGP'), findsOneWidget);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order 41'), findsOneWidget);
    expect(api.placed.single, {'latte': 2, 'cake': 1});
  });
}
