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
    // مفتاح جديد لكل ساعة: بدونه يُبقي Flutter الـ provider الأول (الفصل 1).
    key: ValueKey(hour),
    create: (context) => OrdersController(
      PlaceOrder(repo, clock: () => DateTime(2026, 11, 22, hour)),
      repo,
    ),
    child: const MaterialApp(home: OrdersPage()),
  );
}

void main() {
  testWidgets('الصفحة تعرض الطلب المرسل، أو الفشل بالكلمات', (tester) async {
    await tester.pumpWidget(app(hour: 10));
    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('الطلب 1 · 45 جنيه'), findsOneWidget);

    await tester.pumpWidget(app(hour: 23));
    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('المقهى مغلق. نفتح من 8:00 إلى 22:00.'), findsOneWidget);
  });
}
