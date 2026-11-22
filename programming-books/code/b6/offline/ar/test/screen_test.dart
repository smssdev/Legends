import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/offline_app.dart';

void main() {
  testWidgets('بلا اتصال يظهر الطلب، معلَّماً بأنه ينتظر', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OrdersPage())),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(
      find.text('أنت غير متصل. الطلبات الجديدة تُحفظ هنا وتُرسل حين تعود.'),
      findsOneWidget,
    );

    await tester.tap(find.text('اطلب لاتيه'));
    await tester.pumpAndSettle();
    expect(find.text('لاتيه'), findsOneWidget);
    expect(find.text('ينتظر الإرسال'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('زامن الآن'));
    await tester.pumpAndSettle();
    expect(find.text('أُرسل · جديد'), findsOneWidget);
  });
}
