import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'retry.dart';

typedef Sleep = Future<void> Function(Duration);

// عميل واحد للتطبيق كله: كل طلب يمر من _send.
class ApiClient {
  ApiClient(
    this.client, {
    required this.base,
    this.timeout = const Duration(seconds: 10),
    this.policy = const RetryPolicy(),
    Sleep? sleep,
    Random? random,
    this.log,
  }) : sleep = sleep ?? Future<void>.delayed,
       random = random ?? Random();

  final http.Client client;
  final String base;
  final Duration timeout;
  final RetryPolicy policy;
  // الانتظار يُعطى من الخارج، فلا تنتظر الاختبارات فعلاً.
  final Sleep sleep;
  final Random random;
  final void Function(String line)? log;

  // GET آمن التكرار. أما POST فبمفتاح عدم تكرار (idempotency key) فقط، يجعل الخادم يعرف التكرار.
  Future<Object?> get(String path) => _send('GET', path, retry: true);

  Future<Object?> post(String path, Object body, {String? idempotencyKey}) =>
      _send(
        'POST',
        path,
        body: body,
        headers: {'idempotency-key': ?idempotencyKey},
        retry: idempotencyKey != null,
      );

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
    required bool retry,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        final result = await _once(method, path, body, headers);
        log?.call('attempt $attempt: OK');
        return result;
      } on ApiError catch (e) {
        log?.call('attempt $attempt: ${describe(e)}');
        if (!retry || attempt >= policy.attempts || !retryable(e)) {
          rethrow;
        }
        // إن قال الخادم متى نعود، فصدّقه.
        final wait =
            (e is ServerError ? e.retryAfter : null) ??
            policy.delay(attempt - 1, random);
        log?.call('  waiting ${wait.inMilliseconds} ms');
        await sleep(wait);
      }
    }
  }

  Future<Object?> _once(
    String method,
    String path,
    Object? body,
    Map<String, String> headers,
  ) async {
    final request = http.Request(method, Uri.parse('$base$path'))
      ..headers.addAll({'accept': 'application/json', ...headers});
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      // عدم الإجابة في الوقت فشل أيضاً. والمهلة تغطي الطلب كله: الإرسال والانتظار والقراءة.
      response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const TimedOut();
    } on http.ClientException {
      throw const Offline();
    }
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.bodyBytes.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException catch (e) {
        throw BadResponse(e.message);
      }
    }
    // كل رمز حالة يصير الخطأ الذي يعنيه.
    throw switch (status) {
      401 => const Unauthorized(),
      404 => const NotFound(),
      429 || >= 500 => ServerError(status, retryAfter: _retryAfter(response)),
      _ => Rejected(status, _message(response)),
    };
  }

  static Duration? _retryAfter(http.Response r) {
    final seconds = int.tryParse(r.headers['retry-after'] ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static String _message(http.Response r) {
    try {
      return ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error']
              as String?) ??
          'HTTP ${r.statusCode}';
    } on Object {
      return 'HTTP ${r.statusCode}';
    }
  }
}
