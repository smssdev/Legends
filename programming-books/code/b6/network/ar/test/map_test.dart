import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/retry.dart';

void main() {
  test('كل رمز حالة يصير خطأه', () async {
    final answers = <int, String>{
      200: '{"ok": true}',
      201: 'not json',
      401: '',
      404: '',
      409: '{"error": "Sold out"}',
      500: '',
      503: '',
    };
    for (final MapEntry(key: status, value: body) in answers.entries) {
      final api = ApiClient(
        MockClient((r) async => http.Response(body, status)),
        base: '',
        policy: const RetryPolicy(attempts: 1),
      );
      try {
        debugPrint('$status -> ${await api.get('/x')}');
      } on ApiError catch (e) {
        debugPrint('$status -> ${describe(e)}');
      }
    }
    final offline = ApiClient(
      MockClient((r) => throw http.ClientException('connection refused')),
      base: '',
      policy: const RetryPolicy(attempts: 1),
    );
    expect(() => offline.get('/x'), throwsA(isA<Offline>()));
  });
}
