import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';
import 'frames.dart';

/// [Sprint 17 F2] A league match as the server gives it (`GET /matches/{id}`, the simulator's shape): the clubs, both
/// teams (the tactics only for your own side, `you`), and the minute's length. The app only draws it.
class MatchClub {
  const MatchClub({required this.id, required this.name, required this.code, this.primary, this.secondary, this.logo, this.awayKit});

  factory MatchClub.fromJson(Map<String, dynamic>? j) => MatchClub(
        id: j?['id'] as int? ?? 0, name: '${j?['name'] ?? ''}', code: '${j?['code'] ?? ''}',
        primary: j?['primary'] as String?, secondary: j?['secondary'] as String?, logo: j?['logo'] as String?,
        awayKit: (j?['away_kit'] as Map?)?['color'] as String?,
      );

  final int id;
  final String name, code;
  final String? primary, secondary, logo;

  /// [Sprint 34 V1] Its change kit's colour, worn on a clash.
  final String? awayKit;
}

class MatchPlayer {
  const MatchPlayer({required this.id, required this.name, required this.no, required this.pos, required this.line, required this.on,
      this.out = '', this.fit = 100, this.yc = 0, this.rating});

  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
        id: j['id'] as int, name: '${j['name']}', no: j['no'] as int? ?? 0, pos: '${j['pos'] ?? ''}', line: '${j['line'] ?? 'mid'}',
        on: j['on'] == true, out: '${j['out'] ?? ''}', fit: j['fit'] as int? ?? 100, yc: j['yc'] as int? ?? 0, rating: j['rating'] as int?,
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
        tactics: j?['tactics'] == null ? null : Map<String, Object>.from(j!['tactics'] as Map),
        subsUsed: j?['subs_used'] as int? ?? 0, subsMax: j?['subs_max'] as int? ?? 3,
        players: [for (final p in (j?['players'] as List? ?? const [])) MatchPlayer.fromJson(p as Map<String, dynamic>)],
        stats: {for (final e in ((j?['stats'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0},
      );

  final String? formation;
  final Map<String, Object>? tactics;
  final int subsUsed, subsMax;
  final List<MatchPlayer> players;
  final Map<String, int> stats;

  List<MatchPlayer> get onPitch => [for (final p in players) if (p.on && !p.gone) p];
  List<MatchPlayer> get bench => [for (final p in players) if (!p.on && !p.gone) p];
}

class MatchView {
  const MatchView({required this.id, required this.leagueId, required this.home, required this.away, required this.teams, this.you,
      required this.finished, required this.score, required this.tick, required this.tickMs, this.kickoffAt, this.formations = const [],
      this.coaches = const {}, this.competition = 'league', this.round, this.seed});

  factory MatchView.fromJson(Map<String, dynamic> j) {
    final clubs = j['clubs'] as Map<String, dynamic>? ?? const {};
    final teams = j['teams'] as Map<String, dynamic>? ?? const {};
    final timing = j['timing'] as Map<String, dynamic>? ?? const {};
    final coaches = j['coaches'];
    return MatchView(
      id: j['id'] as int, leagueId: j['league_id'] as int? ?? 0, competition: '${j['competition'] ?? 'league'}', round: j['round'] as int?,
      home: MatchClub.fromJson(clubs['home'] as Map<String, dynamic>?), away: MatchClub.fromJson(clubs['away'] as Map<String, dynamic>?),
      teams: {'home': MatchTeam.fromJson(teams['home'] as Map<String, dynamic>?), 'away': MatchTeam.fromJson(teams['away'] as Map<String, dynamic>?)},
      you: j['you'] as String?, finished: j['finished'] == true,
      score: _score(j['score']), tick: j['tick'] as int? ?? 0, tickMs: timing['tick_ms'] as int? ?? 3000,
      kickoffAt: DateTime.tryParse('${j['kickoff_at'] ?? ''}'),
      formations: [for (final f in (j['formations'] as List? ?? const [])) '$f'],
      coaches: coaches is Map ? {for (final e in coaches.entries) '${e.key}': '${e.value}'} : const {},
      seed: (j['seed'] as num?)?.toInt(),
    );
  }

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

(int, int) _score(Object? s) => s is Map ? ((s['home'] as num?)?.toInt() ?? 0, (s['away'] as num?)?.toInt() ?? 0) : (0, 0);

/// One event of a minute, with the server's commentary line (`text`, the same for everyone).
class MatchEvent {
  const MatchEvent({required this.type, this.team, this.text, required this.minute, this.added = 0, this.color, this.raw = const {}});

  factory MatchEvent.fromJson(Map<String, dynamic> j, {required int minute, int added = 0}) => MatchEvent(
        type: '${j['type']}', team: j['team'] as String?, text: j['text'] as String?, minute: minute, added: added,
        color: j['color'] as String?, raw: j,
      );

  final String type;
  final String? team, text, color;
  final int minute, added;
  final Map<String, dynamic> raw;

  bool get big => type == 'goal' || (type == 'card' && color == 'red') || type == 'penalty' || type == 'period';
  String get clock => added > 0 ? "$minute+$added'" : "$minute'";
}

/// A minute made by the server: its clock, score, events, both teams as they stand, and its Keyframes.
class LiveTick {
  const LiveTick({required this.tick, required this.minute, this.added = 0, required this.score, required this.events, this.teams,
      this.frames = const [], this.at, this.window = false, this.finished = false, this.period, this.moment, this.moods = const {}, this.how});

  factory LiveTick.fromJson(Map<String, dynamic> j) {
    final m = j['minute'];
    final minute = m is List ? (m[0] as num).toInt() : (m as num?)?.toInt() ?? 0;
    final added = m is List && m.length > 1 ? (m[1] as num).toInt() : 0;
    final teams = j['teams'] as Map<String, dynamic>?;
    return LiveTick(
      tick: j['tick'] as int, minute: minute, added: added, score: _score(j['score']),
      events: [for (final e in (j['events'] as List? ?? const [])) MatchEvent.fromJson(e as Map<String, dynamic>, minute: minute, added: added)],
      teams: teams == null ? null : {'home': MatchTeam.fromJson(teams['home'] as Map<String, dynamic>?), 'away': MatchTeam.fromJson(teams['away'] as Map<String, dynamic>?)},
      frames: [for (final f in (j['frames'] as List? ?? const [])) Keyframe.fromJson(f as Map<String, dynamic>)],
      at: (j['at'] as num?)?.toInt(), window: j['window'] == true, finished: j['finished'] == true, period: j['period'] as int?,
      moment: j['moment'] is Map ? Moment.fromJson(j['moment'] as Map<String, dynamic>) : null,
      moods: j['moods'] is Map ? {for (final e in (j['moods'] as Map).entries) '${e.key}': '${e.value}'} : const {},
      how: j['voice'] is Map ? (j['voice'] as Map)['how'] as String? : null,
    );
  }

  final int tick, minute, added;
  final (int, int) score;
  final List<MatchEvent> events;
  final Map<String, MatchTeam>? teams;
  final List<Keyframe> frames;
  final int? at, period;
  final bool window, finished;

  /// [Sprint 44 A1] How the server tells this minute on the broadcast (MomentClock::moment), and the coaches' moods.
  final Moment? moment;
  final Map<String, String> moods;

  /// Where a missed shot went (wide, over, the post): the server's, with its commentary line.
  final String? how;
}

/// [Sprint 44 A1] The server's moment for a minute: its kind, its length on the broadcast, a brief one (only its card),
/// how a card or a foul is told (drama), and why VAR ruled a goal out.
class Moment {
  const Moment({required this.kind, required this.ms, this.brief = false, this.drama, this.varReason});

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
        kind: '${j['kind'] ?? 'quiet'}', ms: (j['ms'] as num?)?.toInt() ?? 3000, brief: j['brief'] == true,
        drama: j['drama'] as String?, varReason: j['var'] as String?,
      );

  final String kind;
  final int ms;
  final bool brief;
  final String? drama, varReason;
}

/// The break under way [UP17]: until when (server ms), who is ready, and whether orders are open in it.
class MatchPause {
  const MatchPause({required this.until, this.ready = const [], this.window = false});

  factory MatchPause.fromJson(Map<String, dynamic> j) =>
      MatchPause(until: (j['until'] as num?)?.toInt() ?? 0, ready: [for (final r in (j['ready'] as List? ?? const [])) '$r'], window: j['window'] == true);

  final int until;
  final List<String> ready;
  final bool window;
}

class LiveSync {
  const LiveSync({required this.finished, required this.tick, required this.serverNow, this.nextAt, this.ticks = const [], this.missed = const [],
      this.pause, this.pollMs, this.readings = const [], this.chat = const [], this.reactions = const []});

  factory LiveSync.fromJson(Map<String, dynamic> j) => LiveSync(
        finished: j['finished'] == true, tick: j['tick'] as int? ?? 0, serverNow: (j['server_now'] as num?)?.toInt() ?? 0,
        nextAt: (j['next_at'] as num?)?.toInt(),
        ticks: [for (final t in (j['ticks'] as List? ?? const [])) LiveTick.fromJson(t as Map<String, dynamic>)],
        missed: [
          for (final t in (j['missed'] as List? ?? const []))
            for (final e in ((t as Map)['events'] as List? ?? const []))
              MatchEvent.fromJson(e as Map<String, dynamic>, minute: (t['minute'] as num?)?.toInt() ?? 0),
        ],
        pause: j['pause'] is Map ? MatchPause.fromJson(j['pause'] as Map<String, dynamic>) : null,
        pollMs: (j['poll_ms'] as num?)?.toInt(),
        readings: [for (final r in (j['readings'] as List? ?? const [])) if (r is Map && r['text'] != null) '${r['text']}'],
        chat: [for (final c in (j['chat'] as List? ?? const [])) (id: (c as Map)['id'] as int, who: '${c['who']}', body: '${c['body']}', side: c['side'] as String?)],
        reactions: [for (final r in (j['reactions'] as List? ?? const [])) (id: (r as Map)['id'] as int, who: '${r['who']}', key: '${r['key']}', target: r['target'] as String?)],
      );

  final bool finished;
  final int tick, serverNow;
  final int? nextAt, pollMs;
  final List<LiveTick> ticks;
  final List<MatchEvent> missed;
  final MatchPause? pause;
  final List<String> readings;

  /// [X24] The side chat between the league's viewers (the latest 50) and the latest reactions.
  final List<({int id, String who, String body, String? side})> chat;
  final List<({int id, String who, String key, String? target})> reactions;
}

/// What the app needs of a finished match: the coach's report, or the recap for a member who coaches neither side.
class MatchReport {
  const MatchReport({required this.score, this.result, this.side, this.reasons = const [], this.improve, this.verdict = const [], this.motm,
      this.stats = const {}, this.moments = const [], this.ratings = const {}});

  factory MatchReport.fromReport(Map<String, dynamic> j) => MatchReport(
        score: _score(j['score']), result: j['result'] as String?, side: j['side'] as String?,
        reasons: [for (final r in (j['reasons'] as List? ?? const [])) _note(r as Map)],
        improve: j['improve'] is Map ? _note(j['improve'] as Map) : null,
        verdict: [for (final v in (j['verdict'] as List? ?? const [])) (tag: '${(v as Map)['tag'] ?? ''}', text: '${v['text'] ?? ''}')],
        motm: j['man_of_the_match'] is Map ? '${(j['man_of_the_match'] as Map)['name'] ?? ''}' : null,
        stats: _stats(j['stats']),
        moments: [
          for (final t in (j['timeline'] as List? ?? const []))
            if ((t as Map)['type'] case 'goal' || 'card' || 'sub' || 'injury' || 'penalty')
              MatchEvent.fromJson(t as Map<String, dynamic>, minute: (t['minute'] is List ? (t['minute'] as List)[0] : t['minute'] as num? ?? 0).toInt(),
                  added: t['minute'] is List && (t['minute'] as List).length > 1 ? ((t['minute'] as List)[1] as num).toInt() : 0),
        ],
        ratings: {
          for (final side in ['home', 'away'])
            side: [for (final r in ((j['ratings'] as Map?)?[side] as List? ?? const [])) (name: '${(r as Map)['name']}', rating: (r['rating'] as num?)?.toInt() ?? 0)],
        },
      );

  factory MatchReport.fromRecap(Map<String, dynamic> j) => MatchReport(
        score: _score(j['score']), result: j['result'] as String?, side: j['side'] as String?,
        motm: j['man_of_the_match'] is Map ? '${(j['man_of_the_match'] as Map)['name'] ?? ''}' : null,
        stats: _stats(j['stats']),
        moments: [
          for (final m in (j['moments'] as List? ?? const []))
            MatchEvent(type: '${(m as Map)['type']}', team: m['team'] as String?, minute: (m['minute'] as num?)?.toInt() ?? 0, color: m['color'] as String?,
                text: _moment(m), raw: Map<String, dynamic>.from(m)),
        ],
        ratings: {
          for (final side in ['home', 'away'])
            side: [for (final r in ((j['best'] as Map?)?[side] as List? ?? const [])) (name: '${(r as Map)['name']}', rating: (r['rating'] as num?)?.toInt() ?? 0)],
        },
      );

  /// The report with the recap's key moments, which carry the players' names.
  MatchReport withMoments(MatchReport recap) => MatchReport(score: score, result: result, side: side, reasons: reasons, improve: improve,
      verdict: verdict, motm: motm, stats: recap.stats, moments: recap.moments, ratings: ratings);

  final (int, int) score;
  final String? result, side, motm;
  final List<({String title, String text, String big})> reasons;
  final ({String title, String text, String big})? improve;
  final List<({String tag, String text})> verdict;
  final Map<String, Map<String, int>> stats;
  final List<MatchEvent> moments;
  final Map<String, List<({String name, int rating})>> ratings;
}

/// A recap moment in a line (names in English): the scorer and his assist, who came on for whom, the booked player.
String _moment(Map m) {
  final who = m['player'] as String? ?? '', other = m['other'] as String?;
  return switch (m['type']) {
    'goal' => other == null ? who : '$who ($other)',
    'sub' => other == null ? who : '$other ⇄ $who',
    _ => who,
  };
}

({String title, String text, String big}) _note(Map r) => (title: '${r['title'] ?? ''}', text: '${r['text'] ?? ''}', big: '${r['big'] ?? ''}');

Map<String, Map<String, int>> _stats(Object? s) => {
      for (final side in ['home', 'away'])
        side: {for (final e in (((s as Map?)?[side] as Map?) ?? const {}).entries) if (e.value is num) '${e.key}': (e.value as num).toInt()},
    };

class MatchRepository {
  MatchRepository(this._api);

  final ApiClient _api;

  Future<MatchView> show(int id) async => MatchView.fromJson(await _api.get('/matches/$id'));
  Future<LiveSync> live(int id, int since) async => LiveSync.fromJson(await _api.get('/matches/$id/live', query: {'since': since}));

  /// An order for the next minute not yet made; only in a window (the server answers 409 otherwise, with why).
  Future<void> order(int id, Map<String, Object> order) =>
      Intents.run('order:$id:$order', (key) => _api.post('/matches/$id/actions', {...order, 'idempotency_key': key}));
  Future<void> sub(int id, int out, int into) => order(id, {'type': 'sub', 'out': out, 'in': into});
  Future<void> tactics(int id, Map<String, Object> changes) => order(id, {'type': 'tactics', 'tactics': changes});
  Future<void> formation(int id, String formation) => order(id, {'type': 'formation', 'formation': formation});
  Future<void> ready(int id) => _api.post('/matches/$id/ready');
  Future<void> react(int id, String key, {String? target}) => _api.post('/matches/$id/reactions', {'key': key, 'target': ?target});
  Future<void> say(int id, String body) => _api.post('/matches/$id/chat', {'body': body});

  /// The coach's own report; the quick recap for a member who coaches neither side (403 on the report).
  Future<MatchReport> report(int id, {required bool coach}) async {
    final recap = _api.get('/matches/$id/recap');
    if (!coach) return MatchReport.fromRecap(await recap);
    final report = await _api.get('/matches/$id/report');
    return MatchReport.fromReport(report).withMoments(MatchReport.fromRecap(await recap));
  }

  /// My matches being played now, in every league (the switcher).
  Future<List<({int id, String home, String away})>> mine() async => [
        for (final m in ((await _api.get('/matches/live'))['matches'] as List? ?? const []))
          (id: (m as Map)['id'] as int, home: '${m['home']}', away: '${m['away']}'),
      ];
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) => MatchRepository(ref.watch(apiProvider)));
final matchProvider = FutureProvider.autoDispose.family<MatchView, int>((ref, id) => ref.read(matchRepositoryProvider).show(id));
final myLiveMatchesProvider = FutureProvider.autoDispose((ref) => ref.read(matchRepositoryProvider).mine());
final reportProvider = FutureProvider.autoDispose.family<MatchReport, (int, bool)>((ref, k) => ref.read(matchRepositoryProvider).report(k.$1, coach: k.$2));
