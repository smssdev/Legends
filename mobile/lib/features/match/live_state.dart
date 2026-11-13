part of 'live_screen.dart';

class _LiveState extends ConsumerState<_Live> with WidgetsBindingObserver {
  late final MatchRepository _repo = ref.read(matchRepositoryProvider);
  late (int, int) _score = widget.view.score;
  late Map<String, MatchTeam> _teams = widget.view.teams;
  late bool _finished = widget.view.finished;
  final List<LiveTick> _recent = [];
  final List<MatchEvent> _feed = [];
  List<String> _readings = const [];
  List<({int id, String who, String body, String? side})> _chat = const [];
  List<({int id, String who, String key, String? target})> _reactions = const [];
  MatchPause? _pause;
  int _tick = 0, _offset = 0, _minute = 0, _added = 0;
  bool _started = false, _busy = false;

  /// [Sprint 50 M14, M15] The momentum wave (each minute's danger, the home side's share), and the timeout held.
  final List<int> _wave = [];
  int? _homePct;
  int? _timeoutUntil;
  late bool _timeoutUsed = widget.view.you != null && widget.view.timeoutsUsed.contains(widget.view.you);

  /// [Sprint 44 C1] The broadcast: the minutes waiting for their scene, and the minutes not yet told (in order), whose
  /// score and events show when their scene reaches its key moment, so the result never comes before the ball.
  final List<BroadcastPlay> _plays = [];
  final List<(LiveTick, bool)> _untold = [];
  bool _synced = false;
  Timer? _timer;

  /// [Sprint 51 F2] The timeout bar's end, cancelled with the screen.
  Timer? _timeoutEnd;

  /// [Sprint 53 F2] The match's channel: the minutes, the chat and the reactions pushed. While it is subscribed the poll
  /// only checks now and then (every [_pushedPollMs], or [_breakPollMs] in a break, for who is ready); without it the
  /// poll runs as before.
  LiveSubscription? _channel;
  static const _pushedPollMs = 12000, _breakPollMs = 2000;

