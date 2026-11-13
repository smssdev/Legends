import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';
import '../../core/api/api_error.dart';
import '../../core/live/live_channels.dart';
import 'feed/broadcast.dart';
import 'feed/director.dart';
import 'feed/story.dart';
import 'match_data.dart';
import 'sim_source.dart';

/// [Sprint 61 F4] What the live match screen shows of the match as it goes: one value, changed whole at each minute
/// told, so each part of the screen watches only its own (`select`): the score, the pitch, the feed, the wave, the
/// chat. The screen's own (a drawer open, an order on its way) stays in the screen.
class LiveMatchState {
  const LiveMatchState({
    required this.score,
    required this.teams,
    required this.finished,
    this.recent = const [],
    this.feed = const [],
    this.readings = const [],
    this.chat = const [],
    this.reactions = const [],
    this.pause,
    this.tick = 0,
    this.offset = 0,
    this.minute = 0,
    this.added = 0,
    this.started = false,
    this.wave = const [],
    this.homePct,
    this.playsVersion = 0,
  });

  final (int, int) score;
  final Map<String, MatchTeam> teams;
  final bool finished, started;

  /// The last minutes for the light pitch (three at most).
  final List<LiveTick> recent;

  /// The commentary, newest first (200 at most).
  final List<MatchEvent> feed;
  final List<String> readings;
  final List<({int id, String who, String body, String? side})> chat;
  final List<({int id, String who, String key, String? target})> reactions;
  final MatchPause? pause;
  final int tick, offset, minute, added;

  /// The momentum wave (the last 30 minutes' danger) and the home side's share.
  final List<int> wave;
  final int? homePct;

  /// Grows when a scene joins the broadcast's queue (LiveMatch.plays), so the stage takes it.
  final int playsVersion;

  /// The clock as the score bug shows it ("67'", "90+3'"), null before the start.
  String? get clock => started ? (added > 0 ? "$minute+$added'" : "$minute'") : null;

  LiveMatchState copyWith({
    (int, int)? score,
    Map<String, MatchTeam>? teams,
    bool? finished,
    List<LiveTick>? recent,
    List<MatchEvent>? feed,
    List<String>? readings,
    List<({int id, String who, String body, String? side})>? chat,
    List<({int id, String who, String key, String? target})>? reactions,
    MatchPause? pause,
    bool keepPause = true,
    int? tick,
    int? offset,
    int? minute,
    int? added,
    bool? started,
    List<int>? wave,
    int? homePct,
    int? playsVersion,
  }) => LiveMatchState(
    score: score ?? this.score,
    teams: teams ?? this.teams,
    finished: finished ?? this.finished,
    recent: recent ?? this.recent,
    feed: feed ?? this.feed,
    readings: readings ?? this.readings,
    chat: chat ?? this.chat,
    reactions: reactions ?? this.reactions,
    pause: keepPause ? (pause ?? this.pause) : pause,
    tick: tick ?? this.tick,
    offset: offset ?? this.offset,
    minute: minute ?? this.minute,
    added: added ?? this.added,
    started: started ?? this.started,
    wave: wave ?? this.wave,
    homePct: homePct ?? this.homePct,
    playsVersion: playsVersion ?? this.playsVersion,
  );
}

/// [Sprint 61 F4] A live match on the screen: its poll and its channel (Sprint 53), the minutes told in their turn (a
/// minute with a scene waits for its key moment, Sprint 44), the side chat and the reactions. The screen draws
/// [state] and tells it when the phone comes back ([now]) or sleeps ([hold]).
class LiveMatch extends Notifier<LiveMatchState> {
  LiveMatch(this.id);

  final int id;

  /// The broadcast's queue: the stage takes the scenes from it as they come (the same list, never replaced).
  final List<BroadcastPlay> plays = [];

  /// The words of the minute's story: Arabic, or English (the screen says which).
  bool ar = true;

