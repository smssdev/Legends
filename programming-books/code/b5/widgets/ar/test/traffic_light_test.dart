import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/projects_traffic_light.dart';

void main() {
  testWidgets('الزر ينقل إلى الضوء التالي', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrafficLight()));
    expect(find.text('قف'), findsOneWidget);
    for (final label in ['استعد', 'انطلق', 'قف']) {
      await tester.tap(find.text('التالي'));
      await tester.pump();
      expect(find.text(label), findsOneWidget);
    }
  });
}
