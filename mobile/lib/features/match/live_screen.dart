import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import 'live_pitch.dart';
import 'match_data.dart';

/// [Sprint 17 F2] The live match in the app (the web's /live/{id}): the score bug, the light pitch, the commentary
/// line by line from the server (`text`), and for a coach of either side his orders (a substitution, the tactics or
/// the shape, in the windows) and «أنا مستعد» in a break. It follows the server's minutes (`live?since=`), comes back
/// to now after the phone was locked, and keeps the screen on while it plays.
class LiveMatchScreen extends ConsumerWidget {
  const LiveMatchScreen({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(matchProvider(matchId));
    if (value.value case final m?) return _Live(view: m);
    return Scaffold(
      appBar: AppBar(),
      body: GlmBackground(child: AsyncView(value: value, onRetry: () => ref.invalidate(matchProvider(matchId)), data: (_) => const SizedBox())),
    );
  }
}

class _Live extends ConsumerStatefulWidget {
  const _Live({required this.view});

  final MatchView view;

  @override
  ConsumerState<_Live> createState() => _LiveState();
}

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
  Timer? _timer;

  int get _id => widget.view.id;
  String? get _you => widget.view.you;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _poll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
    } on ApiError {
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
      _score = t.score;
      _minute = t.minute;
      _added = t.added;
      if (t.teams != null) _teams = t.teams!;
      _feed.insertAll(0, t.events.reversed);
      _recent.add(t);
      if (t.finished) _finished = true;
    }
    if (_recent.length > 3) _recent.removeRange(0, _recent.length - 3);
    if (s.finished) _finished = true;
    if (_feed.length > 200) _feed.removeRange(200, _feed.length);
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
    final kits = matchKits(v);
    final numbers = {
      for (final side in ['home', 'away'])
        for (final p in _teams[side]!.players) '${p.id}': (side, p.no),
    };
    return Scaffold(
      appBar: AppBar(title: Text(_finished ? l.fullTime : l.liveNow)),
      body: GlmBackground(
        wide: true,
        child: LayoutBuilder(builder: (context, box) {
          final bug = _ScoreBug(view: v, score: _score, minute: _started ? (_added > 0 ? "$_minute+$_added'" : "$_minute'") : null, finished: _finished);
          final pitch = LivePitch(ticks: List.of(_recent), tickMs: v.tickMs, serverOffset: _offset, kits: kits, numbers: numbers);
          final controls = <Widget>[
            if (_pause != null && _you != null && !_finished) _breakBar(l),
            if (_you != null && !_finished) _coachBar(l),
            if (_finished)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: GlmButton(label: l.matchReport, variant: GlmButtonVariant.brand, block: true, onPressed: () => context.push('/match/$_id/report?coach=${_you != null}')),
              ),
            if (!_finished && _started) _socialBar(l),
          ];
          // [2026-11-06] Landscape, as a broadcast: the score and the pitch filling one side, the coach's controls and
          // the commentary on the other.
          if (box.maxWidth > box.maxHeight) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 6,
                child: Column(children: [
                  bug,
                  Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Center(child: pitch))),
                ]),
              ),
              Expanded(
                flex: 5,
                child: Column(children: [...controls, Expanded(child: _feedList(l))]),
              ),
            ]);
          }
          return Column(children: [
            bug,
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: pitch),
            ...controls,
            Expanded(child: _feedList(l)),
          ]);
        }),
      ),
    );
  }

  /// [X24] Reactions on every viewer's screen, and the side chat between the league's viewers.
  static const reactions = {
    'fire': '🔥', 'clap': '👏', 'wow': '😱', 'laugh': '😂', 'angry': '😤', 'pray': '🤲', 'unlucky': '😅', 'coming': '⚽', 'easy': '😎', 'focus': '🧠', 'cheer': '📣', 'boo': '👎',
  };

  Widget _socialBar(L l) {
    final p = context.palette;
    final latest = _reactions.reversed.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(children: [
        if (latest.isNotEmpty)
          Text(latest.map((r) => '${reactions[r.key] ?? ''} ${r.who}').join('   '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.textMuted, fontSize: 12)),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            ActionChip(avatar: const Icon(Icons.chat_bubble_rounded, size: 18), label: Text('${l.matchChat} ${_chat.length}'), onPressed: _chatSheet),
            const SizedBox(width: 6),
            for (final e in reactions.entries)
              if (e.key != 'cheer' && e.key != 'boo')
                IconButton(
                  tooltip: e.key,
                  onPressed: () => _send(() => _repo.react(_id, e.key), quiet: true),
                  icon: Text(e.value, style: const TextStyle(fontSize: 22)),
                ),
            for (final side in ['home', 'away']) ...[
              IconButton(tooltip: 'cheer $side', onPressed: () => _send(() => _repo.react(_id, 'cheer', target: side), quiet: true), icon: Text('📣${widget.view.club(side).code}', style: const TextStyle(fontSize: 14))),
              IconButton(tooltip: 'boo $side', onPressed: () => _send(() => _repo.react(_id, 'boo', target: side), quiet: true), icon: Text('👎${widget.view.club(side).code}', style: const TextStyle(fontSize: 14))),
            ],
          ]),
        ),
      ]),
    );
  }

  Future<void> _chatSheet() async {
    final l = L.of(context);
    final text = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .6,
            child: Column(children: [
              Expanded(
                child: ListView(reverse: true, padding: const EdgeInsets.all(12), children: [
                  for (final c in _chat.reversed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${c.who}: ', style: TextStyle(fontWeight: FontWeight.w800, color: ctx.glm.goldText)),
                        TextSpan(text: c.body),
                      ])),
                    ),
                ]),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Expanded(child: TextField(controller: text, maxLength: 140, decoration: InputDecoration(hintText: l.typeMessage, counterText: ''))),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: ctx.palette.gold),
                      onPressed: () async {
                        final body = text.text.trim();
                        if (body.isEmpty) return;
                        text.clear();
                        await _send(() => _repo.say(_id, body), quiet: true);
                        _timer?.cancel();
                        await _poll();
                        set(() {});
                      },
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    text.dispose();
  }

  Widget _breakBar(L l) {
    final ready = _pause!.ready.contains(_you);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: GlmCard(
        gold: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(Icons.pause_circle_rounded, color: context.palette.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(_pause!.window ? l.windowOpen : l.breakTime, style: const TextStyle(fontWeight: FontWeight.w700))),
          ready
              ? Text(l.readyWaiting, style: TextStyle(color: context.palette.textMuted, fontSize: 12))
              : GlmButton(label: l.imReady, onPressed: _busy ? null : () => _send(() => _repo.ready(_id))),
        ]),
      ),
    );
  }

  Widget _coachBar(L l) {
    final team = _teams[_you]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(children: [
        for (final (icon, label, onTap) in [
          (Icons.swap_vert_rounded, '${l.substitute} ${team.subsMax - team.subsUsed}', _busy ? null : _subSheet),
          (Icons.tune_rounded, l.tactics, _busy ? null : _tacticsSheet),
          (Icons.grid_view_rounded, l.formation, _busy || widget.view.formations.isEmpty ? null : _formationSheet),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GlmCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                onTap: onTap,
                child: Column(children: [
                  Icon(icon, color: onTap == null ? context.palette.textMuted : context.palette.gold),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _feedList(L l) {
    final p = context.palette;
    if (_feed.isEmpty && _readings.isEmpty) {
      final at = widget.view.kickoffAt;
      return Center(child: Text(_started || at == null ? l.commentary : l.notStarted, style: TextStyle(color: p.textMuted)));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), children: [
      if (_readings.isNotEmpty)
        GlmCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.assistantNotes, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final r in _readings.reversed.take(3)) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r)),
          ]),
        ),
      if (_readings.isNotEmpty) const SizedBox(height: 10),
      for (final e in _feed)
        if (e.text != null && e.text!.isNotEmpty) EventLine(e),
    ]);
  }

  Future<void> _subSheet() async {
    final l = L.of(context);
    final team = _teams[_you]!;
    MatchPlayer? out, into;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Widget pick(String title, List<MatchPlayer> list, MatchPlayer? sel, void Function(MatchPlayer) on) => Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(title, textAlign: TextAlign.center, style: context.text.titleSmall),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(children: [
                      for (final p in list)
                        ListTile(
                          dense: true,
                          selected: sel?.id == p.id,
                          selectedTileColor: ctx.palette.gold.withValues(alpha: .18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
                          subtitle: Text('${p.pos} · ${p.fit}%', textDirection: TextDirection.ltr),
                          onTap: () => set(() => on(p)),
                        ),
                    ]),
                  ),
                ]),
              );
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * .7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: [
                Text(l.subsLeft(team.subsUsed, team.subsMax), style: TextStyle(color: ctx.palette.textMuted)),
                const SizedBox(height: 4),
                Text(l.ordersHint, textAlign: TextAlign.center, style: TextStyle(color: ctx.palette.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  pick(l.subOut, team.onPitch, out, (p) => out = p),
                  const SizedBox(width: 8),
                  pick(l.subIn, team.bench, into, (p) => into = p),
                ])),
                GlmButton(
                  label: l.send,
                  block: true,
                  onPressed: out == null || into == null
                      ? null
                      : () {
                          final o = out!.id, i = into!.id;
                          Navigator.pop(ctx);
                          _send(() => _repo.sub(_id, o, i));
                        },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _tacticsSheet() async {
    final l = L.of(context);
    final current = Map<String, Object>.from(_teams[_you]!.tactics ?? const {});
    final changes = <String, Object>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Object? val(String k) => changes[k] ?? current[k];
        Widget chips<T extends Object>(String title, String key, Map<T, String> options) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(title, style: ctx.text.titleSmall),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final o in options.entries)
                    ChoiceChip(label: Text(o.value), selected: val(key) == o.key, selectedColor: ctx.palette.gold.withValues(alpha: .28), onSelected: (_) => set(() => changes[key] = o.key)),
                ]),
              ]),
            );
        Widget slider(String title, String key) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Text(title, style: ctx.text.titleSmall), const Spacer(), Text('${(val(key) as num? ?? 50).round()}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: ctx.glm.goldText))]),
              Slider(value: (val(key) as num? ?? 50).toDouble(), min: 0, max: 100, divisions: 20, activeColor: ctx.palette.gold, onChanged: (v) => set(() => changes[key] = v.round())),
            ]);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * .75,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
              Text(l.ordersHint, textAlign: TextAlign.center, style: TextStyle(color: ctx.palette.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              chips(l.plan, 'plan', {'passing': l.planPassing, 'counter': l.planCounter, 'long': l.planLong, 'wings': l.planWings, 'shots': l.planShots}),
              slider(l.pressing, 'pressing'),
              slider(l.style, 'style'),
              slider(l.tempo, 'tempo'),
              chips(l.tackling, 'tackling', {0: l.tackle0, 1: l.tackle1, 2: l.tackle2, 3: l.tackle3}),
              chips(l.lineAtt, 'att', {'back': l.attBack, 'support': l.attSupport, 'only': l.attOnly}),
              chips(l.lineMid, 'mid', {'def': l.midDef, 'stay': l.midStay, 'push': l.midPush}),
              chips(l.lineDef, 'def', {'stay': l.defStay, 'fullbacks': l.defFullbacks, 'mid': l.defMid}),
              chips(l.marking, 'marking', {'zone': l.markZone, 'man': l.markMan}),
              const SizedBox(height: 6),
              GlmButton(
                label: l.send,
                block: true,
                onPressed: changes.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _send(() => _repo.tactics(_id, Map.of(changes)));
                      },
              ),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _formationSheet() async {
    final now = _teams[_you]!.formation;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final f in widget.view.formations)
            ListTile(
              title: Text(f.startsWith('custom:') ? f : f, textDirection: TextDirection.ltr),
              trailing: f == now ? Icon(Icons.check_rounded, color: ctx.palette.gold) : null,
              onTap: () => Navigator.pop(ctx, f),
            ),
        ]),
      ),
    );
    if (picked != null && picked != now) await _send(() => _repo.formation(_id, picked));
  }
}

