import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/menu_app.dart';

void main() {
  testWidgets('القائمة تُحمَّل، والفشل يعرض إعادة المحاولة', (tester) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response(
          '{"error": "المطبخ يحترق"}',
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        '[{"id": 2, "name": "شاي بالنعناع", "price": 25, "image": "tea"}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    await tester.pumpWidget(CafeApp(api: CafeApi(client)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('المطبخ يحترق'), findsOneWidget);

    await tester.tap(find.text('أعد المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('شاي بالنعناع'), findsOneWidget);
  });
}
