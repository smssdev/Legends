import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_about.dart';

void main() {
  testWidgets('صفحة «عن المقهى» تُفتح وتُغلق', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.tap(find.text('عن مقهى بِت'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'مقهى صغير على النيل، مفتوح منذ 2020. نحمّص قهوتنا بأنفسنا ونخبز كل صباح.',
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'مقهى صغير على النيل، مفتوح منذ 2020. نحمّص قهوتنا بأنفسنا ونخبز كل صباح.',
      ),
      findsNothing,
    );
  });
}
