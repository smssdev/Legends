import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// [2026-11-09] One idempotency key per action the coach means (buy this player, build this section), kept until the
/// server says it is done. A tap again after a lost answer (a timeout, a dropped connection) sends the same key, so the
/// server does it once (it records a key only with the action done). The next deliberate action gets a new key.
///
/// [Sprint 59 F10] The pending keys are kept on the phone too (`glm.intents`), so a tap again after the app was closed
/// mid-request still sends the same key; a key left over a day is forgotten.
abstract final class Intents {
  static const storeKey = 'glm.intents';
  static const lifetime = Duration(days: 1);

  static final _random = Random.secure();
  static SharedPreferences? _store;

  /// The pending keys: the action → (its key, when it was first sent, ms since the epoch).
  static final _keys = <String, ({String key, int at})>{};

  static String _fresh() => 'app-${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

  /// Reads the keys left pending from the phone (main() calls it once), dropping those over a day old.
  static void load(SharedPreferences store, {DateTime? now}) {
    _store = store;
    _keys.clear();
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    try {
      final saved = jsonDecode(store.getString(storeKey) ?? '{}') as Map<String, dynamic>;
      saved.forEach((action, v) {
        final m = v as Map<String, dynamic>;
        final since = m['at'] as int? ?? 0;
        if (at - since < lifetime.inMilliseconds) _keys[action] = (key: '${m['key']}', at: since);
      });
    } on Object {
      // A broken entry is forgotten: the next action gets a new key.
    }
    _save();
  }

  static void _save() {
    final s = _store;
    if (s == null) return;
    if (_keys.isEmpty) {
      s.remove(storeKey).ignore();
      return;
    }
    s
        .setString(
          storeKey,
          jsonEncode({
            for (final e in _keys.entries) e.key: {'key': e.value.key, 'at': e.value.at},
          }),
        )
        .ignore();
  }

  /// The key pending for [action], if any (for the tests).
  static String? pending(String action) => _keys[action]?.key;

  /// Runs [call] with the key for [action] (a string naming it: what, where and with what), forgetting the key once it
  /// succeeds.
  static Future<T> run<T>(String action, Future<T> Function(String key) call, {DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final held = _keys[action];
    final key = held != null && at - held.at < lifetime.inMilliseconds ? held.key : _fresh();
    if (held?.key != key) {
      _keys[action] = (key: key, at: at);
      _save();
    }
    final result = await call(key);
    _keys.remove(action);
    _save();
    return result;
  }
}
