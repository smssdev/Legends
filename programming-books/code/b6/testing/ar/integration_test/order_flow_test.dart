import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/data/demo_menu.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('من بداية فاشلة إلى طلب', (tester) async {
    await tester.pumpWidget(
      BitApp(repository: DemoMenu(), now: () => DateTime(2026, 11, 23, 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل القائمة.'), findsOneWidget);

    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لاتيه'));
    await tester.tap(find.text('لاتيه'));
    await tester.tap(find.text('كيك الكرز'));
    await tester.pumpAndSettle();
    expect(find.text('المجموع: 145 جنيه'), findsOneWidget);
  });
}
