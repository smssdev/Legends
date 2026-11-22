import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/data/menu.dart';
import 'package:bit_app/ui/menu_screen.dart';

void main() {
  testWidgets('a drink tile in Arabic and in dark mode', (tester) async {
    tester.view.physicalSize = const Size(320, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.brown,
          brightness: Brightness.dark,
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: DrinkTile(
                  drink: Drink('latte', 'لاتيه', 45),
                  quantity: 2,
                  onAdd: _nothing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(DrinkTile),
      matchesGoldenFile('goldens/drink_tile_rtl_dark.png'),
    );
  });
}

void _nothing() {}
