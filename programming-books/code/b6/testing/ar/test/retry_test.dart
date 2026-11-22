import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

class FlakyMenu implements MenuRepository {
  var calls = 0;

  @override
  Future<List<Drink>> menu() async {
    calls++;
    if (calls == 1) {
      throw const MenuException('timeout');
    }
    return const [Drink('latte', 'Latte', 45)];
  }
}

void main() {
  testWidgets('«حاول مرة أخرى» تسأل المستودع من جديد', (tester) async {
    final flaky = FlakyMenu();
    await tester.pumpWidget(MaterialApp(home: MenuScreen(repository: flaky)));
    await tester.pump();
    expect(find.text('تعذّر تحميل القائمة.'), findsOneWidget);
    expect(flaky.calls, 1);

    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(flaky.calls, 2);
    expect(find.text('Latte'), findsOneWidget);
  });
}
