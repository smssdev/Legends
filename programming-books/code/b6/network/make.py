"""Writes the examples of Book 6, chapter "Networking, Errors and Retries", in English and Arabic: an API client
on package:http with typed errors, timeouts, retries with backoff and jitter, Retry-After and idempotency
keys. Tests use a fake sleep that records the waits; a real run against a flaky local server is recorded too.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium)
"""
import os
import signal
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery, popen  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_c_errors="Everything that can go wrong with a request, as types the screen can switch on.",
        w_c_policy="How many times to try, and how long to wait between tries.",
        w_c_jitter="Full jitter: a random wait between zero and the doubling limit, so that a thousand phones do not retry at the same moment.",
        w_c_retryable="Only failures that may pass: no connection, a timeout, an overloaded or restarting server.",
        w_c_client="One client for the whole app: every request goes through _send.",
        w_c_safe="GET is safe to repeat. POST only with an idempotency key, which lets the server recognise a repeat.",
        w_c_after="If the server says when to come back, believe it.",
        w_c_timeout="No answer in time is a failure too. The timeout covers the whole request: sending, waiting, and reading.",
        w_c_status="Each status becomes the error it means.",
        w_c_sleep="Waiting is given, so tests do not really wait.",
        w_c_nowait="The test does not really wait: the log shows what would have been waited.",
        w_menu="Menu", w_attempts="What happened", w_egp="EGP", w_try="Try again",
        w_latte="Latte", w_tea="Mint tea", w_cake="Cherry cake",
        w_c_flaky="A pretend server inside the app for this screen: busy twice, then it answers.",
        w_t_map="each status becomes its error",
        w_t_retry="retries wait longer each time, and only when it can help",
        w_t_timeout="a server that never answers becomes a TimedOut",
        w_t_messages="every error has words, in the language of the person",
        w_t_idem="with a key, a retried order is created once",
        w_t_refresh="three requests, one refresh",
        w_m_offline="No connection. Check your internet and try again.",
        w_m_timeout="The café is taking too long to answer. Try again in a moment.",
        w_m_auth="Please sign in again.",
        w_m_notfound="This was not found. It may have been removed.",
        w_m_busy="The café is very busy. Try again in a minute.",
        w_m_server="Something went wrong on our side. We are on it.",
        w_m_bad="The answer from the café could not be read. Please update the app.",
        w_c_words="The screen's words for each error: the switch must cover them all.",
        w_c_key="One key per order the person placed, not per attempt.",
        w_c_dedupe="The server keeps the keys it has seen, and answers a repeat with the first result.",
        w_c_lost="The order was saved, but the answer is lost on the way back.",
        w_c_single="One refresh at a time: the requests that arrive meanwhile wait for the same one.",
        w_c_auth_client="Adds the token to every request; on a 401, refreshes once and tries again.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_c_errors="كل ما قد يسوء في طلب، في صورة أنواع تستطيع الشاشة أن تعمل switch عليها.",
        w_c_policy="كم مرة نحاول، وكم ننتظر بين المحاولات.",
        w_c_jitter="عشوائية كاملة: انتظار عشوائي بين الصفر وحد يتضاعف، كي لا تعيد ألف جوال المحاولة في اللحظة نفسها.",
        w_c_retryable="فقط حالات الفشل التي قد تزول: لا اتصال، أو انتهاء المهلة، أو خادم مزدحم أو يُعاد تشغيله.",
        w_c_client="عميل واحد للتطبيق كله: كل طلب يمر من _send.",
        w_c_safe="GET آمن التكرار. أما POST فبمفتاح عدم تكرار (idempotency key) فقط، يجعل الخادم يعرف التكرار.",
        w_c_after="إن قال الخادم متى نعود، فصدّقه.",
        w_c_timeout="عدم الإجابة في الوقت فشل أيضاً. والمهلة تغطي الطلب كله: الإرسال والانتظار والقراءة.",
        w_c_status="كل رمز حالة يصير الخطأ الذي يعنيه.",
        w_c_sleep="الانتظار يُعطى من الخارج، فلا تنتظر الاختبارات فعلاً.",
        w_c_nowait="الاختبار لا ينتظر فعلاً: والسجل يعرض ما كان سيُنتظر.",
        w_menu="القائمة", w_attempts="ما الذي حدث", w_egp="جنيه", w_try="أعد المحاولة",
        w_latte="لاتيه", w_tea="شاي بالنعناع", w_cake="كيك الكرز",
        w_c_flaky="خادم متخيَّل داخل التطبيق لهذه الشاشة: مشغول مرتين، ثم يجيب.",
        w_t_map="كل رمز حالة يصير خطأه",
        w_t_retry="إعادة المحاولة تنتظر أطول في كل مرة، وفقط حين يفيد ذلك",
        w_t_timeout="الخادم الذي لا يجيب أبداً يصير TimedOut",
        w_t_messages="لكل خطأ كلمات، بلغة الشخص",
        w_t_idem="مع المفتاح، الطلب المعاد يُنشأ مرة واحدة",
        w_t_refresh="ثلاثة طلبات، وتجديد واحد",
        w_m_offline="لا اتصال. تحقق من الإنترنت وحاول من جديد.",
        w_m_timeout="المقهى يتأخر في الإجابة. حاول بعد لحظة.",
        w_m_auth="من فضلك سجّل الدخول من جديد.",
        w_m_notfound="لم يُعثر على هذا. ربما حُذف.",
        w_m_busy="المقهى مزدحم جداً. حاول بعد دقيقة.",
        w_m_server="حدث خطأ من جهتنا. ونحن نعمل عليه.",
        w_m_bad="تعذّرت قراءة إجابة المقهى. من فضلك حدّث التطبيق.",
        w_c_words="كلمات الشاشة لكل خطأ: ويجب أن يغطيها الـ switch كلها.",
        w_c_key="مفتاح واحد لكل طلب يرسله الشخص، لا لكل محاولة.",
        w_c_dedupe="الخادم يحفظ المفاتيح التي رآها، ويجيب التكرار بالنتيجة الأولى.",
        w_c_lost="حُفظ الطلب، لكن الإجابة ضاعت في طريق العودة.",
        w_c_single="تجديد واحد في كل مرة: والطلبات التي تصل في هذه الأثناء تنتظر التجديد نفسه.",
        w_c_auth_client="يضيف التوكن إلى كل طلب؛ ومع 401 يجدده مرة ويحاول من جديد.",
    ),
}

