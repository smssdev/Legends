import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';

/// A server that answers with these statuses, in order, then 200.
ApiClient serverSaying(
  List<int> statuses,
  List<String> log, {
  Map<String, String> headers = const {},
}) {
  var i = 0;
  return ApiClient(
    MockClient(
      (r) async => http.Response(
        '{}',
        i < statuses.length ? statuses[i++] : 200,
        headers: headers,
      ),
    ),
    base: '',
    random: Random(1),
    // The test does not really wait: the log shows what would have been waited.
    sleep: (d) async {},
    log: log.add,
  );
}

Future<void> run(
  String title,
  Future<Object?> Function() request,
  List<String> log,
) async {
  try {
    await request();
  } on ApiError {
    // The log says what happened.
  }
  debugPrint([title, ...log].join('\n'));
}

void main() {
  test('retries wait longer each time, and only when it can help', () async {
    final a = <String>[];
    await run(
      'GET, busy three times:',
      () => serverSaying([503, 503, 503], a).get('/menu'),
      a,
    );
    expect(a.last, 'attempt 4: OK');

    final b = <String>[];
    await run(
      'GET, a bug on the server:',
      () => serverSaying([500], b).get('/menu'),
      b,
    );
    final c = <String>[];
    await run(
      'POST without a key:',
      () => serverSaying([503], c).post('/orders', {}),
      c,
    );
    final d = <String>[];
    await run(
      'POST with a key:',
      () => serverSaying([503], d).post('/orders', {}, idempotencyKey: 'k1'),
      d,
    );
    final e = <String>[];
    await run(
      '429 with Retry-After: 2',
      () => serverSaying([429], e, headers: {'retry-after': '2'}).get('/menu'),
      e,
    );
    expect(e[1], '  waiting 2000 ms');
  });
}
