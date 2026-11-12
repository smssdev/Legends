import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';
import 'frames.dart';

part 'match_event.dart';
part 'match_report.dart';

/// [Sprint 17 F2] A league match as the server gives it (`GET /matches/{id}`, the simulator's shape): the clubs, both
/// teams (the tactics only for your own side, `you`), and the minute's length. The app only draws it.
class MatchClub {
  const MatchClub({required this.id, required this.name, required this.code, this.primary, this.secondary, this.logo, this.awayKit});

  factory MatchClub.fromJson(Map<String, dynamic>? j) => MatchClub(
    id: j?['id'] as int? ?? 0,
    name: '${j?['name'] ?? ''}',
    code: '${j?['code'] ?? ''}',
    primary: j?['primary'] as String?,
    secondary: j?['secondary'] as String?,
    logo: j?['logo'] as String?,
    awayKit: (j?['away_kit'] as Map<dynamic, dynamic>?)?['color'] as String?,
  );

  final int id;
  final String name, code;
  final String? primary, secondary, logo;

  /// [Sprint 34 V1] Its change kit's colour, worn on a clash.
  final String? awayKit;
}

class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.name,
    required this.no,
    required this.pos,
    required this.line,
    required this.on,
    this.out = '',
    this.fit = 100,
    this.yc = 0,
    this.rating,
  });

  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
    id: j['id'] as int,
    name: '${j['name']}',
    no: j['no'] as int? ?? 0,
    pos: '${j['pos'] ?? ''}',
    line: '${j['line'] ?? 'mid'}',
    on: j['on'] == true,
    out: '${j['out'] ?? ''}',
    fit: j['fit'] as int? ?? 100,
    yc: j['yc'] as int? ?? 0,
    rating: j['rating'] as int?,
  );

  final int id, no, fit, yc;
  final String name, pos, line, out;
  final bool on;
  final int? rating;

  /// Off the pitch for good: sent off, injured or replaced.
  bool get gone => out.isNotEmpty;
}

class MatchTeam {
  const MatchTeam({this.formation, this.tactics, this.subsUsed = 0, this.subsMax = 3, this.players = const [], this.stats = const {}});

  factory MatchTeam.fromJson(Map<String, dynamic>? j) => MatchTeam(
    formation: j?['formation'] as String?,
    tactics: j?['tactics'] == null ? null : Map<String, Object>.from(j!['tactics'] as Map<dynamic, dynamic>),
    subsUsed: j?['subs_used'] as int? ?? 0,
    subsMax: j?['subs_max'] as int? ?? 3,
    players: [for (final p in (j?['players'] as List<dynamic>? ?? const [])) MatchPlayer.fromJson(p as Map<String, dynamic>)],
    stats: {for (final e in ((j?['stats'] as Map<dynamic, dynamic>?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0},
  );

  final String? formation;
  final Map<String, Object>? tactics;
  final int subsUsed, subsMax;
  final List<MatchPlayer> players;
  final Map<String, int> stats;

  List<MatchPlayer> get onPitch => [
    for (final p in players)
      if (p.on && !p.gone) p,
  ];
  List<MatchPlayer> get bench => [
    for (final p in players)
      if (!p.on && !p.gone) p,
  ];
}

class MatchView {
  const MatchView({
    required this.id,
    required this.leagueId,
    required this.home,
    required this.away,
    required this.teams,
    this.you,
    required this.finished,
    required this.score,
    required this.tick,
    required this.tickMs,
    this.kickoffAt,
    this.formations = const [],
    this.coaches = const {},
    this.competition = 'league',
    this.round,
    this.seed,
    this.timeoutsUsed = const [],
    this.timeoutSeconds = 0,
    this.kits,
  });

  factory MatchView.fromJson(Map<String, dynamic> j) {
    final clubs = j['clubs'] as Map<String, dynamic>? ?? const {};
    final teams = j['teams'] as Map<String, dynamic>? ?? const {};
    final timing = j['timing'] as Map<String, dynamic>? ?? const {};
    final coaches = j['coaches'];
    return MatchView(
      id: j['id'] as int,
      leagueId: j['league_id'] as int? ?? 0,
      competition: '${j['competition'] ?? 'league'}',
      round: j['round'] as int?,
      home: MatchClub.fromJson(clubs['home'] as Map<String, dynamic>?),
      away: MatchClub.fromJson(clubs['away'] as Map<String, dynamic>?),
      teams: {
        'home': MatchTeam.fromJson(teams['home'] as Map<String, dynamic>?),
        'away': MatchTeam.fromJson(teams['away'] as Map<String, dynamic>?),
      },
      you: j['you'] as String?,
      finished: j['finished'] == true,
      score: _score(j['score']),
      tick: j['tick'] as int? ?? 0,
      tickMs: timing['tick_ms'] as int? ?? 3000,
      kickoffAt: DateTime.tryParse('${j['kickoff_at'] ?? ''}'),
      formations: [for (final f in (j['formations'] as List<dynamic>? ?? const [])) '$f'],
      coaches: coaches is Map<dynamic, dynamic> ? {for (final e in coaches.entries) '${e.key}': '${e.value}'} : const {},
      seed: (j['seed'] as num?)?.toInt(),
      timeoutsUsed: [for (final t in (j['timeouts'] as List<dynamic>? ?? const [])) '${(t as Map<dynamic, dynamic>)['side']}'],
      timeoutSeconds: (j['timeout_seconds'] as num?)?.toInt() ?? 0,
      kits: j['kits'] is Map<dynamic, dynamic>
          ? {
              for (final e in (j['kits'] as Map<dynamic, dynamic>).entries)
                if (e.value is Map<dynamic, dynamic>)
                  '${e.key}': (
                    shirt: '${(e.value as Map<dynamic, dynamic>)['shirt']}',
                    text: '${(e.value as Map<dynamic, dynamic>)['text']}',
                    gk: '${(e.value as Map<dynamic, dynamic>)['gk']}',
                  ),
            }
          : null,
    );
  }

  /// [Sprint 50 M14] The sides that took their timeout, and how long one holds play.
  final List<String> timeoutsUsed;
  final int timeoutSeconds;

  /// [Sprint 57 F1] Both sides' final kits from the server (App\Data\MatchKits): the shirt, its number's colour, the
  /// keeper's. The same on every screen; the app no longer works them out.
  final Map<String, ({String shirt, String text, String gk})>? kits;

  /// [Sprint 44 C3] The match's seed: the rain (MomentClock::rainy) and the cartoon's own variety, as on the web.
  final int? seed;

  final int id, leagueId, tick, tickMs;
  final int? round;
  final String competition;
  final MatchClub home, away;
  final Map<String, MatchTeam> teams;
  final String? you;
  final bool finished;
  final (int, int) score;
  final DateTime? kickoffAt;
  final List<String> formations;
  final Map<String, String> coaches;

  MatchClub club(String side) => side == 'home' ? home : away;
}

(int, int) _score(Object? s) =>
    s is Map<dynamic, dynamic> ? ((s['home'] as num?)?.toInt() ?? 0, (s['away'] as num?)?.toInt() ?? 0) : (0, 0);