  late MatchView _view;
  late MatchRepository _repo;
  final List<(LiveTick, bool)> _untold = [];
  bool _synced = false;
  Timer? _timer;
  LiveSubscription? _channel;
  static const _pushedPollMs = 12000, _breakPollMs = 2000;

  bool get _sim => id < 0;

  @override
  LiveMatchState build() {
    _view = ref.read(matchProvider(id)).requireValue;
    _repo = ref.read(matchSourceProvider(id));
    ref.onDispose(() {
      _timer?.cancel();
      _channel?.subscribed.removeListener(_channelChanged);
      _channel?.leave();
    });
    scheduleMicrotask(_start);
    return LiveMatchState(score: _view.score, teams: _view.teams, finished: _view.finished);
  }

  void _start() {
    if (!ref.mounted) return;
    unawaited(_poll());
    if (!_view.finished && !_sim) {
      _channel = ref.read(liveFeedProvider).join('match.$id', {'minute': _pushed, 'chat': _pushedChat, 'reaction': _pushedReaction});
      _channel!.subscribed.addListener(_channelChanged);
    }
  }

  /// Ask now (the phone came back, a message was sent): what was missed comes at once.
  Future<void> now() async {
    if (state.finished) return;
    _timer?.cancel();
    await _poll();
  }

  /// The phone sleeps: no asking until [now].
  void hold() => _timer?.cancel();

  /// The channel came (ask once for what it may have missed) or went (back to the poll's own pace at once).
  void _channelChanged() {
    if (!ref.mounted || state.finished) return;
    unawaited(now());
  }

  Future<void> _poll() async {
    var wait = 1500;
    try {
      final s = await _repo.live(id, state.tick);
      if (!ref.mounted) return;
      _apply(s);
      wait = s.pollMs ?? wait;
      // [Sprint 53 F2] On the channel the minutes come by themselves.
      if (_channel?.subscribed.value == true && state.started) {
        final floor = state.pause != null ? _breakPollMs : _pushedPollMs;
        wait = wait > floor ? wait : floor;
      }
    } on ApiError {
      wait = 4000;
    } catch (_) {
      // [2026-11-09] Any other failure (a field the app did not expect) must not stop the match: try again shortly.
      wait = 4000;
    }
    if (ref.mounted && !state.finished) _timer = Timer(Duration(milliseconds: wait), _poll);
  }

  /// [Sprint 53 F2] A minute pushed whole (App\Events\MatchMinute's `live`): told as if the poll had brought it.
  void _pushed(Map<String, dynamic> e) {
    // [Sprint 59 F1] The event's minute through its generated model (`LiveMinute`); one that does not read is left to the poll.
    final r = JsonReader(e, 'MatchMinute');
    final live = r.objectOrNull('live', api.LiveMinute.fromJson);
    if (!ref.mounted || state.finished || live == null) return;
    final t = LiveTick.of(live);
    if (t.tick <= state.tick) return;
    // A minute missing in between (a message lost): the poll brings everything after the last one told.
    if (t.tick > state.tick + 1) return unawaited(now());
    _apply(
      LiveSync(
        finished: t.finished,
        tick: t.tick,
        serverNow: DateTime.now().millisecondsSinceEpoch + state.offset,
        nextAt: r.intOrNull('next_at'),
        ticks: [t],
        pause: state.pause,
        chat: state.chat,
        reactions: state.reactions,
      ),
    );
    // A break opens or the match ends: the details (who is ready, the window) from the poll, now.
    if (t.window || t.finished || t.period != null && t.events.any((x) => x.type == 'period')) unawaited(now());
  }

  void _pushedChat(Map<String, dynamic> e) {
    final c = JsonReader(e, 'MatchSocialPosted').objectOrNull('item', api.BroadcastChat.fromJson);
    if (!ref.mounted || c == null || state.chat.any((x) => x.id == c.id)) return;
    state = state.copyWith(chat: [...state.chat, LiveSync.chatOf(c)].take(50).toList());
  }

