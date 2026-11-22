import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/rows.dart';

var created = 0;

DrinkRow row(int n) {
  created++;
  return DrinkRow(n: n);
}

Future<void> measure(
  WidgetTester tester,
  String name,
  Widget Function() list,
) async {
  created = 0;
  rowBuilds = 0;
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: list())));
  debugPrint('${name.padRight(21)}$created rows created, $rowBuilds built');
}

void main() {
  testWidgets('a list of 1000 drinks, how many rows are built', (tester) async {
    await measure(
      tester,
      'ListView(children:)',
      () => ListView(children: [for (var n = 1; n <= 1000; n++) row(n)]),
    );
    await measure(
      tester,
      'ListView.builder',
      () => ListView.builder(
        itemCount: 1000,
        itemBuilder: (context, i) => row(i + 1),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    debugPrint(
      'after scrolling 3000 pixels: ${find.byType(DrinkRow).evaluate().length} rows alive, $created created in all',
    );
    expect(created, lessThan(100));
  });
}
