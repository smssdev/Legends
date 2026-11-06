import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../leagues/models.dart';

/// [Sprint 16, 17] The club's board (`/team/summary`): the money, the next match with both sides, the lineup's state, my
/// place in the table, the board's objective and what waits for me.
class ClubSummary {
  const ClubSummary({required this.club, required this.cash, required this.coins, this.next, this.venue, this.matchAt, this.lineupAuto = true,
      this.lineupReady = true, this.position, this.teams, this.goal, this.pending = const [], this.matchId, this.matchStatus, this.missed = 0,
      this.needs = const [], this.strength, this.top = const [], this.formation, this.timers = const [], this.round, this.form = const []});

  factory ClubSummary.fromJson(Map<String, dynamic> j) {
    final m = j['match'] as Map<String, dynamic>?;
    final lineup = j['lineup'] as Map<String, dynamic>? ?? const {};
    final standings = j['standings'] as Map<String, dynamic>? ?? const {};
    final board = j['board'] as Map<String, dynamic>?;
    return ClubSummary(
      club: Side.fromJson(j['club'] as Map<String, dynamic>?),
      cash: (j['money'] as Map?)?['cash'] as int? ?? 0, coins: (j['money'] as Map?)?['coins'] as int? ?? 0,
      next: m == null ? null : Side.fromJson(m['opponent'] as Map<String, dynamic>?), venue: m?['venue'] as String?, matchAt: date(m?['scheduled_at']),
      lineupAuto: lineup['auto'] != false, lineupReady: lineup['ready'] != false,
      position: standings['position'] as int?, teams: standings['teams'] as int?,
      goal: board == null ? null : (kind: '${board['kind']}', target: board['target'] as int? ?? 0),
      matchId: m?['match_id'] as int?, matchStatus: m?['status'] as String?, missed: j['missed'] as int? ?? 0,
      pending: [for (final p in (j['pending'] as List? ?? const [])) '${((p as Map)['lines'] as List?)?.join(' ') ?? p['kind']}'],
      needs: [
        for (final p in (j['pending'] as List? ?? const []))
          (kind: '${(p as Map)['kind']}', severity: '${p['severity'] ?? 'low'}', count: (p['count'] as num?)?.toInt() ?? (p['lines'] as List?)?.length ?? (p['players'] as List?)?.length ?? 0, matchId: (p['match_id'] as num?)?.toInt()),
      ],
      strength: m == null ? null : ((m['club'] as Map?)?['strength_cp'] as num?, (m['opponent'] as Map?)?['strength_cp'] as num?).let((s) => s.$1 == null || s.$2 == null ? null : (s.$1!.toInt(), s.$2!.toInt())),
      top: [
        for (final r in (standings['top'] as List? ?? const []))
          (position: (r as Map)['position'] as int? ?? 0, name: '${r['name']}', code: '${r['code'] ?? ''}', points: r['points'] as int? ?? 0, mine: r['mine'] == true),
      ],
      formation: lineup['formation'] as String?,
      round: m?['round'] as int?,
      form: [for (final f in ((m?['club'] as Map?)?['form'] as List? ?? const [])) '$f'],
      timers: [for (final t in (j['timers'] as List? ?? const [])) (kind: '${(t as Map)['kind']}', at: date(t['at']))],
    );
  }

  final Side club;
  final int cash, coins;
  final Side? next;
  final String? venue;
  final DateTime? matchAt;
  final bool lineupAuto, lineupReady;
  final int? position, teams;
  final ({String kind, int target})? goal;
  final List<String> pending;

  /// [Sprint 17 F2] The next match once it is under way: its id and status.
  final int? matchId;
  final String? matchStatus;

  /// [Sprint 20 B3] Played matches the coach has not seen yet.
  final int missed;

  /// [Sprint 45 M2] What needs the coach now (ClubAgenda): its kind, how urgent, how many, and the match when it is one.
  final List<({String kind, String severity, int count, int? matchId})> needs;

  /// Both sides' strength for the next match (mine, theirs), the table's top and my line in it, my formation, and the
  /// clocks running (the daily coins, the market's renewal, training, the stadium, the scout).
  final (int, int)? strength;
  final List<({int position, String name, String code, int points, bool mine})> top;
  final String? formation;
  final List<({String kind, DateTime? at})> timers;

  /// The next match's round, and my club's last results (W, D, L), newest last.
  final int? round;
  final List<String> form;
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

final clubSummaryProvider = FutureProvider.autoDispose.family<ClubSummary, int>(
    (ref, league) async => ClubSummary.fromJson(await ref.read(apiProvider).get('/leagues/$league/team/summary')));
