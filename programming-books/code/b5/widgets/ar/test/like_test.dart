import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/like.dart';

void main() {
  testWidgets('الضغط على القلب يضيف إعجاباً', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LikePage()));
    expect(find.text('0 إعجاب'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.text('1 إعجاب'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
