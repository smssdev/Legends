part of 'live_screen.dart';

class _LiveState extends ConsumerState<_Live> with WidgetsBindingObserver {
  late final MatchRepository _repo = ref.read(matchSourceProvider(widget.view.id));
  bool _busy = false;

  /// [Sprint 63 G2] The curtain over the match, and whether it has closed (the screen may go).
  final _curtain = GlobalKey<MatchCurtainState>();
  bool _leaving = false;

  /// [Sprint 61 F4] The match as it goes lives in LiveMatch (live_controller.dart): each part of the screen watches its
  /// own of it (`select`), and the screen only what changes its shape. These read it as it is now.
  LiveMatchState get _s => ref.read(liveMatchProvider(_id));
  LiveMatch get _live => ref.read(liveMatchProvider(_id).notifier);
  Map<String, MatchTeam> get _teams => _s.teams;
  bool get _finished => _s.finished;
  bool get _started => _s.started;
  List<MatchEvent> get _feed => _s.feed;
  List<String> get _readings => _s.readings;
  List<({int id, String who, String body, String? side})> get _chat => _s.chat;
  List<({int id, String who, String key, String? target})> get _reactions => _s.reactions;
  MatchPause? get _pause => _s.pause;
  int get _offset => _s.offset;
  List<int> get _wave => _s.wave;
  int? get _homePct => _s.homePct;

  /// [Sprint 60 F6] The drawer open over the picture on a landscape screen: 'orders', 'chat' or none.
  String? _drawer;

  void _openDrawer(String? d) => setState(() => _drawer = d);

  /// [Sprint 64 F7] The orders drawer was opened by a window (so its end closes it).
  bool _openedByWindow = false;

  /// [Sprint 50 M14] The timeout held.
  int? _timeoutUntil;
  late bool _timeoutUsed = widget.view.you != null && widget.view.timeoutsUsed.contains(widget.view.you);

  /// [Sprint 51 F2] The timeout bar's end, cancelled with the screen.
  Timer? _timeoutEnd;

  int get _id => widget.view.id;
  String? get _you => widget.view.you;

