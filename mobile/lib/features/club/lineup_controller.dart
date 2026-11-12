import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import 'team_data.dart';

/// A lineup as the coach is changing it: the formation, the eleven and the bench.
@immutable
class LineupDraft {
  const LineupDraft({required this.formation, required this.starters, required this.bench, this.busy = false});

  factory LineupDraft.of(Lineup l) => LineupDraft(formation: l.formation, starters: [...l.starters], bench: [...l.bench]);

  final String formation;
  final List<int> starters, bench;

  /// A save on its way.
  final bool busy;

  LineupDraft copy({String? formation, List<int>? starters, List<int>? bench, bool? busy}) => LineupDraft(
    formation: formation ?? this.formation,
    starters: starters ?? this.starters,
    bench: bench ?? this.bench,
    busy: busy ?? this.busy,
  );

  /// Whether it differs from the saved [l].
  bool changedFrom(Lineup l) => formation != l.formation || !listEquals(starters, l.starters) || !listEquals(bench, l.bench);
}

/// [Sprint 59 F5] The lineup being edited (null: untouched, the saved one shows). The screen draws it and sends the
/// coach's moves; the editor keeps the server's slot rule (Sprint 59 F6) and saves.
class LineupEditor extends Notifier<LineupDraft?> {
  LineupEditor(this.league);

  final int league;

  @override
  LineupDraft? build() => null;

  LineupDraft _from(Lineup saved) => state ?? LineupDraft.of(saved);

  void formation(String f, Lineup saved) => state = _from(saved).copy(formation: f);

  /// Two players swap ([a] picked first, [b] tapped), or a reserve comes in. False when it would break the slot rule of
  /// [slots] (a sheet already wrong on the server stays editable: only a move that breaks it is refused).
  bool swap(int a, int b, Lineup saved, List<Slot> slots, String? Function(int id) lineOf) {
    final d = _from(saved);
    final starters = [...d.starters], bench = [...d.bench];
    List<int>? where(int x) => starters.contains(x)
        ? starters
        : bench.contains(x)
        ? bench
        : null;
    final la = where(a), lb = where(b);
    if (la != null && lb != null) {
      final ia = la.indexOf(a), ib = lb.indexOf(b);
      la[ia] = b;
      lb[ib] = a;
    } else if (la != null) {
      la[la.indexOf(a)] = b;
    } else if (lb != null) {
      lb[lb.indexOf(b)] = a;
    }
    bool fits(List<int> eleven) {
      for (var i = 0; i < eleven.length && i < slots.length; i++) {
        if (!slots[i].takes(lineOf(eleven[i]))) return false;
      }
      return true;
    }

    if (!fits(starters) && fits(d.starters)) return false;
    state = d.copy(starters: starters, bench: bench);
    return true;
  }

  /// Saves the draft ([positions]: the ten outfield places) or, with [auto], lets the game pick; the error if refused.
  Future<ApiError?> save(Lineup saved, {bool auto = false, List<List<int>>? positions}) async {
    final d = _from(saved);
    if (d.busy) return null;
    state = d.copy(busy: true);
    final repo = ref.read(teamRepositoryProvider);
    try {
      final team = auto
          ? await repo.autoLineup(league)
          : await repo.saveLineup(league, d.formation, d.starters, d.bench, positions: positions);
      state = LineupDraft.of(team.lineup);
      ref.invalidate(teamProvider(league));
      return null;
    } on ApiError catch (e) {
      state = d;
      return e;
    }
  }
}

final lineupEditorProvider = NotifierProvider.autoDispose.family<LineupEditor, LineupDraft?, int>(LineupEditor.new);