  int get _id => widget.view.id;
  String? get _you => widget.view.you;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _poll();
    if (!widget.view.finished) {
      _channel = ref.read(liveFeedProvider).join('match.$_id', {'minute': _pushed, 'chat': _pushedChat, 'reaction': _pushedReaction});
      _channel!.subscribed.addListener(_channelChanged);
    }
  }

  /// The channel came (ask once for what it may have missed) or went (back to the poll's own pace at once).
  void _channelChanged() {
    if (!mounted || _finished) return;
    _timer?.cancel();
    _poll();
  }

  /// [Sprint 53 F2] A minute pushed whole (App\Events\MatchMinute's `live`): told as if the poll had brought it.
  void _pushed(Map<String, dynamic> e) {
    // [Sprint 59 F1] The event's minute through its generated model (`LiveMinute`); one that does not read is left to the poll.
    final r = JsonReader(e, 'MatchMinute');
    final live = r.objectOrNull('live', api.LiveMinute.fromJson);
    if (!mounted || _finished || live == null) return;
    final t = LiveTick.of(live);
    if (t.tick <= _tick) return;
    // A minute missing in between (a message lost): the poll brings everything after the last one told.
    if (t.tick > _tick + 1) {
      _timer?.cancel();
      _poll();
      return;
    }
    setState(
      () => _apply(
        LiveSync(
          finished: t.finished,
          tick: t.tick,
          serverNow: DateTime.now().millisecondsSinceEpoch + _offset,
          nextAt: r.intOrNull('next_at'),
          ticks: [t],
          pause: _pause,
          chat: _chat,
          reactions: _reactions,
        ),
      ),
    );
    // A break opens or the match ends: the details (who is ready, the window) from the poll, now.
    if (t.window || t.finished || t.period != null && t.events.any((x) => x.type == 'period')) {
      _timer?.cancel();
      _poll();
    }
  }

  void _pushedChat(Map<String, dynamic> e) {
    final c = JsonReader(e, 'MatchSocialPosted').objectOrNull('item', api.BroadcastChat.fromJson);
    if (!mounted || c == null || _chat.any((x) => x.id == c.id)) return;
    setState(() => _chat = [..._chat, LiveSync.chatOf(c)].take(50).toList());
  }

  void _pushedReaction(Map<String, dynamic> e) {
    final r = JsonReader(e, 'MatchSocialPosted').objectOrNull('item', api.BroadcastReaction.fromJson);
    if (!mounted || r == null || _reactions.any((x) => x.id == r.id)) return;
    setState(() => _reactions = [..._reactions, LiveSync.reactionOf(r)]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timeoutEnd?.cancel();
    _channel?.subscribed.removeListener(_channelChanged);
    _channel?.leave();
    unawaited(WakelockPlus.disable().catchError((_) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background: straight to now (the server sends what was missed).
    if (state == AppLifecycleState.resumed && !_finished) {
      _timer?.cancel();
      _poll();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  Future<void> _poll() async {
    var wait = 1500;
    try {
      final s = await _repo.live(_id, _tick);
      if (!mounted) return;
      setState(() => _apply(s));
      wait = s.pollMs ?? wait;
      // [Sprint 53 F2] On the channel the minutes come by themselves.
      if (_channel?.subscribed.value == true && _started) {
        wait = wait > (_pause != null ? _breakPollMs : _pushedPollMs) ? wait : (_pause != null ? _breakPollMs : _pushedPollMs);
      }
    } on ApiError {
      wait = 4000;
    } catch (_) {
      // [2026-11-09] Any other failure (a field the app did not expect) must not stop the match: try again shortly.
      wait = 4000;
    }
    if (mounted && !_finished) _timer = Timer(Duration(milliseconds: wait), _poll);
  }

  void _apply(LiveSync s) {
    _offset = s.serverNow - DateTime.now().millisecondsSinceEpoch;
    _pause = s.pause;
    if (s.readings.isNotEmpty) _readings = s.readings;
    _chat = s.chat;
    _reactions = s.reactions;
    // A gap (a locked phone, a lost connection): the events of the minutes missed, then the minutes themselves.
    _feed.insertAll(0, s.missed.reversed);
    for (final t in s.ticks) {
      if (t.tick <= _tick) continue;
      _tick = t.tick;
      _started = true;
      _minute = t.minute;
      _added = t.added;
      if (t.teams != null) _teams = t.teams!;
      _wave.add(t.momentumNow);
      if (_wave.length > 30) _wave.removeAt(0);
      if (t.momentumPct != null) _homePct = t.momentumPct;
      _recent.add(t);
      // A minute with a scene waits for it (not the minutes already played when the page opened); the rest is told
      // in its turn.
      final story = _synced ? _story(t) : null;
      if (story?.scene != null) {
        _plays.add(
          BroadcastPlay.of(
            t.tick,
            story!,
            total: (t.moment?.ms ?? widget.view.tickMs) / 1000,
            moods: t.moods,
            tier: Tier.high,
            seed: widget.view.seed ?? 1,
          ),
        );
        _untold.add((t, false));
      } else {
        _untold.add((t, true));
      }
      if (t.finished) _finished = true;
    }
    _synced = true;
    _tell();
    if (_recent.length > 3) _recent.removeRange(0, _recent.length - 3);
    if (s.finished) _finished = true;
    if (_feed.length > 200) _feed.removeRange(200, _feed.length);
  }

  /// The minute's story for the broadcast (feed/story.dart): the names, numbers and clubs as this match has them.
  FeedStory _story(LiveTick t) {
    final v = widget.view;
    return feedStory(
      t,
      cast: {
        for (final side in ['home', 'away'])
          for (final p in (t.teams ?? _teams)[side]!.players) '${p.id}': (name: p.name, no: p.no, side: side),
      },
      clubs: {'home': v.home.name, 'away': v.away.name},
      ar: Localizations.localeOf(context).languageCode == 'ar',
    );
  }

  /// A minute's key moment has come: it, and every minute after it already told, show their score and events.
  void _keyed(int tick) {
    final i = _untold.indexWhere((u) => u.$1.tick == tick);
    if (i >= 0) _untold[i] = (_untold[i].$1, true);
    _tell();
    if (mounted) setState(() {});
  }

  void _tell() {
    while (_untold.isNotEmpty && _untold.first.$2) {
      final t = _untold.removeAt(0).$1;
      _score = t.score;
      _feed.insertAll(0, t.events.reversed);
    }
  }

  /// [Sprint 59 F5] An order through LiveOrders (its key kept for a retry), and the screen says how it went.
  Future<void> _order(Future<bool> Function(LiveOrders orders) send) async {
    final orders = ref.read(liveOrdersProvider(_id).notifier);
    final ok = await send(orders);
    if (!mounted) return;
    final error = ref.read(liveOrdersProvider(_id)).error;
    if (ok) {
      showGlmToast(context, L.of(context).orderSent);
    } else if (error != null) {
      showGlmToast(context, error, error: true);
    }
  }

  Future<void> _send(Future<void> Function() order, {bool quiet = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await order();
      if (mounted && !quiet) showGlmToast(context, L.of(context).orderSent);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final v = widget.view;
    // LiveOrders lives while the screen is open.
    ref.watch(liveOrdersProvider(_id));
    final kits = matchKits(v);
    final numbers = {
      for (final side in ['home', 'away'])
        for (final p in _teams[side]!.players) '${p.id}': (side, p.no),
    };
    return Scaffold(
      appBar: GameBar(title: Text(_finished ? l.fullTime : l.liveNow)),
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(
          builder: (context, box) {
            final bug = _ScoreBug(
              view: v,
              score: _score,
              minute: _started ? (_added > 0 ? "$_minute+$_added'" : "$_minute'") : null,
              finished: _finished,
            );
            final light = LivePitch(ticks: List.of(_recent), tickMs: v.tickMs, serverOffset: _offset, kits: kits, numbers: numbers);
            // [Sprint 44] The broadcast over the pitch: each moment's cartoon scene, the director's cutaways, the studio
            // before kick-off.
            final pitch = AspectRatio(
              aspectRatio: 105 / 68,
              child: BroadcastStage(
                look: _clipLook(context, kits),
                queue: _plays,
                onKey: _keyed,
                studio: _started || _finished ? null : (score: '${_score.$1} - ${_score.$2}', clock: L.of(context).notStarted),
                child: light,
              ),
            );
            final controls = <Widget>[
              if (_timeoutUntil != null && _timeoutUntil! > DateTime.now().millisecondsSinceEpoch + _offset && !_finished) _timeoutBar(l),
              if (_pause != null && _you != null && !_finished) _breakBar(l),
              if (_you != null && !_finished) _coachBar(l),
              if (_finished)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: GlmButton(
                    label: l.matchReport,
                    variant: GlmButtonVariant.brand,
                    block: true,
                    onPressed: () => context.push('/match/$_id/report?coach=${_you != null}'),
                  ),
                ),
              if (!_finished && _started) _socialBar(l),
            ];
            // [2026-11-06] Landscape, as a broadcast: the score and the pitch filling one side, the coach's controls and
            // the commentary on the other.
            if (box.maxWidth > box.maxHeight) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        bug,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                            child: Center(child: pitch),
                          ),
                        ),
                        if (_started && _wave.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: _MomentumStrip(wave: _wave, homePct: _homePct, view: v),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        ...controls,
                        Expanded(child: _feedList(l)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                bug,
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: pitch),
                ...controls,
                Expanded(child: _feedList(l)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// [X24] Reactions on every viewer's screen, and the side chat between the league's viewers.
  static const reactions = {
    'fire': '🔥',
    'clap': '👏',
    'wow': '😱',
    'laugh': '😂',
    'angry': '😤',
    'pray': '🤲',
    'unlucky': '😅',
    'coming': '⚽',
    'easy': '😎',
    'focus': '🧠',
    'cheer': '📣',
    'boo': '👎',
  };

  Widget _breakBar(L l) {
    final ready = _pause!.ready.contains(_you);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: GlmCard(
        gold: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.pause_circle_rounded, color: context.palette.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_pause!.window ? l.windowOpen : l.breakTime, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ready
                ? Text(l.readyWaiting, style: TextStyle(color: context.palette.textMuted, fontSize: 12))
                : GlmButton(
                    label: l.imReady,
                    onPressed: _busy
                        ? null
                        : () {
                            unawaited(GameSounds.play(Sfx.whistle));
                            _send(() => _repo.ready(_id));
                          },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeTimeout() async {
    setState(() => _busy = true);
    try {
      final until = await ref.read(consoleRepositoryProvider).timeout(_id);
      unawaited(GameSounds.play(Sfx.whistle));
      if (!mounted) return;
      setState(() {
        _timeoutUntil = until;
        _timeoutUsed = true;
      });
      // The bar goes when play goes on.
      _timeoutEnd?.cancel();
      _timeoutEnd = Timer(Duration(milliseconds: (until - DateTime.now().millisecondsSinceEpoch - _offset).clamp(0, 600000)), () {
        if (mounted) setState(() {});
      });
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
      if (mounted) setState(() => _timeoutUsed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _timeoutBar(L l) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: GlmCard(
      gold: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: context.palette.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.timeoutTaken, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );

  Widget _coachBar(L l) {
    // An order in flight keeps the buttons still.
    final busy = _busy || ref.watch(liveOrdersProvider(_id)).busy;
    final team = _teams[_you]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          for (final (icon, label, onTap) in [
            (Icons.swap_vert_rounded, '${l.substitute} ${team.subsMax - team.subsUsed}', busy ? null : _subSheet),
            (Icons.tune_rounded, l.tactics, busy ? null : _tacticsSheet),
            (Icons.grid_view_rounded, l.formation, busy || widget.view.formations.isEmpty ? null : _formationSheet),
            // [Sprint 50 M14] The one timeout: play waits, the changes open for both coaches.
            (Icons.timer_rounded, _timeoutUsed ? l.timeoutUsed : l.timeout, _busy || _timeoutUsed || !_started ? null : _takeTimeout),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GlmCard(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  onTap: onTap,
                  child: Column(
                    children: [
                      Icon(icon, color: onTap == null ? context.palette.textMuted : context.palette.gold),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
