import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/cafe_api.dart';
import 'package:bit_app/projects_send_order.dart';

void main() {
  testWidgets('the message from the server is shown', (tester) async {
    final client = MockClient(
      (request) async => http.Response(
        '{"error": "A name is needed"}',
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: SendOrderPage(api: CafeApi(client))),
    );
    await tester.tap(find.text('Send order'));
    await tester.pumpAndSettle();
    expect(find.text('A name is needed'), findsOneWidget);
  });
}
