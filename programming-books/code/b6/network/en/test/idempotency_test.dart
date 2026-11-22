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
    // The server keeps the keys it has seen, and answers a repeat with the first result.
    final id =
        (key != null ? seen[key] : null) ??
        (orders..add(orders.length + 1)).last;
    if (key != null) {
      seen[key] = id;
    }
    if (!lost) {
      lost = true;
      // The order was saved, but the answer is lost on the way back.
      throw http.ClientException('connection reset');
    }
    return http.Response(jsonEncode({'id': id}), 201);
  });
}

void main() {
  test('with a key, a retried order is created once', () async {
    final withKey = Server();
    final api = ApiClient(withKey.client, base: '', sleep: (_) async {});
    // One key per order the person placed, not per attempt.
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
