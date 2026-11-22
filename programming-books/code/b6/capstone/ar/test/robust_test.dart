import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_app.dart';
import 'package:bit_app/state/providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('كل شاشة، داكنة وبنص 200%، بلا فيض', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      cafe(
        overrides: [
          apiProvider.overrideWithValue(FakeApi()),
          prefsProvider.overrideWithValue(memoryPrefs()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final checked = <String>[];
    void check(String page) {
      expect(tester.takeException(), isNull, reason: page);
      checked.add(page);
    }

    check('menu');
    await tester.tap(find.byTooltip('أضف Latte'));
    await tester.tap(find.byTooltip('افتح طلبك'));
    await tester.pumpAndSettle();
    check('cart');
    await tester.tap(find.text('أرسل الطلب'));
    await tester.pumpAndSettle();
    check('order');
    debugPrint(
      'dark theme, text at 200%, 360 x 640: ${checked.join(', ')} without overflow',
    );
  });
}