  /// [Sprint 61 F10] A simulator match (SimMatches): no league channel, timeout, side chat, break or report.
  bool get _sim => _id < 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable().catchError((_) {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _live.ar = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeoutEnd?.cancel();
    unawaited(WakelockPlus.disable().catchError((_) {}));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background: straight to now (the server sends what was missed).
    if (state == AppLifecycleState.resumed) {
      unawaited(_live.now());
    } else if (state == AppLifecycleState.paused) {
      _live.hold();
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
    // [Sprint 61 F4] The screen itself rebuilds only when its shape changes (the start, a break, the end); the score,
    // the pitch, the feed and the wave each watch their own below.
    ref.watch(liveMatchProvider(_id).select((s) => (s.started, s.finished, s.pause)));
    // [Sprint 64 F7] A coach's window opens his orders by itself (its countdown in the break bar), and its end closes
    // them, if it was the window that opened them.
    ref.listen(liveMatchProvider(_id).select((s) => s.pause?.window ?? false), (was, on) {
      if (_you == null || _sim || _finished || was == on) return;
      if (on && _drawer != 'orders') {
        _openedByWindow = true;
        _openDrawer('orders');
      } else if (!on && _openedByWindow) {
        _openedByWindow = false;
        if (_drawer == 'orders') _openDrawer(null);
      }
    });
    final kits = matchKits(v);
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    // [Sprint 63 G2] Into the pitch's world and out of it: a curtain in the two shirts, parting as the match shows, and
    // shut before the screen goes back.
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _curtain.currentState?.close();
        if (!mounted) return;
        setState(() => _leaving = true);
        nav.pop();
      },
      child: Stack(
        children: [
          Scaffold(
            // [Sprint 72 R5] The picture keeps its size under the keyboard (the chat's sheet sits above it by itself).
            resizeToAvoidBottomInset: false,
            // [Sprint 60 F6] On a landscape screen the picture has no frame (the draft's «bare» screen).
            appBar: landscape ? null : GameBar(title: Text(_finished ? l.fullTime : l.liveNow)),
            body: GlmBackground(
              wide: true,
              child: LayoutBuilder(
                builder: (context, box) {
                  Widget bug({bool compact = false}) => Consumer(
                    builder: (context, ref, _) {
                      final s = ref.watch(liveMatchProvider(_id).select((s) => (s.score, s.clock, s.finished)));
                      return _ScoreBug(view: v, score: s.$1, minute: s.$2, finished: s.$3, compact: compact);
                    },
                  );
                  // [Sprint 44] The broadcast over the pitch: each moment's cartoon scene, the director's cutaways, the studio
                  // before kick-off. It rebuilds with the minutes (the light pitch) and the scenes queued.
                  final pitch = AspectRatio(
                    aspectRatio: 105 / 68,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final s = ref.watch(liveMatchProvider(_id).select((s) => (s.recent, s.playsVersion, s.offset, s.teams)));
                        final st = ref.read(liveMatchProvider(_id));
                        final numbers = {
                          for (final side in ['home', 'away'])
                            for (final p in s.$4[side]!.players) '${p.id}': (side, p.no),
                        };
                        return BroadcastStage(
                          look: _clipLook(context, kits),
                          queue: _live.plays,
                          onKey: _live.keyed,
                          studio: st.started || st.finished
                              ? null
                              : (score: '${st.score.$1} - ${st.score.$2}', clock: L.of(context).notStarted),
                          child: LivePitch(ticks: List.of(s.$1), tickMs: v.tickMs, serverOffset: s.$3, kits: kits, numbers: numbers),
                        );
                      },
                    ),
                  );
                  final controls = <Widget>[
                    if (_timeoutUntil != null && _timeoutUntil! > DateTime.now().millisecondsSinceEpoch + _offset && !_finished)
                      _timeoutBar(l),
                    if (_pause != null && _you != null && !_finished && !_sim) _breakBar(l),
                    if (_you != null && !_finished) _watch((s) => s.teams, () => _coachBar(l)),
                    if (_finished) Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: _endButton(l)),
                    if (!_finished && _started) _watch((s) => (s.chat, s.reactions), () => _socialBar(l)),
                  ];
                  if (box.maxWidth > box.maxHeight) {
                    return _broadcast(l, pitch, bug(compact: true));
                  }
                  return Column(
                    children: [
                      bug(),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: pitch),
                      ...controls,
                      Expanded(child: _watch((s) => (s.feed, s.readings), () => _feedList(l))),
                    ],
                  );
                },
              ),
            ),
          ),
          // [Sprint 64 F6] A league match before its whistle: the waiting room, gone by itself at kick-off.
          if (!_sim && !_started && !_finished && (widget.view.kickoffAt?.isAfter(DateTime.now()) ?? false))
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(GlmSpace.md),
                  child: WaitingRoom(view: widget.view, onChat: () => _openDrawer('chat')),
                ),
              ),
            ),
          // [Sprint 64 F1] The intro match's assistant (nothing for any other match).
          if (_sim)
            Positioned.fill(
              child: SafeArea(
                child: IntroCoachOverlay(handle: _id, onOrders: () => _openDrawer('orders')),
              ),
            ),
          Positioned.fill(
            child: MatchCurtain(key: _curtain, home: kits['home']!.$1, away: kits['away']!.$1),
          ),
        ],
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

  /// [Sprint 61 F4] A part of the screen rebuilt only when its [slice] of the match changes.
  Widget _watch(Object? Function(LiveMatchState s) slice, Widget Function() build) => Consumer(
    builder: (context, ref, _) {
      ref.watch(liveMatchProvider(_id).select(slice));
      return build();
    },
  );

  /// At the end: the report of a league match; a sim match goes back to the simulator.
  Widget _endButton(L l) => GlmButton(
    label: _sim ? l.close : l.matchReport,
    variant: GlmButtonVariant.brand,
    block: true,
    onPressed: _sim ? () => Navigator.of(context).maybePop() : () => context.push('/match/$_id/report?coach=${_you != null}'),
  );

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
                ? Text(l.readyWaiting, style: glmText(GlmType.caption, color: context.palette.textMuted))
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
      // [Sprint 60 F8] Each command's name whole on two lines if need be, the four cards one height.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (icon, label, onTap) in [
              (Icons.swap_vert_rounded, '${l.substitute} ${team.subsMax - team.subsUsed}', busy ? null : _subSheet),
              (Icons.tune_rounded, l.tactics, busy ? null : _tacticsSheet),
              (Icons.grid_view_rounded, l.formation, busy || widget.view.formations.isEmpty ? null : _formationSheet),
              // [Sprint 50 M14] The one timeout: play waits, the changes open for both coaches.
              if (!_sim)
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
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: glmText(GlmType.caption, fontWeight: FontWeight.w800, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
