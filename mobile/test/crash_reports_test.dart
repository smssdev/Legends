import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glm/core/crash_reports.dart';
import 'package:glm/l10n/app_localizations.dart';
import 'package:glm/ui/widgets/broken_part.dart';

/// Answers 204 to everything and keeps what was sent.
class _Recorder implements HttpClientAdapter {
  final sent = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    sent.add(options);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Recorder recorder;

  setUp(() {
    CrashReports.reset();
    CrashReports.enabled = true;
    CrashReports.version = '1.4.0';
    CrashReports.path = '/leagues/12/lineup?x=1';
    recorder = _Recorder();
    CrashReports.client = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))..httpClientAdapter = recorder;
  });
  tearDown(() => CrashReports.enabled = false);

  // [Sprint 66 F1] What a report carries, and no token: the client is the reports' own.
  test('a report says the platform, version, path without query, message and trace, and nothing else', () async {
    CrashReports.report(StateError('Bad state'), StackTrace.fromString('#0 main (lib/main.dart:1)\n#1 run'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(recorder.sent, hasLength(1));
    final r = recorder.sent.single;
    expect(r.path, '/client-errors');
    expect(r.headers.containsKey('Authorization'), isFalse);
    final body = r.data as Map<String, Object>;
    expect(body.keys.toSet(), {'platform', 'version', 'path', 'message', 'stack'});
    expect(body['version'], '1.4.0');
    expect(body['path'], '/leagues/12/lineup');
    expect(body['message'], 'StateError: Bad state: Bad state');
    expect(jsonEncode(body), contains('lib/main.dart:1'));
  });

  test('the same error once a minute, twenty a session at most', () async {
    for (var i = 0; i < 3; i++) {
      CrashReports.report(StateError('same'), null);
    }
    for (var i = 0; i < 30; i++) {
      CrashReports.report(StateError('e$i'), null);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(recorder.sent, hasLength(20));
    final now = DateTime(2026, 11, 15, 10);
    CrashReports.reset();
    expect(CrashReports.shouldSend('k', now), isTrue);
    expect(CrashReports.shouldSend('k', now.add(const Duration(seconds: 59))), isFalse);
    expect(CrashReports.shouldSend('k', now.add(const Duration(minutes: 1))), isTrue);
  });

  test('the network gone is not our error; a server error left uncaught is', () {
    final o = RequestOptions(path: '/x');
    expect(CrashReports.ignored(DioException(requestOptions: o, type: DioExceptionType.connectionError)), isTrue);
    expect(CrashReports.ignored(DioException(requestOptions: o, type: DioExceptionType.cancel)), isTrue);
    expect(CrashReports.ignored(DioException(requestOptions: o, type: DioExceptionType.badResponse)), isFalse);
    expect(CrashReports.ignored(StateError('x')), isFalse);
  });

  testWidgets('a part that failed shows one calm line in the player\'s language', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: L.localizationsDelegates,
        home: BrokenPart(),
      ),
    );
    expect(find.textContaining('تعذّر عرض هذا الجزء'), findsOneWidget);
  });
}
