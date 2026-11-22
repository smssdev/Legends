import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/data/orders_source.dart';
import 'package:bit_app/features/orders/domain/place_order.dart';
import 'package:bit_app/features/orders/presentation/orders_controller.dart';
import 'package:bit_app/features/orders/presentation/orders_page.dart';

Widget app({required int hour}) {
  final repo = OrdersRepositoryImpl(FakeOrdersSource());
  return ChangeNotifierProvider(
    // A new key for each hour: without it, Flutter would keep the first provider (Chapter 1).
    key: ValueKey(hour),
    create: (context) => OrdersController(
      PlaceOrder(repo, clock: () => DateTime(2026, 11, 22, hour)),
      repo,
    ),
    child: const MaterialApp(home: OrdersPage()),
  );
}

void main() {
  testWidgets('the page shows the placed order, or the failure in words', (
    tester,
  ) async {
    await tester.pumpWidget(app(hour: 10));
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Order 1 · 45 EGP'), findsOneWidget);

    await tester.pumpWidget(app(hour: 23));
    await tester.tap(find.byTooltip('Add Latte'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(
      find.text('The café is closed. We open from 8:00 to 22:00.'),
      findsOneWidget,
    );
  });
}
