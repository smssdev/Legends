import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/projects_favourites.dart';

void main() {
  testWidgets('a heart on one tab shows on the other', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => Favourites(),
        child: const MaterialApp(home: Shell()),
      ),
    );
    await tester.tap(find.byTooltip('Like Mint tea'));
    await tester.pump();
    await tester.tap(find.text('Favourites'));
    await tester.pump();
    expect(find.text('Mint tea'), findsOneWidget);
    expect(find.text('Latte'), findsNothing);
  });
}
