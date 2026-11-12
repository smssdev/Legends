part of 'match_data.dart';

/// One event of a minute, with the server's commentary line (`text`, the same for everyone).
class MatchEvent {
  const MatchEvent({required this.type, this.team, this.text, required this.minute, this.added = 0, this.color, this.raw = const {}});

  factory MatchEvent.fromJson(Map<String, dynamic> j, {required int minute, int added = 0}) => MatchEvent(
    type: '${j['type']}',
    team: j['team'] as String?,
    text: j['text'] as String?,
    minute: minute,
    added: added,
    color: j['color'] as String?,
    raw: j,
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
  const LiveTick({
    required this.tick,
    required this.minute,
    this.added = 0,
    required this.score,
    required this.events,
    this.teams,
    this.frames = const [],
    this.at,
    this.window = false,
    this.finished = false,
    this.period,
    this.moment,
    this.moods = const {},
    this.how,
    this.momentumNow = 0,
    this.momentumPct,
    this.story,
  });

  factory LiveTick.fromJson(Map<String, dynamic> j) {
    final m = j['minute'];
    final minute = m is List<dynamic> ? (m[0] as num).toInt() : (m as num?)?.toInt() ?? 0;
    final added = m is List<dynamic> && m.length > 1 ? (m[1] as num).toInt() : 0;
    final teams = j['teams'] as Map<String, dynamic>?;
    return LiveTick(
      tick: j['tick'] as int,
      minute: minute,
      added: added,
      score: _score(j['score']),
      events: [
        for (final e in (j['events'] as List<dynamic>? ?? const []))
          MatchEvent.fromJson(e as Map<String, dynamic>, minute: minute, added: added),
      ],
      teams: teams == null
          ? null
          : {
              'home': MatchTeam.fromJson(teams['home'] as Map<String, dynamic>?),
              'away': MatchTeam.fromJson(teams['away'] as Map<String, dynamic>?),
            },
      frames: [for (final f in (j['frames'] as List<dynamic>? ?? const [])) Keyframe.fromJson(f as Map<String, dynamic>)],
      at: (j['at'] as num?)?.toInt(),
      window: j['window'] == true,
      finished: j['finished'] == true,
      period: j['period'] as int?,
      moment: j['moment'] is Map<dynamic, dynamic> ? Moment.fromJson(j['moment'] as Map<String, dynamic>) : null,
      moods: j['moods'] is Map<dynamic, dynamic>
          ? {for (final e in (j['moods'] as Map<dynamic, dynamic>).entries) '${e.key}': '${e.value}'}
          : const {},
      how: j['voice'] is Map<dynamic, dynamic> ? (j['voice'] as Map<dynamic, dynamic>)['how'] as String? : null,
      momentumNow: ((j['momentum'] as Map<dynamic, dynamic>?)?['now'] as num?)?.toInt() ?? 0,
      momentumPct: ((j['momentum'] as Map<dynamic, dynamic>?)?['home_pct'] as num?)?.toInt(),
      story: j['story'] is Map<dynamic, dynamic> ? (j['story'] as Map<dynamic, dynamic>).cast<String, dynamic>() : null,
    );
  }

  final int tick, minute, added;
  final (int, int) score;
  final List<MatchEvent> events;
  final Map<String, MatchTeam>? teams;
  final List<Keyframe> frames;
  final int? at, period;

  /// [Sprint 57 F1] The minute's story as the server tells it (MomentStory), for the broadcast (feed/story.dart).
  final Map<String, dynamic>? story;
  final bool window, finished;

  /// [Sprint 44 A1] How the server tells this minute on the broadcast (MomentClock::moment), and the coaches' moods.
  final Moment? moment;
  final Map<String, String> moods;

  /// [Sprint 50 M15] The momentum after this minute (the server's): this minute's danger (+ home, - away) and the home
  /// side's share of the last minutes.
  final int momentumNow;
  final int? momentumPct;

  /// Where a missed shot went (wide, over, the post): the server's, with its commentary line.
  final String? how;
}

/// [Sprint 44 A1] The server's moment for a minute: its kind, its length on the broadcast, a brief one (only its card),
/// how a card or a foul is told (drama), and why VAR ruled a goal out.
class Moment {
  const Moment({required this.kind, required this.ms, this.brief = false, this.drama, this.varReason});

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
    kind: '${j['kind'] ?? 'quiet'}',
    ms: (j['ms'] as num?)?.toInt() ?? 3000,
    brief: j['brief'] == true,
    drama: j['drama'] as String?,
    varReason: j['var'] as String?,
  );

  final String kind;
  final int ms;
  final bool brief;
  final String? drama, varReason;
}

/// The break under way [UP17]: until when (server ms), who is ready, and whether orders are open in it.
class MatchPause {
  const MatchPause({required this.until, this.ready = const [], this.window = false});

  factory MatchPause.fromJson(Map<String, dynamic> j) => MatchPause(
    until: (j['until'] as num?)?.toInt() ?? 0,
    ready: [for (final r in (j['ready'] as List<dynamic>? ?? const [])) '$r'],
    window: j['window'] == true,
  );

  final int until;
  final List<String> ready;
  final bool window;
}

class LiveSync {
  const LiveSync({
    required this.finished,
    required this.tick,
    required this.serverNow,
    this.nextAt,
    this.ticks = const [],
    this.missed = const [],
    this.pause,
    this.pollMs,
    this.readings = const [],
    this.chat = const [],
    this.reactions = const [],
  });

  factory LiveSync.fromJson(Map<String, dynamic> j) => LiveSync(
    finished: j['finished'] == true,
    tick: j['tick'] as int? ?? 0,
    serverNow: (j['server_now'] as num?)?.toInt() ?? 0,
    nextAt: (j['next_at'] as num?)?.toInt(),
    ticks: [for (final t in (j['ticks'] as List<dynamic>? ?? const [])) LiveTick.fromJson(t as Map<String, dynamic>)],
    missed: [
      for (final t in (j['missed'] as List<dynamic>? ?? const []))
        for (final e in ((t as Map<dynamic, dynamic>)['events'] as List<dynamic>? ?? const []))
          MatchEvent.fromJson(e as Map<String, dynamic>, minute: (t['minute'] as num?)?.toInt() ?? 0),
    ],
    pause: j['pause'] is Map<dynamic, dynamic> ? MatchPause.fromJson(j['pause'] as Map<String, dynamic>) : null,
    pollMs: (j['poll_ms'] as num?)?.toInt(),
    readings: [
      for (final r in (j['readings'] as List<dynamic>? ?? const []))
        if (r is Map<dynamic, dynamic> && r['text'] != null) '${r['text']}',
    ],
    chat: [
      for (final c in (j['chat'] as List<dynamic>? ?? const []))
        (id: (c as Map<dynamic, dynamic>)['id'] as int, who: '${c['who']}', body: '${c['body']}', side: c['side'] as String?),
    ],
    reactions: [
      for (final r in (j['reactions'] as List<dynamic>? ?? const []))
        (id: (r as Map<dynamic, dynamic>)['id'] as int, who: '${r['who']}', key: '${r['key']}', target: r['target'] as String?),
    ],
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
