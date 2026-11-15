import 'dart:io' show Platform;

import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/widgets/motion.dart';

/// [Sprint 74 P3] How much this phone can draw, as the site's three tiers (web/src/match/perf.ts): a first guess from
/// its processor, then corrected by what it really does (the frames it draws late). A `low` phone gets the game
/// without its endless motion (the sheen on the gold button, the pulses, the live dot's ripple): the screens are the
/// same, only stiller. The coach can ask for it himself (the settings' «حركة أقل»). Drawing only: no rule of the game.
enum DeviceTier { low, mid, high }

abstract final class DeviceTiers {
  static const _key = 'glm.tier';
  static const _lite = 'glm.motion.lite';

  /// The tier in force; `mid` until [start].
  static DeviceTier now = DeviceTier.mid;

  /// The first guess from the processor's cores. Pure.
  static DeviceTier guess(int cores) => cores <= 4 ? DeviceTier.low : (cores <= 6 ? DeviceTier.mid : DeviceTier.high);

  /// The tier after watching [frames] of which [late] took over 33 ms (two frames' time): a phone that draws more than
  /// 15% of them late goes down a tier; none goes up (a quiet screen proves nothing). Under 300 frames: no verdict. Pure.
  static DeviceTier judged(DeviceTier from, {required int frames, required int late}) {
    if (frames < 300 || late * 100 <= frames * 15) return from;
    return from == DeviceTier.high ? DeviceTier.mid : DeviceTier.low;
  }

  /// Whether the endless motion is off: the phone is `low`, or the coach asked. Pure.
  static bool liteFor(DeviceTier tier, {required bool asked}) => asked || tier == DeviceTier.low;

  /// At launch: the tier kept from the last run (or the guess), the coach's own choice, and the watch on the frames.
  static void start(SharedPreferences prefs) {
    now = DeviceTier.values.asNameMap()[prefs.getString(_key)] ?? guess(Platform.numberOfProcessors);
    Ambient.lite = liteFor(now, asked: prefs.getBool(_lite) ?? false);
    var frames = 0, late = 0;
    void watch(List<FrameTiming> timings) {
      for (final t in timings) {
        frames++;
        if (t.totalSpan.inMilliseconds > 33) late++;
      }
      if (frames < 300) return;
      final next = judged(now, frames: frames, late: late);
      frames = 0;
      late = 0;
      if (next == now) return;
      now = next;
      prefs.setString(_key, next.name);
      Ambient.lite = liteFor(now, asked: prefs.getBool(_lite) ?? false);
    }

    SchedulerBinding.instance.addTimingsCallback(watch);
  }

  /// The coach's own choice (the settings), kept on the phone.
  static bool asked(SharedPreferences prefs) => prefs.getBool(_lite) ?? false;

  static Future<void> ask(SharedPreferences prefs, bool lite) async {
    await prefs.setBool(_lite, lite);
    Ambient.lite = liteFor(now, asked: lite);
  }
}