FILES = {
    "lib/api/errors.dart": """// {w_c_errors}
sealed class ApiError implements Exception {
  const ApiError();
}

final class Offline extends ApiError {
  const Offline();
}

final class TimedOut extends ApiError {
  const TimedOut();
}

final class Unauthorized extends ApiError {
  const Unauthorized();
}

final class NotFound extends ApiError {
  const NotFound();
}

/// The server refused the request (400, 409, 422…), with its reason.
final class Rejected extends ApiError {
  const Rejected(this.status, this.message);
  final int status;
  final String message;
}

/// 429 and 5xx: the server could not answer now.
final class ServerError extends ApiError {
  const ServerError(this.status, {this.retryAfter});
  final int status;
  final Duration? retryAfter;
}

final class BadResponse extends ApiError {
  const BadResponse(this.detail);
  final String detail;
}

String describe(ApiError e) => switch (e) {
  Offline() => 'Offline',
  TimedOut() => 'TimedOut',
  Unauthorized() => 'Unauthorized',
  NotFound() => 'NotFound',
  Rejected(:final status, :final message) => 'Rejected($status, $message)',
  ServerError(:final status) => 'ServerError($status)',
  BadResponse() => 'BadResponse',
};
""",
    "lib/api/retry.dart": """import 'dart:math';

import 'errors.dart';

// {w_c_policy}
class RetryPolicy {
  const RetryPolicy({this.attempts = 4, this.base = const Duration(milliseconds: 200), this.cap = const Duration(seconds: 5)});

  final int attempts;
  final Duration base;
  final Duration cap;

  // {w_c_jitter}
  Duration delay(int retry, Random random) {
    final limit = min(cap.inMilliseconds, base.inMilliseconds * pow(2, retry).toInt());
    return Duration(milliseconds: random.nextInt(limit + 1));
  }
}

// {w_c_retryable}
bool retryable(ApiError e) => switch (e) {
  Offline() || TimedOut() => true,
  ServerError(:final status) => status == 429 || status == 502 || status == 503 || status == 504,
  _ => false,
};
""",
    "lib/api/client.dart": """import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'retry.dart';

typedef Sleep = Future<void> Function(Duration);

// {w_c_client}
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
  // {w_c_sleep}
  final Sleep sleep;
  final Random random;
  final void Function(String line)? log;

  // {w_c_safe}
  Future<Object?> get(String path) => _send('GET', path, retry: true);

  Future<Object?> post(String path, Object body, {String? idempotencyKey}) => _send(
    'POST',
    path,
    body: body,
    headers: {'idempotency-key': ?idempotencyKey},
    retry: idempotencyKey != null,
  );

  Future<Object?> _send(String method, String path, {Object? body, Map<String, String> headers = const {}, required bool retry}) async {
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
        // {w_c_after}
        final wait = (e is ServerError ? e.retryAfter : null) ?? policy.delay(attempt - 1, random);
        log?.call('  waiting ${wait.inMilliseconds} ms');
        await sleep(wait);
      }
    }
  }

  Future<Object?> _once(String method, String path, Object? body, Map<String, String> headers) async {
    final request = http.Request(method, Uri.parse('$base$path'))..headers.addAll({'accept': 'application/json', ...headers});
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      // {w_c_timeout}
      response = await client.send(request).then(http.Response.fromStream).timeout(timeout);
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
    // {w_c_status}
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
      return ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['error'] as String?) ?? 'HTTP ${r.statusCode}';
    } on Object {
      return 'HTTP ${r.statusCode}';
    }
  }
}
""",
    "lib/api/messages.dart": """import 'errors.dart';

// {w_c_words}
String message(ApiError e) => switch (e) {
  Offline() => '{w_m_offline}',
  TimedOut() => '{w_m_timeout}',
  Unauthorized() => '{w_m_auth}',
  NotFound() => '{w_m_notfound}',
  Rejected(:final message) => message,
  ServerError(status: 429 || 503) => '{w_m_busy}',
  ServerError() => '{w_m_server}',
  BadResponse() => '{w_m_bad}',
};
""",
    "lib/menu_app.dart": """import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'api/client.dart';
import 'api/errors.dart';
import 'api/messages.dart';

// {w_c_flaky}
var calls = 0;
final flaky = MockClient((request) async {
  await Future<void>.delayed(const Duration(milliseconds: 150));
  if (++calls <= 2) {
    return http.Response('{"error": "busy"}', 503);
  }
  return http.Response(
    jsonEncode([
      {'name': '{w_latte}', 'price': 45},
      {'name': '{w_tea}', 'price': 25},
      {'name': '{w_cake}', 'price': 60},
    ]),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const MenuPage(),
    ),
  );
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final lines = <String>[];
  late final api = ApiClient(flaky, base: 'https://cafe.example', random: Random(7), log: (l) => setState(() => lines.add(l)));
  List<Object?>? menu;
  ApiError? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await api.get('/menu') as List<Object?>;
      setState(() => menu = result);
    } on ApiError catch (e) {
      setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (menu case final items?)
            for (final item in items.cast<Map<String, Object?>>())
              ListTile(title: Text('${item['name']}'), trailing: Text('${item['price']} {w_egp}')),
          if (error != null) ListTile(leading: const Icon(Icons.cloud_off), title: Text(message(error))),
          if (menu == null && error == null) const LinearProgressIndicator(),
          const Divider(height: 32),
          Text('{w_attempts}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in lines) Text(line, textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
""",
    "root/bin/flaky_server.dart": """import 'dart:convert';
import 'dart:io';

// A café server that is overloaded two times out of three, and slow on /slow.
Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8091);
  var menuCalls = 0;
  // Each request is handled on its own: a slow one must not hold up the others.
  server.listen((request) async {
    final response = request.response..headers.contentType = ContentType.json;
    switch (request.uri.path) {
      case '/menu' when ++menuCalls % 3 != 0:
        response
          ..statusCode = 503
          ..write('{"error": "busy"}');
      case '/menu':
        response.write(jsonEncode([
          {'name': 'Latte', 'price': 45},
        ]));
      case '/slow':
        await Future<void>.delayed(const Duration(seconds: 3));
        response.write('[]');
      case '/busy':
        response
          ..statusCode = 429
          ..headers.set('retry-after', '1')
          ..write('{"error": "slow down"}');
      default:
        response
          ..statusCode = 404
          ..write('{"error": "not found"}');
    }
    await response.close();
  });
}
""",
    "root/bin/demo.dart": """import 'dart:io';
import 'dart:math';

import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final watch = Stopwatch()..start();
  void log(String line) => stdout.writeln('${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s  $line');
  final api = ApiClient(
    http.Client(),
    base: 'http://localhost:8091',
    timeout: const Duration(seconds: 1),
    random: Random(1),
    log: log,
  );
  for (final path in ['/menu', '/slow', '/busy', '/missing']) {
    stdout.writeln('GET $path');
    watch.reset();
    try {
      stdout.writeln('  -> ${await api.get(path)}');
    } on ApiError catch (e) {
      stdout.writeln('  -> ${describe(e)}');
    }
  }
  api.client.close();
}
""",
    "test/map_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/retry.dart';

void main() {
  test('{w_t_map}', () async {
    final answers = <int, String>{200: '{"ok": true}', 201: 'not json', 401: '', 404: '', 409: '{"error": "Sold out"}', 500: '', 503: ''};
    for (final MapEntry(key: status, value: body) in answers.entries) {
      final api = ApiClient(MockClient((r) async => http.Response(body, status)), base: '', policy: const RetryPolicy(attempts: 1));
      try {
        debugPrint('$status -> ${await api.get('/x')}');
      } on ApiError catch (e) {
        debugPrint('$status -> ${describe(e)}');
      }
    }
    final offline = ApiClient(MockClient((r) => throw http.ClientException('connection refused')), base: '', policy: const RetryPolicy(attempts: 1));
    expect(() => offline.get('/x'), throwsA(isA<Offline>()));
  });
}
""",
    "test/retry_test.dart": """import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';

/// A server that answers with these statuses, in order, then 200.
ApiClient serverSaying(List<int> statuses, List<String> log, {Map<String, String> headers = const {}}) {
  var i = 0;
  return ApiClient(
    MockClient((r) async => http.Response('{}', i < statuses.length ? statuses[i++] : 200, headers: headers)),
    base: '',
    random: Random(1),
    // {w_c_nowait}
    sleep: (d) async {},
    log: log.add,
  );
}

Future<void> run(String title, Future<Object?> Function() request, List<String> log) async {
  try {
    await request();
  } on ApiError {
    // The log says what happened.
  }
  debugPrint([title, ...log].join('\\n'));
}

void main() {
  test('{w_t_retry}', () async {
    final a = <String>[];
    await run('GET, busy three times:', () => serverSaying([503, 503, 503], a).get('/menu'), a);
    expect(a.last, 'attempt 4: OK');

    final b = <String>[];
    await run('GET, a bug on the server:', () => serverSaying([500], b).get('/menu'), b);
    final c = <String>[];
    await run('POST without a key:', () => serverSaying([503], c).post('/orders', {}), c);
    final d = <String>[];
    await run('POST with a key:', () => serverSaying([503], d).post('/orders', {}, idempotencyKey: 'k1'), d);
    final e = <String>[];
    await run('429 with Retry-After: 2', () => serverSaying([429], e, headers: {'retry-after': '2'}).get('/menu'), e);
    expect(e[1], '  waiting 2000 ms');
  });
}
""",
    "test/timeout_test.dart": """import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/retry.dart';

void main() {
  test('{w_t_timeout}', () async {
    final never = MockClient((r) => Completer<http.Response>().future);
    final api = ApiClient(never, base: '', timeout: const Duration(milliseconds: 50), policy: const RetryPolicy(attempts: 1));
    final watch = Stopwatch()..start();
    await expectLater(api.get('/menu'), throwsA(isA<TimedOut>()));
    expect(watch.elapsedMilliseconds, lessThan(1000));
  });
}
""",
    # Projects
    "test/messages_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/api/errors.dart';
import 'package:bit_app/api/messages.dart';

void main() {
  test('{w_t_messages}', () {
    expect(message(const Offline()), '{w_m_offline}');
    expect(message(const ServerError(503)), '{w_m_busy}');
    expect(message(const ServerError(500)), '{w_m_server}');
    expect(message(const Rejected(409, 'Sold out')), 'Sold out');
  });
}
""",
    "test/idempotency_test.dart": """import 'dart:convert';

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
    // {w_c_dedupe}
    final id = (key != null ? seen[key] : null) ?? (orders..add(orders.length + 1)).last;
    if (key != null) {
      seen[key] = id;
    }
    if (!lost) {
      lost = true;
      // {w_c_lost}
      throw http.ClientException('connection reset');
    }
    return http.Response(jsonEncode({'id': id}), 201);
  });
}

void main() {
  test('{w_t_idem}', () async {
    final withKey = Server();
    final api = ApiClient(withKey.client, base: '', sleep: (_) async {});
    // {w_c_key}
    final placed = await api.post('/orders', {'latte': 1}, idempotencyKey: 'order-7f3a');
    debugPrint('with a key: answer $placed, orders on the server: ${withKey.orders}');
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
    debugPrint('without a key, tapped twice: orders on the server: ${noKey.orders}');
  });
}
""",
    "lib/api/auth_client.dart": """import 'dart:async';

import 'package:http/http.dart' as http;

// {w_c_auth_client}
class AuthClient extends http.BaseClient {
  AuthClient(this.inner, this._token, {required this.refresh});

  final http.Client inner;
  final Future<String> Function() refresh;
  String _token;
  Future<String>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner.send(_withToken(request, _token));
    if (response.statusCode != 401) {
      return response;
    }
    // {w_c_single}
    final sentWith = _token;
    _refreshing ??= refresh().whenComplete(() => _refreshing = null);
    _token = sentWith == _token ? await _refreshing! : _token;
    return inner.send(_withToken(request, _token));
  }

  http.BaseRequest _withToken(http.BaseRequest original, String token) {
    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..headers['authorization'] = 'Bearer $token';
    if (original is http.Request) {
      copy.bodyBytes = original.bodyBytes;
    }
    return copy;
  }
}
""",
    "test/refresh_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/api/auth_client.dart';

void main() {
  test('{w_t_refresh}', () async {
    var refreshes = 0;
    final server = MockClient((request) async {
      final ok = request.headers['authorization'] == 'Bearer fresh';
      return http.Response(ok ? '{}' : '', ok ? 200 : 401);
    });
    final client = AuthClient(
      server,
      'expired',
      refresh: () async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'fresh';
      },
    );
    final answers = await Future.wait([for (final p in ['/a', '/b', '/c']) client.get(Uri.parse('https://cafe.example$p'))]);
    expect([for (final r in answers) r.statusCode], [200, 200, 200]);
    expect(refreshes, 1);
  });
}
""",
}

SHOTS = [("retries.png", "lib/menu_app.dart", "wait=3000")]

TESTS = [
    ("map-test.sh", "test/map_test.dart"),
    ("retry-test.sh", "test/retry_test.dart"),
    ("timeout-test.sh", "test/timeout_test.dart"),
    ("projects/messages-test.sh", "test/messages_test.dart"),
    ("projects/idempotency-test.sh", "test/idempotency_test.dart"),
    ("projects/refresh-test.sh", "test/refresh_test.dart"),
]


def real_run(lang):
    """The demo against the flaky server, both really running on this machine."""
    project = WORK / HERE.name / lang / "bit_app"
    server = popen("dart run bin/flaky_server.dart", project, start_new_session=True)
    try:
        time.sleep(8)
        s = Session(project)
        s.run("dart run bin/demo.dart")
        s.save(HERE / lang / "demo.sh")
    finally:
        os.killpg(server.pid, signal.SIGTERM)


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["http"])
    for lang in T:
        real_run(lang)


def demo_only():
    """Runs only the real demo again, with the server file as it is in FILES."""
    from kit import fill, sh
    for lang, words in T.items():
        text = fill(FILES["root/bin/flaky_server.dart"], words)
        for folder in (WORK / HERE.name / lang / "bit_app" / "bin", HERE / lang / "bin"):
            (folder / "flaky_server.dart").write_text(text)
        sh("dart format bin", WORK / HERE.name / lang / "bit_app")
        (HERE / lang / "bin" / "flaky_server.dart").write_text((WORK / HERE.name / lang / "bit_app" / "bin" / "flaky_server.dart").read_text())
        real_run(lang)


if __name__ == "__main__":
    demo_only() if sys.argv[1:] == ["demo"] else main()
