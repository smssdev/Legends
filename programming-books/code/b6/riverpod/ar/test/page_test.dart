import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/features/orders/presentation/orders_page.dart';
import 'package:bit_app/features/orders/providers.dart';

void main() {
  testWidgets('الإضافة والإرسال وتحديث السجل', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 22, 10)),
        ],
        child: const OrdersApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لم تطلب شيئاً بعد'), findsOneWidget);

    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.tap(find.byTooltip('أضف كيك الكرز'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('أرسل الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('الطلب 1 · 105 جنيه'), findsOneWidget);
  });
}
