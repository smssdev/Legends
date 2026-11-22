import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/presentation/orders_page.dart';
import 'package:bit_app/features/orders/providers.dart';

void main() {
  testWidgets('adding, placing, and the history refreshed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
        ],
        child: const OrdersApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nothing ordered yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Latte'));
    await tester.tap(find.byTooltip('Add Cherry cake'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order 1 · 105 EGP'), findsOneWidget);
  });
}
