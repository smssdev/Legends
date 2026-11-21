import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('لا تُبنى إلا العناصر الظاهرة', (tester) async {
    final built = <int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, i) {
              built.add(i);
              return ListTile(title: Text('طلب رقم ${i + 1}'));
            },
          ),
        ),
      ),
    );
    debugPrint('built ${built.length} of 1000');

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    debugPrint('after scrolling: built ${built.length} of 1000');
    expect(built.length, lessThan(100));
  });
}
