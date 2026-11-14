import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';

/// [Sprint 66 F1] The errors the app meets on a player's phone, sent to our own server (POST /client-errors): the
/// platform, the app's version, the screen's path (the server drops its ids), the message and the first lines of the
/// trace. Its own client, without the account's token: nothing in a report names the player. The same error goes once
/// a minute at most, and twenty a session at most. The privacy policy says so («بيانات الأعطال»).
abstract final class CrashReports {
  static const oncePer = Duration(minutes: 1);
  static const maxPerSession = 20;

  /// The app's version (set once in main.dart, from the package).
  static String version = '0.0.0';

  /// The screen on show now (the router tells it, app.dart).
  static String path = '/';

  /// Off in the widget tests (no network there).
  static bool enabled = !kDebugMode;

  static final _sent = <String, DateTime>{};
  static var _count = 0;
  static Dio? _dio;

  /// Sends on this client instead (the tests).
  @visibleForTesting
  static set client(Dio dio) => _dio = dio;

  static String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Whether this error may go now: not sent in the last minute, and the session's allowance not spent.
  static bool shouldSend(String key, DateTime now) {
    if (_count >= maxPerSession) return false;
    final last = _sent[key];
    if (last != null && now.difference(last) < oncePer) return false;
    _sent[key] = now;
    return true;
  }

  /// The report for an error and its trace.
  static Map<String, Object> describe(Object error, StackTrace? stack) {
    final message = '${error.runtimeType}: $error';
    final lines = (stack?.toString() ?? '').split('\n').where((l) => l.trim().isNotEmpty).take(8).join('\n');
    return {
      'platform': platform,
      'version': version.length > 20 ? version.substring(0, 20) : version,
      'path': path.split(RegExp('[?#]')).first,
      'message': message.length > 1000 ? message.substring(0, 1000) : message,
      'stack': lines.length > 2000 ? lines.substring(0, 2000) : lines,
    };
  }

  /// Sends one error; never throws and never waits (a report must not break what is left of the app).
  static void report(Object error, StackTrace? stack) {
    if (!enabled || ignored(error)) return;
    final body = describe(error, stack);
    final first = (body['stack']! as String).split('\n').first;
    if (!shouldSend('${body['message']}\n$first', DateTime.now())) return;
    _count++;
    final dio = _dio ??= Dio(
      BaseOptions(baseUrl: AppConfig.apiUrl, connectTimeout: const Duration(seconds: 8), headers: {'Accept': 'application/json'}),
    );
    unawaited(dio.post<void>('/client-errors', data: body).then((_) {}, onError: (_) {}));
  }

  /// What says nothing about our code: the network gone, a request cancelled or timed out (a server's error answer, left
  /// uncaught, still goes).
  static bool ignored(Object error) => error is DioException && error.type != DioExceptionType.badResponse;

  @visibleForTesting
  static void reset() {
    _sent.clear();
    _count = 0;
    _dio = null;
  }
}
