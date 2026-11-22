import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/api/client.dart';

/// A server that saves every order, but loses the answer to the first one.
class Server {
  final orders = <int>[];
  final seen = <String, int>{};
  var lost = false;

  late final client = MockClient((request) async {
    final key = request.headers['idempotency-key'];
    // الخادم يحفظ المفاتيح التي رآها، ويجيب التكرار بالنتيجة الأولى.
    final id =
        (key != null ? seen[key] : null) ??
        (orders..add(orders.length + 1)).last;
    if (key != null) {
      seen[key] = id;
    }
    if (!lost) {
      lost = true;
      // حُفظ الطلب، لكن الإجابة ضاعت في طريق العودة.
      throw http.ClientException('connection reset');
    }
    return http.Response(jsonEncode({'id': id}), 201);
  });
}

void main() {
  test('مع المفتاح، الطلب المعاد يُنشأ مرة واحدة', () async {
    final withKey = Server();
    final api = ApiClient(withKey.client, base: '', sleep: (_) async {});
    // مفتاح واحد لكل طلب يرسله الشخص، لا لكل محاولة.
    final placed = await api.post('/orders', {
      'latte': 1,
    }, idempotencyKey: 'order-7f3a');
    debugPrint(
      'with a key: answer $placed, orders on the server: ${withKey.orders}',
    );
    expect(withKey.orders, [1]);

    final noKey = Server();
    final retrying = ApiClient(noKey.client, base: '', sleep: (_) async {});
    for (var i = 0; i < 2; i++) {
      try {
        await retrying.post('/orders', {'latte': 1});
      } on Object {
        // The person taps again.
      }
    }
    debugPrint(
      'without a key, tapped twice: orders on the server: ${noKey.orders}',
    );
  });
}
