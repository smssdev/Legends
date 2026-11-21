import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:bit_app/projects_favourites.dart';

void main() {
  testWidgets('القلب في تبويب يظهر في الآخر', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => Favourites(),
        child: const MaterialApp(home: Shell()),
      ),
    );
    await tester.tap(find.byTooltip('أعجبني شاي بالنعناع'));
    await tester.pump();
    await tester.tap(find.text('المفضلة'));
    await tester.pump();
    expect(find.text('شاي بالنعناع'), findsOneWidget);
    expect(find.text('لاتيه'), findsNothing);
  });
}
