import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/core/result.dart';
import 'package:bit_app/features/orders/data/http_orders_source.dart';
import 'package:bit_app/features/orders/data/orders_repository_impl.dart';
import 'package:bit_app/features/orders/domain/failures.dart';
import 'package:bit_app/features/orders/domain/order.dart';

void main() {
  test('the HTTP source maps answers and errors', () async {
    final server = MockClient((request) async {
      final items = (jsonDecode(request.body) as Map)['items'] as Map;
      if (items.containsKey('cake')) {
        return http.Response('{"error": "sold out"}', 409);
      }
      return http.Response(
        jsonEncode({
          'id': 7,
          'items': items,
          'status': 'pending',
          'placed_at': '2026-11-22T10:00:00',
        }),
        201,
      );
    });
    final repo = OrdersRepositoryImpl(HttpOrdersSource(server));

    final ok = await repo.place([OrderLine(menu[1], 3)]) as Ok;
    expect((ok.value as Order).total.pounds, 75);
    expect(
      (await repo.place([OrderLine(menu[2], 1)]) as Err).failure,
      isA<NetworkFailure>(),
    );
  });
}
