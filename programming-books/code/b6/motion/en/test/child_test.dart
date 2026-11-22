import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/brewing.dart';

void main() {
  testWidgets('the child of an AnimatedBuilder is built once', (tester) async {
    cupBuilds = 0;
    await tester.pumpWidget(const MaterialApp(home: BrewingPage()));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    debugPrint('60 frames of the ring, the cup was built $cupBuilds time');
    expect(cupBuilds, 1);
  });
}
