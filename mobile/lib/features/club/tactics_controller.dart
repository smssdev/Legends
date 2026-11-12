import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import 'team_data.dart';

/// [Sprint 59 F5] The tactics being edited: each change shows at once and goes to the server together with the others
/// made within [delay]; a change still unsaved when the screen closes is sent on the way out. A refused save gives its
/// error and drops the edit (the screen reloads what the server has). The screen draws [state] and calls the actions.
class TacticsEditor extends Notifier<Tactics?> {
  TacticsEditor(this.league);

  final int league;
  static const delay = Duration(milliseconds: 700);

  final Map<String, Object> _pending = {};
  Timer? _timer;
  late TeamRepository _repo;

  @override
  Tactics? build() {
    _repo = ref.read(teamRepositoryProvider);
    ref.onDispose(() {
      _timer?.cancel();
      if (_pending.isNotEmpty) unawaited(_repo.saveTactics(league, Map.of(_pending)).then((_) {}, onError: (_) {}));
    });
    return null;
  }

  /// Told when a save the timer sent is refused (the screen shows it).
  void Function(ApiError error)? onError;

  /// Whether a change waits to be sent.
  bool get pending => _pending.isNotEmpty;

  /// A change to [from] (the tactics on the screen: the edit so far, or the server's).
  void set(String key, Object value, Tactics from) {
    state = (state ?? from).set(key, value);
    _pending[key] = value;
    _timer?.cancel();
    _timer = Timer(
      delay,
      () => unawaited(
        flush().then((e) {
          if (e != null) onError?.call(e);
        }),
      ),
    );
  }

  /// Sends the changes made so far; the error, if the server refused them (the edit is dropped then).
  Future<ApiError?> flush() async {
    _timer?.cancel();
    if (_pending.isEmpty) return null;
    final changes = Map.of(_pending);
    _pending.clear();
    try {
      await _repo.saveTactics(league, changes);
      return null;
    } on ApiError catch (e) {
      state = null;
      ref.invalidate(tacticsProvider(league));
      return e;
    }
  }

  /// [Sprint 50 M12] A ready philosophy: the server sets its keys, and the editor takes what it answers.
  Future<ApiError?> preset(String preset) async {
    final failed = await flush();
    if (failed != null) return failed;
    try {
      state = await _repo.saveTactics(league, {'preset': preset});
      return null;
    } on ApiError catch (e) {
      return e;
    }
  }
}

final tacticsEditorProvider = NotifierProvider.autoDispose.family<TacticsEditor, Tactics?, int>(TacticsEditor.new);
