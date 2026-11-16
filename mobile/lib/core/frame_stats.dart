import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'config.dart';
import 'crash_reports.dart';
import 'device_tier.dart';

/// [Sprint 74 P2] How smoothly the app draws on this phone, counted per screen and sent to our own server when the
/// app is left (POST /client-frames): the frames drawn, how many took over 16 ms and over 33 ms, the app's version
/// and the phone's tier. Counts only, on its own client without the account's token: nothing names the player or the
/// phone (the privacy policy says so, «بيانات الأعطال»). It is what tells us which screen stutters on a weak phone.
abstract final class FrameStats {
  /// A screen with fewer frames than this (about a second) says nothing: left out.
  static const minFrames = 60;
  static const maxScreens = 20;

  /// Off in debug and in the widget tests (no network there, and a debug build's frames are not the app's).
  static bool enabled = !kDebugMode;

  static final _screens = <String, List<int>>{};
  static Dio? _dio;

  @visibleForTesting
  static set client(Dio dio) => _dio = dio;

  /// Counts one frame of [ms] in for the screen at [path] (its query dropped; the server drops its ids).
  static void add(String path, int ms) {
    final s = _screens.putIfAbsent(path.split(RegExp('[?#]')).first, () => [0, 0, 0]);
    s[0]++;
    if (ms > 16) s[1]++;
    if (ms > 33) s[2]++;
  }

  /// The report for what was counted so far, the busiest screens first; null when nothing is worth sending. Pure.
  static Map<String, Object>? describe({required String platform, required String version, required DeviceTier tier}) {
    final worth = _screens.entries.where((e) => e.value[0] >= minFrames).toList()..sort((a, b) => b.value[0].compareTo(a.value[0]));
    if (worth.isEmpty) return null;
    return {
      'platform': platform,
      'version': version.length > 20 ? version.substring(0, 20) : version,
      'tier': tier.name,
      'screens': [
        for (final e in worth.take(maxScreens)) {'path': e.key, 'frames': e.value[0], 'late16': e.value[1], 'late33': e.value[2]},
      ],
    };
  }

  /// Forgets what was counted (after it is sent; and between tests).
  static void clear() => _screens.clear();

  /// Sends what was counted and starts again; never throws and never waits.
  static void send() {
    if (!enabled) return;
    final body = describe(platform: CrashReports.platform, version: CrashReports.version, tier: DeviceTiers.now);
    if (body == null) return;
    clear();
    final dio = _dio ??= Dio(
      BaseOptions(baseUrl: AppConfig.apiUrl, connectTimeout: const Duration(seconds: 8), headers: {'Accept': 'application/json'}),
    );
    unawaited(dio.post<void>('/client-frames', data: body).then((_) {}, onError: (_) {}));
  }

  static AppLifecycleListener? _life;

  /// Whether the count is running (it starts once).
  static bool get started => _life != null;

  /// From the first frame: every frame counted for the screen on show (the router tells CrashReports.path), and the
  /// counts sent when the app goes to the background.
  static void start() {
    if (!enabled || started) return;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        add(CrashReports.path, t.totalSpan.inMilliseconds);
      }
    });
    _life = AppLifecycleListener(onPause: send);
  }
}