  void _pushedReaction(Map<String, dynamic> e) {
    final r = JsonReader(e, 'MatchSocialPosted').objectOrNull('item', api.BroadcastReaction.fromJson);
    if (!ref.mounted || r == null || state.reactions.any((x) => x.id == r.id)) return;
    state = state.copyWith(reactions: [...state.reactions, LiveSync.reactionOf(r)]);
  }

  void _apply(LiveSync s) {
    var st = state.copyWith(
      offset: s.serverNow - DateTime.now().millisecondsSinceEpoch,
      pause: s.pause,
      keepPause: false,
      readings: s.readings.isNotEmpty ? s.readings : null,
      chat: s.chat,
      reactions: s.reactions,
    );
    // A gap (a locked phone, a lost connection): the events of the minutes missed, then the minutes themselves.
    final feed = [...s.missed.reversed, ...st.feed];
    if (feed.length > 200) feed.removeRange(200, feed.length);
    final recent = [...st.recent];
    final wave = [...st.wave];
    var plays = 0;
    for (final t in s.ticks) {
      if (t.tick <= st.tick) continue;
      st = st.copyWith(
        tick: t.tick,
        started: true,
        minute: t.minute,
        added: t.added,
        teams: t.teams,
        homePct: t.momentumPct,
        finished: t.finished ? true : null,
      );
      wave.add(t.momentumNow);
      if (wave.length > 30) wave.removeAt(0);
      recent.add(t);
      // A minute with a scene waits for it (not the minutes already played when the page opened); the rest is told
      // in its turn.
      final story = _synced ? _story(t, st.teams) : null;
      if (story?.scene != null) {
        plays++;
        this.plays.add(
          BroadcastPlay.of(
            t.tick,
            story!,
            total: (t.moment?.ms ?? _view.tickMs) / 1000,
            moods: t.moods,
            tier: Tier.high,
            seed: _view.seed ?? 1,
          ),
        );
        _untold.add((t, false));
      } else {
        _untold.add((t, true));
      }
    }
    _synced = true;
    if (recent.length > 3) recent.removeRange(0, recent.length - 3);
    st = st.copyWith(recent: recent, wave: wave, feed: feed, finished: s.finished ? true : null, playsVersion: st.playsVersion + plays);
    state = _told(st);
  }

  /// The minute's story for the broadcast (feed/story.dart): the names, numbers and clubs as this match has them.
  FeedStory _story(LiveTick t, Map<String, MatchTeam> teams) => feedStory(
    t,
    cast: {
      for (final side in ['home', 'away'])
        for (final p in (t.teams ?? teams)[side]!.players) '${p.id}': (name: p.name, no: p.no, side: side),
    },
    clubs: {'home': _view.home.name, 'away': _view.away.name},
    ar: ar,
  );

  /// A minute's key moment has come (the stage says so, sometimes while it is being built): it, and every minute after
  /// it already told, show their score and events, a moment later.
  void keyed(int tick) => scheduleMicrotask(() {
    if (!ref.mounted) return;
    final i = _untold.indexWhere((u) => u.$1.tick == tick);
    if (i >= 0) _untold[i] = (_untold[i].$1, true);
    state = _told(state);
  });

  LiveMatchState _told(LiveMatchState st) {
    var score = st.score;
    final told = <MatchEvent>[];
    while (_untold.isNotEmpty && _untold.first.$2) {
      final t = _untold.removeAt(0).$1;
      score = t.score;
      told.insertAll(0, t.events.reversed);
    }
    if (told.isEmpty && score == st.score) return st;
    final feed = [...told, ...st.feed];
    if (feed.length > 200) feed.removeRange(200, feed.length);
    return st.copyWith(score: score, feed: feed);
  }
}

final liveMatchProvider = NotifierProvider.autoDispose.family<LiveMatch, LiveMatchState, int>(LiveMatch.new);
