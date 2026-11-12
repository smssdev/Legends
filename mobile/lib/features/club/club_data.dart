import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../leagues/models.dart';

/// [Sprint 16, 17] The club's board (`/team/summary`): the money, the next match with both sides, the lineup's state, my
/// place in the table, the board's objective and what waits for me.
class ClubSummary {
  const ClubSummary({
    required this.club,
    required this.cash,
    required this.coins,
    this.next,
    this.venue,
    this.matchAt,
    this.lineupAuto = true,
    this.lineupReady = true,
    this.position,
    this.teams,
    this.goal,
    this.pending = const [],
    this.matchId,
    this.matchStatus,
    this.missed = 0,
    this.needs = const [],
    this.strength,
    this.top = const [],
    this.formation,
    this.timers = const [],
    this.round,
    this.form = const [],
  });

  /// [Sprint 59 F1] The club's board (`ClubBoard`), read through its generated model.
  factory ClubSummary.fromJson(Object? json) {
    final v = api.ClubBoard.fromJson(json);
    final m = v.match;
    return ClubSummary(
      club: Side(id: v.club.id, name: v.club.name, code: v.club.code, crestUrl: v.club.crestUrl),
      cash: v.money.cash,
      coins: v.money.coins,
      next: m == null ? null : Side(id: m.opponent.id, name: m.opponent.name, code: m.opponent.code, crestUrl: m.opponent.crestUrl),
      venue: m?.venue,
      matchAt: date(m?.scheduledAt),
      lineupAuto: v.lineup.auto,
      lineupReady: v.lineup.ready,
      position: v.standings.position,
      teams: v.standings.teams,
      goal: v.board == null ? null : (kind: v.board!.kind, target: v.board!.target),
      matchId: m?.matchId,
      matchStatus: m?.status,
      missed: v.missed,
      pending: [for (final p in v.pending) p.lines?.join(' ') ?? p.kind],
      needs: [
        for (final p in v.pending)
          (kind: p.kind, severity: p.severity, count: p.count ?? p.lines?.length ?? p.players?.length ?? 0, matchId: p.matchId),
      ],
      strength: m == null ? null : (m.club.strengthCp, m.opponent.strengthCp),
      top: [for (final r in v.standings.top) (position: r.position, name: r.name, code: r.code, points: r.points, mine: r.mine)],
      formation: v.lineup.formation,
      round: m?.round,
      form: m?.club.form ?? const [],
      timers: [for (final t in v.timers) (kind: t.kind, at: date(t.at))],
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

final clubSummaryProvider = FutureProvider.autoDispose.family<ClubSummary, int>(
  (ref, league) async => ClubSummary.fromJson(await ref.read(apiProvider).get('/leagues/$league/team/summary')),
);
