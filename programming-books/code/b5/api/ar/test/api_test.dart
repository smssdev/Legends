import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/cafe_api.dart';

void main() {
  test('القائمة تُحلَّل، والفشل يقول لماذا', () async {
    final good = MockClient((request) async {
      expect(request.url.path, '/menu');
      return http.Response(
        '[{"id": 1, "name": "لاتيه", "price": 45, "image": "latte"}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final drinks = await CafeApi(good).menu();
    expect(drinks.single.name, 'لاتيه');
    expect(drinks.single.price, 45);

    final bad = MockClient(
      (request) async => http.Response(
        '{"error": "المطبخ يحترق"}',
        500,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    expect(() => CafeApi(bad).menu(), throwsA(isA<ApiException>()));
  });
}
