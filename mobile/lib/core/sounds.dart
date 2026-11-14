import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../ui/widgets/motion.dart';

/// [2026-11-06] The game's own sounds (tool/sounds/make_sounds.py, synthesized: no recording, no licence): the intro
/// at the start, a soft stud on turf under each button, a chime for a success, a double ding for coins, a low knock
/// for an error, and the referee's whistle for a match;
/// and in the live clips (Sprint 44 C2) the boot on the ball, the crowd's roar at a goal and its groan at a miss. Off from the settings; silent in the widget tests.
enum Sfx { intro, tap, confirm, coin, error, whistle, kick, roar, ooh }

abstract final class GameSounds {
  /// The coach's choice (settings), kept in step by the app.
  static bool enabled = true;

  /// [Sprint 63 G13] The two levels (settings), 0 to 100: the interface's sounds, and the stadium's (the whistle, the
  /// ball, the crowd).
  static int ui = 80, stadium = 80;

  /// [Sprint 64 F13] The buttons' buzz and tap (settings), kept in step by the app.
  static bool touch = true;

  static bool _isStadium(Sfx s) => s == Sfx.whistle || s == Sfx.kick || s == Sfx.roar || s == Sfx.ooh;
  static final Map<Sfx, AudioPlayer> _players = {};

  /// A new player that stops at the end of its sound (set once, not awaited: it only applies to the next play).
  static AudioPlayer _stopped(AudioPlayer p) {
    unawaited(p.setReleaseMode(ReleaseMode.stop));
    return p;
  }

  static Future<void> play(Sfx s) async {
    final level = (_isStadium(s) ? stadium : ui) / 100;
    if (!enabled || !Ambient.on || level <= 0) return;
    try {
      final p = _players[s] ??= _stopped(AudioPlayer());
      // Short sounds in the low-latency mode; the intro in the media mode (it is longer).
      if (s != Sfx.intro && s != Sfx.roar) await p.setPlayerMode(PlayerMode.lowLatency);
      await p.stop();
      await p.play(AssetSource('sounds/${s.name}.ogg'), volume: (s == Sfx.tap ? .55 : .9) * level);
    } catch (e) {
      // A sound is never worth an error.
      debugPrint('sound ${s.name}: $e');
    }
  }
}
