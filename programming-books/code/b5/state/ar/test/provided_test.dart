import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/basket.dart';
import 'package:bit_app/provided.dart';

void main() {
  testWidgets('الإضافة في القائمة تظهر في صفحة السلة', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => Basket(),
        child: const MaterialApp(home: MenuPage()),
      ),
    );
    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.tap(find.byTooltip('أضف لاتيه'));
    await tester.tap(find.byTooltip('أضف كيك الكرز'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('السلة'));
    await tester.pumpAndSettle();
    expect(find.text('2 × لاتيه'), findsOneWidget);
    expect(find.text('إتمام الطلب · 150 جنيه'), findsOneWidget);
  });
}
