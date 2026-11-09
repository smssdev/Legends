import 'dart:math';

/// [2026-11-09] One idempotency key per action the coach means (buy this player, build this section), kept until the
/// server says it is done. A tap again after a lost answer (a timeout, a dropped connection) sends the same key, so the
/// server does it once (it records a key only with the action done). The next deliberate action gets a new key.
abstract final class Intents {
  static final _keys = <String, String>{};
  static final _random = Random.secure();

  static String _fresh() => 'app-${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

  /// Runs [call] with the key for [action] (a string naming it: what, where and with what), forgetting the key once it
  /// succeeds.
  static Future<T> run<T>(String action, Future<T> Function(String key) call) async {
    final key = _keys.putIfAbsent(action, _fresh);
    final result = await call(key);
    _keys.remove(action);
    return result;
  }
}
