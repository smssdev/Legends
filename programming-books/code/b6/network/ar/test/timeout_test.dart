import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/retry.dart';

void main() {
  test('الخادم الذي لا يجيب أبداً يصير TimedOut', () async {
    final never = MockClient((r) => Completer<http.Response>().future);
    final api = ApiClient(
      never,
      base: '',
      timeout: const Duration(milliseconds: 50),
      policy: const RetryPolicy(attempts: 1),
    );
    final watch = Stopwatch()..start();
    await expectLater(api.get('/menu'), throwsA(isA<TimedOut>()));
    expect(watch.elapsedMilliseconds, lessThan(1000));
  });
}
