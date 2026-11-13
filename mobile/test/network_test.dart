import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/api/api_client.dart';
import 'package:glm/core/api/api_error.dart';
import 'package:glm/core/api/response_cache.dart';
import 'package:glm/core/storage/token_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glm/features/health/offline_bar.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/theme.dart';

/// A server that answers from a script: each request takes the next answer (a status and a body, or no network).
class _Script implements HttpClientAdapter {
  _Script(this.answers);

  final List<(int, Object)?> answers;
  final List<String> asked = [];

  /// Held answers wait for this (a request still on its way when its screen goes).
  Completer<void>? hold;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    asked.add('${options.method} ${options.path}');
    if (hold != null) {
      await Future.any([hold!.future, ?cancelFuture]);
      if (options.cancelToken?.isCancelled ?? false) {
        throw DioException(requestOptions: options, type: DioExceptionType.cancel);
      }
    }
    final a = answers.isEmpty ? (200, <String, dynamic>{}) : answers.removeAt(0);
    if (a == null) throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    return ResponseBody.fromString(
      jsonEncode(a.$2),
      a.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  final links = <bool>[];

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('answers');
    links.clear();
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  ApiClient client(_Script server, {ResponseCache? cache}) => ApiClient(
    TokenStore(),
    language: 'ar',
    dio: Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = server,
    onLink: links.add,
    cache: cache,
    retryDelays: const [Duration(milliseconds: 10), Duration(milliseconds: 30)],
  );

  test('[Sprint 61 F8] a GET is asked again after no network or a server error, never after a refusal', () async {
    final server = _Script([
      null,
      (503, {'message': 'busy'}),
      (200, {'ok': true}),
    ]);
    expect(await client(server).get('/home'), {'ok': true});
    expect(server.asked, hasLength(3));
    expect(links, [false, true, true], reason: 'the frame told of the lost network, then of its return');

    final refused = _Script([
      (422, {'message': 'لا'}),
    ]);
    await expectLater(client(refused).get('/home'), throwsA(isA<ApiError>().having((e) => e.status, 'status', 422)));
    expect(refused.asked, hasLength(1));

    final down = _Script([null, null, null]);
    await expectLater(client(down).get('/home'), throwsA(isA<ApiError>().having((e) => e.offline, 'offline', isTrue)));
    expect(down.asked, hasLength(3), reason: 'two tries more, then the failure');
  });

  test('[Sprint 61 F8] a request stopped with its screen is not asked again and says nothing of the network', () async {
    final server = _Script([
      (200, {'late': true}),
    ])..hold = Completer<void>();
    final cancel = CancelToken();
    final asked = client(server).get('/leagues/8/team', cancel: cancel);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    cancel.cancel();
    await expectLater(asked, throwsA(isA<ApiError>()));
    expect(server.asked, hasLength(1));
    expect(links, isEmpty);
  });

  test('[Sprint 61 F7] the saved answer at once, the server\'s behind it, and the screen told only when it differs', () async {
    final cache = ResponseCache(dir: () async => dir);
    final server = _Script([
      (200, {'cash': 1}),
      (200, {'cash': 1}),
      (200, {'cash': 2}),
    ]);
    final api = client(server, cache: cache);
    var newer = 0;

    // First time: nothing saved, the server's answer (and it is kept).
    expect(await api.getSaved('/home', onNewer: () => newer++), {'cash': 1});
    // Again: the saved one at once; the server says the same, so no rebuild.
    expect(await api.getSaved('/home', onNewer: () => newer++), {'cash': 1});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(newer, 0);
    // Again: the saved one at once; the server's differs, so the screen rebuilds, and reads the newer one.
    expect(await api.getSaved('/home', onNewer: () => newer++), {'cash': 1});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(newer, 1);
    expect(await api.getSaved('/home', onNewer: () => newer++), {'cash': 2});
    expect(server.asked, hasLength(3), reason: 'the rebuild reads what was just fetched, without asking again');

    // No network: the saved answer stays, and nothing breaks.
    final offline = client(_Script([null, null, null]), cache: cache);
    expect(await offline.getSaved('/home', onNewer: () => newer++), {'cash': 2});
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(newer, 1);
    expect(links.last, isFalse);

    // Signed out: forgotten.
    await cache.clear();
    expect(await cache.read(ResponseCache.keyOf('/home', null, 'ar')), isNull);
  });

  test('[Sprint 61 F7] one file a path, its query and language', () {
    final a = ResponseCache.keyOf('/leagues/8/market', {'line': 'gk', 'q': 'x'}, 'ar');
    expect(ResponseCache.keyOf('/leagues/8/market', {'q': 'x', 'line': 'gk'}, 'ar'), a, reason: 'the query in any order');
    expect(ResponseCache.keyOf('/leagues/8/market', {'line': 'gk', 'q': 'x'}, 'en'), isNot(a));
    expect(ResponseCache.keyOf('/leagues/8/market', {'line': 'df', 'q': 'x'}, 'ar'), isNot(a));
    expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
  });

  testWidgets('[Sprint 61 F9] one bar above the frame while offline, gone at the return, and the screens told', (t) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: glmTheme(day: false),
          locale: const Locale('ar'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => OfflineBar(child: child!),
          home: const Scaffold(body: Text('الشاشة')),
        ),
      ),
    );
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    container.read(onlineProvider.notifier).set(false);
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('الشاشة'), findsOneWidget, reason: 'the screen stays under the bar');
    final before = container.read(reconnectedProvider);
    container.read(onlineProvider.notifier).set(true);
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    expect(container.read(reconnectedProvider), before + 1);
    await t.pumpWidget(const SizedBox());
  });
}
