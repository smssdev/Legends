import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/data/demo_menu.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('from a failed start to an order', (tester) async {
    await tester.pumpWidget(
      BitApp(repository: DemoMenu(), now: () => DateTime(2026, 11, 23, 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('The menu could not be loaded.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Latte'));
    await tester.tap(find.text('Cherry cake'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 145 EGP'), findsOneWidget);
  });
}
