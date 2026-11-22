import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/ui/menu_screen.dart';

import 'golden_test.dart' show tile;

void main() {
  testWidgets('a drink tile looks as approved', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A teammate changes the brand colour, and forgets the tiles.
    await tester.pumpWidget(tile(ThemeData(colorSchemeSeed: Colors.teal)));
    await expectLater(
      find.byType(DrinkTile),
      matchesGoldenFile('goldens/drink_tile.png'),
    );
  });
}
