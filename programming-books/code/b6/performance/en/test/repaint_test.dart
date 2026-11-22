import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/repaint.dart';

Future<int> paintsIn60Frames(
  WidgetTester tester, {
  required bool boundary,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey(boundary),
      home: Dashboard(boundary: boundary),
    ),
  );
  chartPaints = 0;
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return chartPaints;
}

void main() {
  testWidgets('sixty frames of a spinner, how many times the chart is painted', (
    tester,
  ) async {
    final without = await paintsIn60Frames(tester, boundary: false);
    final withBoundary = await paintsIn60Frames(tester, boundary: true);
    debugPrint(
      'chart painted in 60 frames: without a boundary $without, with one $withBoundary',
    );
    expect(withBoundary, 0);
  });
}
