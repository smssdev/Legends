import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/projects_live_search.dart';

void main() {
  testWidgets('البحث ينتظر حتى تتوقف الكتابة', (tester) async {
    final asked = <String>[];
    final client = MockClient((request) async {
      asked.add(request.url.queryParameters['q'] ?? '');
      return http.Response(
        '[{"id": 2, "name": "شاي بالنعناع", "price": 25, "image": "tea"}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    await tester.pumpWidget(
      MaterialApp(home: SearchPage(api: CafeApi(client))),
    );

    for (final text in ['ش', 'شا', 'شاي']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(asked, isEmpty);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(asked, ['شاي']);
    expect(find.text('شاي بالنعناع'), findsOneWidget);
  });
}