/// The score bug: home on the right in Arabic (tokens.json match.homeSide), the minute or «نهاية المباراة» below.
/// The score bar, as on a TV broadcast: each side in its kit's colour (the change kit on a clash), the score between them
/// on a dark plate, and the minute (red while it plays) or «full time» under it. Home on the right in Arabic.
class _ScoreBug extends StatelessWidget {
  const _ScoreBug({required this.view, required this.score, this.minute, required this.finished});

  final MatchView view;
  final (int, int) score;
  final String? minute;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final kits = matchKits(view);
    Widget side(MatchClub c, String key) {
      final (shirt, ink) = kits[key]!;
      final mine = view.you == key;
      return Expanded(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(shirt, Colors.white, .12)!, shirt]),
            borderRadius: BorderRadius.circular(14),
            border: mine ? Border.all(color: p.gold, width: 2) : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(c.code, style: TextStyle(fontFamily: GlmFonts.numbers, color: ink, fontWeight: FontWeight.w800, fontSize: 24, height: 1, letterSpacing: 1)),
            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                style: TextStyle(color: ink.withValues(alpha: .85), fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(children: [
        side(view.home, 'home'),
        const SizedBox(width: 6),
        Container(
          width: 108,
          height: 64,
          decoration: BoxDecoration(color: p.bgDeep, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .08))),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${score.$1} - ${score.$2}', textDirection: TextDirection.ltr,
                style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 32, fontWeight: FontWeight.w800, color: p.text, height: 1)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(color: finished ? p.surfaceRaised : p.danger, borderRadius: BorderRadius.circular(99)),
              child: Text(finished ? l.fullTime : (minute ?? l.notStarted), textDirection: TextDirection.ltr,
                  style: TextStyle(color: finished ? p.text : Colors.white, fontWeight: FontWeight.w800, fontSize: 11, fontFamilyFallback: const [GlmFonts.body])),
            ),
          ]),
          ),
        ),
        const SizedBox(width: 6),
        side(view.away, 'away'),
      ]),
    );
  }
}

/// One line of commentary: the minute, a mark for its kind, and the server's sentence.
class EventLine extends StatelessWidget {
  const EventLine(this.e, {super.key});

  final MatchEvent e;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = switch (e.type) {
      'goal' => '⚽',
      'card' => e.color == 'red' ? '🟥' : '🟨',
      'sub' => '🔁',
      'injury' => '🩹',
      'penalty' => '🎯',
      'corner' => '⛳',
      'period' => '⏱',
      _ => '•',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: e.type == 'goal' ? p.gold.withValues(alpha: .16) : p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: e.type == 'goal' ? p.gold.withValues(alpha: .5) : p.surfaceRaised),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 44, child: Text(e.clock, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText))),
        Text(icon),
        const SizedBox(width: 8),
        Expanded(child: Text(e.text ?? '', style: TextStyle(fontWeight: e.big ? FontWeight.w800 : FontWeight.w500))),
      ]),
    );
  }
}
