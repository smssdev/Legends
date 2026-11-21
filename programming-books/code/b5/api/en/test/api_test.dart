import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/cafe_api.dart';

void main() {
  test('the menu is parsed, and a failure says why', () async {
    final good = MockClient((request) async {
      expect(request.url.path, '/menu');
      return http.Response(
        '[{"id": 1, "name": "Latte", "price": 45, "image": "latte"}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final drinks = await CafeApi(good).menu();
    expect(drinks.single.name, 'Latte');
    expect(drinks.single.price, 45);

    final bad = MockClient(
      (request) async => http.Response(
        '{"error": "The kitchen is on fire"}',
        500,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    expect(() => CafeApi(bad).menu(), throwsA(isA<ApiException>()));
  });
}
