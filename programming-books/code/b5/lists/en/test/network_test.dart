import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/network.dart';

void main() {
  testWidgets('a picture that cannot load shows the fallback', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Photo()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
