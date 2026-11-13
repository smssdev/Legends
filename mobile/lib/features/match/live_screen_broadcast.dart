part of 'live_screen.dart';

/// [Sprint 60 F6] The live match on a landscape screen as the approved draft draws it (docs/design/legends-ui/landscape/
/// Match.html): the picture fills the screen with no frame, so each moment's clip plays full screen; the score once at
/// its top; two drawers on the edges that come in over the picture without moving it, the orders at the end and the
/// chat at the start; leaving is a small button in the corner; the last event a line at the foot.
extension _LiveBroadcast on _LiveState {
  static const _chatWidth = 340.0, _ordersWidth = 300.0;

  Widget _broadcast(L l, Widget pitch, Widget bug) {
    final coach = _you != null && !_finished;
    final last = _feed.where((e) => e.text != null && e.text!.isNotEmpty).firstOrNull;
    final urgent = <Widget>[
      if (_timeoutUntil != null && _timeoutUntil! > DateTime.now().millisecondsSinceEpoch + _offset && !_finished) _timeoutBar(l),
      if (_pause != null && _you != null && !_finished && !_sim) _breakBar(l),
      if (_finished) Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: _endButton(l)),
    ];
    return ColoredBox(
      color: GlmBroadcast.tvDeep,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(GlmSpace.xs),
                child: Center(child: pitch),
              ),
            ),
            Positioned(
              top: GlmSpace.xs,
              left: 0,
              right: 0,
              child: Center(child: bug),
            ),
            PositionedDirectional(
              top: GlmSpace.xs,
              start: GlmSpace.xs,
              child: _roundButton(Icons.close_rounded, l.close, () => Navigator.of(context).maybePop()),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Center(child: _edge(Icons.forum_rounded, l.matchChat, 'chat', start: true, dot: _chat.isNotEmpty)),
            ),
            if (coach)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                child: Center(child: _edge(Icons.tune_rounded, l.liveOrders, 'orders', start: false)),
              ),
            // The break's «أنا مستعد» stays in view beside an open drawer.
            PositionedDirectional(
              start: _drawer == 'chat' ? _chatWidth + GlmSpace.sm : 56,
              end: _drawer == 'orders' ? _ordersWidth + GlmSpace.sm : 56,
              bottom: GlmSpace.sm,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...urgent, if (urgent.isEmpty && last != null && _drawer == null) _lastLine(last)],
                  ),
                ),
              ),
            ),
            if (_drawer == 'chat')
              PositionedDirectional(start: 0, top: 0, bottom: 0, width: _chatWidth, child: _panel(l.matchChat, _chatDrawer(l))),
            if (_drawer == 'orders' && coach)
              PositionedDirectional(end: 0, top: 0, bottom: 0, width: _ordersWidth, child: _panel(l.liveOrders, _ordersDrawer(l))),
          ],
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, String tip, VoidCallback onTap) => Material(
    color: GlmBroadcast.tv.withValues(alpha: .88),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tip,
      icon: Icon(icon, color: GlmBroadcast.white),
      onPressed: onTap,
    ),
  );

  /// A tab on the screen's edge: its icon, its name read upward, and a dot when something waits in it.
  Widget _edge(IconData icon, String label, String drawer, {required bool start, bool dot = false}) {
    final open = _drawer == drawer;
    const r = Radius.circular(GlmRadius.md);
    return Material(
      color: open ? context.palette.gold : GlmBroadcast.tv.withValues(alpha: .88),
      shape: RoundedRectangleBorder(
        borderRadius: start
            ? const BorderRadiusDirectional.only(topEnd: r, bottomEnd: r).resolve(Directionality.of(context))
            : const BorderRadiusDirectional.only(topStart: r, bottomStart: r).resolve(Directionality.of(context)),
      ),
      child: InkWell(
        onTap: () => _openDrawer(open ? null : drawer),
        child: SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GlmSpace.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: open ? context.palette.onGold : GlmBroadcast.white),
                    if (dot && !open)
                      PositionedDirectional(
                        top: -2,
                        end: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: context.palette.live, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: GlmSpace.xs),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    label,
                    style: glmText(GlmType.caption, color: open ? context.palette.onGold : GlmBroadcast.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A drawer over the picture: its title and its close, then its body.
  Widget _panel(String title, Widget body) => Material(
    color: context.palette.panel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(GlmSpace.md, GlmSpace.xs, GlmSpace.xs, 0),
          child: Row(
            children: [
              Expanded(child: Text(title, style: context.type.title)),
              IconButton(tooltip: L.of(context).close, icon: const Icon(Icons.close_rounded), onPressed: () => _openDrawer(null)),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    ),
  );

  /// The orders: a row each with its name and its state, the assistant's notes under them, and when they reach the
  /// pitch.
  Widget _ordersDrawer(L l) {
    final busy = _busy || ref.watch(liveOrdersProvider(_id)).busy;
    final team = _teams[_you]!;
    final rows = [
      (Icons.swap_vert_rounded, l.substitute, l.subsLeft(team.subsUsed, team.subsMax), busy ? null : _subSheet),
      (Icons.tune_rounded, l.tactics, null, busy ? null : _tacticsSheet),
      (Icons.grid_view_rounded, l.formation, null, busy || widget.view.formations.isEmpty ? null : _formationSheet),
      if (!_sim)
        (Icons.timer_rounded, l.timeout, _timeoutUsed ? l.timeoutUsed : null, _busy || _timeoutUsed || !_started ? null : _takeTimeout),
    ];
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(GlmSpace.sm, 0, GlmSpace.sm, GlmSpace.md),
      children: [
        for (final (icon, label, note, onTap) in rows)
          ListTile(
            minTileHeight: 52,
            leading: Icon(icon, color: onTap == null ? p.textMuted : p.gold),
            title: Text(label, style: context.type.body.copyWith(fontWeight: FontWeight.w800)),
            subtitle: note == null ? null : Text(note, style: context.type.caption),
            enabled: onTap != null,
            onTap: onTap,
          ),
        if (_readings.isNotEmpty) ...[
          const SizedBox(height: GlmSpace.sm),
          GlmCard(
            padding: const EdgeInsets.all(GlmSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.assistantNotes,
                  style: context.type.body.copyWith(color: context.glm.goldText, fontWeight: FontWeight.w800),
                ),
                for (final r in _readings.reversed.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: GlmSpace.xs),
                    child: Text(r, style: context.type.body),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: GlmSpace.sm),
        Text(l.ordersHint, style: context.type.caption.copyWith(color: p.textMuted)),
      ],
    );
  }

  /// The chat and the commentary: the reactions at 48 each, the chat, the momentum, and the minutes told so far.
  Widget _chatDrawer(L l) {
    final p = context.palette;
    final latest = _reactions.reversed.take(4).toList();
    Widget react(String tip, Widget face, VoidCallback onTap) => SizedBox(
      width: 48,
      height: 48,
      child: IconButton(tooltip: tip, padding: EdgeInsets.zero, onPressed: onTap, icon: face),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(GlmSpace.sm, 0, GlmSpace.sm, GlmSpace.md),
      children: [
        if (_started && !_finished) ...[
          Wrap(
            children: [
              for (final e in _LiveState.reactions.entries)
                if (e.key != 'cheer' && e.key != 'boo')
                  react(e.key, Text(e.value, style: glmText(GlmType.headline)), () => _send(() => _repo.react(_id, e.key), quiet: true)),
              for (final side in _sim ? const <String>[] : ['home', 'away']) ...[
                react(
                  'cheer $side',
                  FittedBox(child: Text('📣${widget.view.club(side).code}', style: glmText(GlmType.body))),
                  () => _send(() => _repo.react(_id, 'cheer', target: side), quiet: true),
                ),
                react(
                  'boo $side',
                  FittedBox(child: Text('👎${widget.view.club(side).code}', style: glmText(GlmType.body))),
                  () => _send(() => _repo.react(_id, 'boo', target: side), quiet: true),
                ),
              ],
            ],
          ),
          if (latest.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: GlmSpace.xs),
              child: Text(
                latest.map((r) => '${_LiveState.reactions[r.key] ?? ''} ${r.who}').join('   '),
                style: glmText(GlmType.caption, color: p.textMuted),
              ),
            ),
          const SizedBox(height: GlmSpace.sm),
        ],
        if (!_sim) GlmButton(label: '${l.matchChat} ${_chat.length}', variant: GlmButtonVariant.quiet, block: true, onPressed: _chatSheet),
        if (_started && _wave.isNotEmpty) ...[
          const SizedBox(height: GlmSpace.sm),
          _MomentumStrip(wave: _wave, homePct: _homePct, view: widget.view),
        ],
        const SizedBox(height: GlmSpace.sm),
        if (_feed.isEmpty)
          Text(
            _started ? l.commentary : l.notStarted,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted),
          )
        else
          for (final e in _feed)
            if (e.text != null && e.text!.isNotEmpty) EventLine(e),
      ],
    );
  }

  /// The last event, one line at the picture's foot (the whole list in the chat's drawer).
  Widget _lastLine(MatchEvent e) => DecoratedBox(
    decoration: ShapeDecoration(color: GlmBroadcast.tv.withValues(alpha: .9), shape: GlmCut.shape(GlmCut.badge)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlmSpace.sm, vertical: GlmSpace.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            e.clock,
            textDirection: TextDirection.ltr,
            style: context.type.numbers(context.type.body).copyWith(color: GlmBroadcast.gold),
          ),
          const SizedBox(width: GlmSpace.sm),
          Flexible(
            child: Text(
              e.text!,
              maxLines: 2,
              style: context.type.body.copyWith(color: GlmBroadcast.white, fontWeight: e.big ? FontWeight.w800 : null),
            ),
          ),
        ],
      ),
    ),
  );
}
