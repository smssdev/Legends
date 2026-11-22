import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/offline_app.dart';

void main() {
  testWidgets('offline, the order still appears, marked as waiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OrdersPage())),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(
      find.text(
        'You are offline. New orders are kept here and sent when you are back.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Order a latte'));
    await tester.pumpAndSettle();
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Waiting to send'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();
    expect(find.text('Sent · new'), findsOneWidget);
  });
}
