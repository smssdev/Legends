import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/keys.dart';

void main() {
  testWidgets('without keys the state stays behind; with keys it moves', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: KeysPage()));
    // Tap A three times in both rows.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('A').first);
      await tester.tap(find.text('A').last);
      await tester.pump();
    }
    await tester.tap(find.text('Swap'));
    await tester.pump();

    String tapsUnder(Finder label) => (tester.widget<Text>(
      find.descendant(
        of: find.ancestor(of: label, matching: find.byType(Column)),
        matching: find.textContaining(':'),
      ),
    )).data!;
    // Without keys: A moved to the other side, but its 3 taps stayed where they were.
    expect(tapsUnder(find.text('A').first), 'Tap: 0');
    // With keys: the 3 taps of A moved with it.
    expect(tapsUnder(find.text('A').last), 'Tap: 3');
  });
}
