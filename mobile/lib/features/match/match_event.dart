part of 'match_data.dart';

/// One event of a minute, with the server's commentary line (`text`, the same for everyone).
class MatchEvent {
  const MatchEvent({required this.type, this.team, this.text, required this.minute, this.added = 0, this.color});

  /// [Sprint 59 F1] From the generated model (`LiveEvent` in openapi.yaml).
  factory MatchEvent.of(api.LiveEvent e, {required int minute, int added = 0}) =>
      MatchEvent(type: e.type, team: e.team, text: e.text, minute: minute, added: added, color: e.color);

  final String type;
  final String? team, text, color;
  final int minute, added;

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

  /// [Sprint 59 F1] A minute as the server sends it, through its generated model (`LiveMinute`).
  factory LiveTick.fromJson(Object? json) => LiveTick.of(api.LiveMinute.fromJson(json));

  factory LiveTick.of(api.LiveMinute m) {
    final (minute, added) = clockOf(m.minute);
    final teams = m.teams;
    return LiveTick(
      tick: m.tick,
      minute: minute,
      added: added,
      score: (m.score.home, m.score.away),
      events: [for (final e in m.events) MatchEvent.of(e, minute: minute, added: added)],
      teams: teams == null
          ? null
          : {
              'home': teams.home == null ? const MatchTeam() : MatchTeam.of(teams.home!),
              'away': teams.away == null ? const MatchTeam() : MatchTeam.of(teams.away!),
            },
      frames: [for (final f in m.frames ?? const <api.Keyframe>[]) Keyframe.of(f)],
      at: m.at,
      window: m.window ?? false,
      finished: m.finished ?? false,
      period: m.period,
      moment: m.moment == null ? null : Moment.of(m.moment!),
      moods: m.moods ?? const {},
      how: m.voice?.how,
      momentumNow: m.momentum?.now ?? 0,
      momentumPct: m.momentum?.homePct,
      story: m.story,
    );
  }

  final int tick, minute, added;
  final (int, int) score;
  final List<MatchEvent> events;
  final Map<String, MatchTeam>? teams;
  final List<Keyframe> frames;
  final int? at, period;

  /// [Sprint 57 F1] The minute's story as the server tells it (MomentStory), for the broadcast (feed/story.dart).
  final api.MomentStory? story;
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

  factory Moment.of(api.LiveMoment m) => Moment(kind: m.kind, ms: m.ms, brief: m.brief ?? false, drama: m.drama, varReason: m.var_);

  final String kind;
  final int ms;
  final bool brief;
  final String? drama, varReason;
}

/// The break under way [UP17]: until when (server ms), who is ready, and whether orders are open in it.
class MatchPause {
  const MatchPause({required this.until, this.ready = const [], this.window = false});

  factory MatchPause.of(api.MatchLivePause p) => MatchPause(until: p.until ?? 0, ready: p.ready ?? const [], window: p.window ?? false);

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

  /// [Sprint 59 F1] `GET /matches/{match}/live` through its generated model (`MatchLive`).
  factory LiveSync.fromJson(Object? json) {
    final j = api.MatchLive.fromJson(json);
    return LiveSync(
      finished: j.finished,
      tick: j.tick,
      serverNow: j.serverNow,
      nextAt: j.nextAt,
      ticks: [for (final t in j.ticks) LiveTick.of(t)],
      missed: [
        for (final t in j.missed)
          for (final e in t.events) MatchEvent.of(e, minute: t.minute),
      ],
      pause: j.pause == null ? null : MatchPause.of(j.pause!),
      pollMs: j.pollMs,
      readings: [for (final r in j.readings) r.text],
      chat: [for (final c in j.chat ?? const <api.BroadcastChat>[]) chatOf(c)],
      reactions: [for (final r in j.reactions ?? const <api.BroadcastReaction>[]) reactionOf(r)],
    );
  }

  /// One side-chat message and one reaction, as the poll and the channel give them.
  static ({int id, String who, String body, String? side}) chatOf(api.BroadcastChat c) =>
      (id: c.id, who: c.who, body: c.body, side: c.side);
  static ({int id, String who, String key, String? target}) reactionOf(api.BroadcastReaction r) =>
      (id: r.id, who: r.who, key: r.key, target: r.target);

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

/// [Sprint 59 F1] A minute's clock as the server writes it: [minute] or [minute, added]; an old saved one, a bare number.
(int, int) clockOf(Object? minute) => switch (minute) {
  [final num m, final num a, ...] => (m.toInt(), a.toInt()),
  [final num m] => (m.toInt(), 0),
  final num m => (m.toInt(), 0),
  _ => (0, 0),
};
