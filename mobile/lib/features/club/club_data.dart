import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../leagues/models.dart';

/// [Sprint 16, 17] The club's board (`/team/summary`): the money, the next match with both sides, the lineup's state, my
/// place in the table, the board's objective and what waits for me.
class ClubSummary {
  const ClubSummary({required this.club, required this.cash, required this.coins, this.next, this.venue, this.matchAt, this.lineupAuto = true,
      this.lineupReady = true, this.position, this.teams, this.goal, this.pending = const []});

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
      pending: [for (final p in (j['pending'] as List? ?? const [])) '${((p as Map)['lines'] as List?)?.join(' ') ?? p['kind']}'],
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
}

final clubSummaryProvider = FutureProvider.autoDispose.family<ClubSummary, int>(
    (ref, league) async => ClubSummary.fromJson(await ref.read(apiProvider).get('/leagues/$league/team/summary')));
