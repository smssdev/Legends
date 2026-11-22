import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('من القائمة إلى طلب جاهز', (tester) async {
    await tester.pumpWidget(cafe());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.tap(find.byTooltip('أضف كيك الكرز'));
    await tester.tap(find.byTooltip('افتح طلبك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرسل الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('قيد التحضير'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    final ready = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'جاهز عند المنضدة'),
    );
    debugPrint(
      'order 41: ${ready.selected ? 'ready' : 'not ready'} after a pull to refresh',
    );
    expect(ready.selected, isTrue);
  });
}
