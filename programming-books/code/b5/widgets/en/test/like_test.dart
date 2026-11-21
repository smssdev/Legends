import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/like.dart';

void main() {
  testWidgets('tapping the heart adds a like', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LikePage()));
    expect(find.text('0 likes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.text('1 likes'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
