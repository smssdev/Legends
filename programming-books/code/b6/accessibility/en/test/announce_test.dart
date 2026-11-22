import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/announce.dart';
import 'package:bit_app/cafe.dart';

void main() {
  testWidgets('adding a drink is announced', (tester) async {
    await tester.pumpWidget(cafe(const OrderCounter()));
    await tester.tap(find.text('Add Latte'));
    await tester.tap(find.text('Add Latte'));
    await tester.pump();
    final said = tester.takeAnnouncements();
    for (final announcement in said) {
      debugPrint(
        'announced (${announcement.assertiveness.name}): "${announcement.message}"',
      );
    }
    expect(said, hasLength(2));
  });
}
