import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('من القائمة إلى طلب جاهز', (tester) async {
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
    await tester.tap(find.byTooltip('أضف Latte'));
    await tester.tap(find.byTooltip('أضف Latte'));
    await tester.tap(find.byTooltip('أضف Cherry cake'));
    await tester.tap(find.byTooltip('افتح طلبك'));
    await tester.pumpAndSettle();
    expect(find.text('المجموع: 145 جنيه'), findsOneWidget);
    await tester.tap(find.text('أرسل الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('الطلب 41'), findsOneWidget);
    expect(api.placed.single, {'latte': 2, 'cake': 1});
  });
}
