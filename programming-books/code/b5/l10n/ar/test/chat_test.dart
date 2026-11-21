import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_chat.dart';

void main() {
  testWidgets('رسائلي في النهاية، في الاتجاهين', (tester) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: const Scaffold(
              body: Column(
                children: [
                  Bubble(text: 'mine', mine: true),
                  Bubble(text: 'theirs', mine: false),
                ],
              ),
            ),
          ),
        ),
      );
      final mine = tester.getCenter(find.text('mine')).dx;
      final theirs = tester.getCenter(find.text('theirs')).dx;
      // Left to right: mine on the right. Right to left: mine on the left.
      expect(mine > theirs, direction == TextDirection.ltr);
    }
  });
}
