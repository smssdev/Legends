import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_shopping.dart';

void main() {
  testWidgets('السحب يحذف العنصر، وزر التراجع يعيده', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShoppingPage()));
    final first = 'حليب,حبوب قهوة,سكر,أكواب,مناديل,برتقال'.split(',').first;
    expect(find.text(first), findsOneWidget);

    await tester.drag(find.text(first), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text(first), findsNothing);

    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(find.text(first), findsOneWidget);
  });
}
