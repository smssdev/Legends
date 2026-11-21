import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_traffic_light.dart';

void main() {
  testWidgets('the button moves to the next light', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrafficLight()));
    expect(find.text('Stop'), findsOneWidget);
    for (final label in ['Get ready', 'Go', 'Stop']) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });
}
