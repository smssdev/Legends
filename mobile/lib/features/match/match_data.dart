import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../api/gen/models.g.dart'
    show
        LeagueMatch,
        LeagueMatchTimeoutsItem,
        MatchCoachReport,
        MatchesLiveAnswer,
        MatchRecap,
        MatchRecapMomentsItem,
        RecapStats,
        ReportNote,
        MatchKit,
        MatchViewClub,
        MatchViewPlayer,
        MatchViewTeam;
import '../../api/gen/models.g.dart' as api;
import 'frames.dart';

part 'match_event.dart';
part 'match_report.dart';

/// [Sprint 17 F2] A league match as the server gives it (`GET /matches/{id}`, the simulator's shape): the clubs, both
/// teams (the tactics only for your own side, `you`), and the minute's length. The app only draws it.
class MatchClub {
  const MatchClub({required this.id, required this.name, required this.code, this.primary, this.secondary, this.logo, this.awayKit});

  /// [Sprint 59 F1] From the generated model.
  factory MatchClub.of(MatchViewClub c) =>
      MatchClub(id: c.id, name: c.name, code: c.code, primary: c.primary, secondary: c.secondary, logo: c.logo, awayKit: c.awayKit?.color);

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

  /// [Sprint 59 F1] From the generated model.
  factory MatchPlayer.of(MatchViewPlayer p) => MatchPlayer(
    id: p.id,
    name: p.name,
    no: p.no,
    pos: p.pos,
    line: p.line,
    on: p.on_,
    out: p.out ?? '',
    fit: p.fit ?? 100,
    yc: p.yc ?? 0,
    rating: p.rating,
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

  /// [Sprint 59 F1] From the generated model.
  factory MatchTeam.of(MatchViewTeam t) => MatchTeam(
    formation: t.formation,
    tactics: t.tactics == null
        ? null
        : {
            for (final e in t.tactics!.entries)
              if (e.value != null) e.key: e.value!,
          },
    subsUsed: t.subsUsed ?? 0,
    subsMax: t.subsMax ?? 3,
    players: [for (final p in t.players) MatchPlayer.of(p)],
    stats: {for (final e in (t.stats ?? const <String, int?>{}).entries) e.key: e.value ?? 0},
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

  /// [Sprint 59 F1] A league match (`GET /matches/{match}`), read through its generated model (`LeagueMatch`).
  factory MatchView.fromJson(Object? json) {
    final m = LeagueMatch.fromJson(json);
    final coaches = m.coaches;
    ({String shirt, String text, String gk}) kit(MatchKit k) => (shirt: k.shirt, text: k.text, gk: k.gk);
    return MatchView(
      id: m.id,
      leagueId: m.leagueId ?? 0,
      competition: m.competition ?? 'league',
      round: m.round,
      home: MatchClub.of(m.clubs.home),
      away: MatchClub.of(m.clubs.away),
      teams: {'home': MatchTeam.of(m.teams.home), 'away': MatchTeam.of(m.teams.away)},
      you: m.you,
      finished: m.finished,
      score: (m.score.home, m.score.away),
      tick: m.tick,
      tickMs: m.timing.tickMs,
      kickoffAt: DateTime.tryParse(m.kickoffAt ?? ''),
      formations: m.formations ?? const [],
      // An empty list when neither side has a coach; a map of names by side otherwise.
      coaches: coaches is Map<dynamic, dynamic> ? {for (final e in coaches.entries) '${e.key}': '${e.value}'} : const {},
      seed: m.seed,
      timeoutsUsed: [for (final t in m.timeouts ?? const <LeagueMatchTimeoutsItem>[]) t.side],
      timeoutSeconds: m.timeoutSeconds ?? 0,
      kits: m.kits == null ? null : {if (m.kits!.home case final h?) 'home': kit(h), if (m.kits!.away case final a?) 'away': kit(a)},
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
