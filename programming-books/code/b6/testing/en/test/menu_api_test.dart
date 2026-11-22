import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/data/menu.dart';

void main() {
  test('reads the menu from the server', () async {
    // A fake HTTP client from package:http: it answers like a server, and checks the request.
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.bitcafe.online/menu');
      return http.Response(
        jsonEncode([
          {'id': 'latte', 'name': 'Latte', 'price': 45},
        ]),
        200,
      );
    });
    final menu = await MenuApi(client).menu();
    expect(menu.single.name, 'Latte');
    expect(menu.single.price, 45);
  });

  test('a server error becomes a MenuException', () async {
    final client = MockClient((request) async => http.Response('oops', 500));
    expect(
      MenuApi(client).menu(),
      throwsA(
        isA<MenuException>().having((e) => e.reason, 'reason', 'status 500'),
      ),
    );
  });
}
