import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

Widget tile(ThemeData theme) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  home: const Scaffold(
    body: Center(
      child: SizedBox(
        width: 320,
        child: DrinkTile(
          drink: Drink('latte', 'Latte', 45),
          quantity: 2,
          onAdd: _nothing,
        ),
      ),
    ),
  ),
);

void _nothing() {}

void main() {
  testWidgets('بلاطة المشروب كما اعتُمدت', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(tile(ThemeData(colorSchemeSeed: Colors.brown)));
    await expectLater(
      find.byType(DrinkTile),
      matchesGoldenFile('goldens/drink_tile.png'),
    );
  });
}
