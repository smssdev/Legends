part of 'live_screen.dart';

/// [Sprint 59 F4] The live match's chat, reactions, feed list and clip look, out of its state's file.
extension _LiveSocial on _LiveState {
  /// The clip's colours: both kits as on the pitch, the keepers' and the referee's far from them, the night, the rain.
  ClipLook _clipLook(BuildContext context, Map<String, (Color, Color)> kits) {
    final p = context.palette;
    final taken = [kits['home']!.$1, kits['away']!.$1];
    return ClipLook(
      kits: kits,
      keeper: farFrom(taken, GlmArt.keeperKits),
      referee: farFrom(taken, GlmArt.refereeKits),
      grass: p.pitch,
      grassDark: p.pitchDark,
      gold: p.gold,
      night: p.bgDeep,
      rain: rainy(widget.view.seed),
    );
  }

  Widget _socialBar(L l) {
    final p = context.palette;
    final latest = _reactions.reversed.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          if (latest.isNotEmpty)
            Text(
              latest.map((r) => '${_LiveState.reactions[r.key] ?? ''} ${r.who}').join('   '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: glmText(GlmType.caption, color: p.textMuted),
            ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (!_sim) ...[
                  ActionChip(
                    avatar: const Icon(Icons.chat_bubble_rounded, size: 18),
                    label: Text('${l.matchChat} ${_chat.length}'),
                    onPressed: _chatSheet,
                  ),
                  const SizedBox(width: 6),
                ],
                for (final e in _LiveState.reactions.entries)
                  if (e.key != 'cheer' && e.key != 'boo')
                    IconButton(
                      tooltip: e.key,
                      onPressed: () => _send(() => _repo.react(_id, e.key), quiet: true),
                      icon: Text(e.value, style: glmText(GlmType.headline)),
                    ),
                for (final side in _sim ? const <String>[] : ['home', 'away']) ...[
                  IconButton(
                    tooltip: 'cheer $side',
                    onPressed: () => _send(() => _repo.react(_id, 'cheer', target: side), quiet: true),
                    icon: Text('📣${widget.view.club(side).code}', style: glmText(GlmType.body)),
                  ),
                  IconButton(
                    tooltip: 'boo $side',
                    onPressed: () => _send(() => _repo.react(_id, 'boo', target: side), quiet: true),
                    icon: Text('👎${widget.view.club(side).code}', style: glmText(GlmType.body)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final c in _chat.reversed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${c.who}: ',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: ctx.glm.goldText),
                                ),
                                TextSpan(text: c.body),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: text,
                            maxLength: 140,
                            decoration: InputDecoration(hintText: l.typeMessage, counterText: ''),
                          ),
                        ),
                        IconButton(
                          tooltip: l.send,
                          icon: Icon(Icons.send_rounded, color: ctx.palette.gold),
                          onPressed: () async {
                            final body = text.text.trim();
                            if (body.isEmpty) return;
                            text.clear();
                            await _send(() => _repo.say(_id, body), quiet: true);
                            await _live.now();
                            set(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    text.dispose();
  }

  Widget _feedList(L l) {
    final p = context.palette;
    if (_feed.isEmpty && _readings.isEmpty) {
      final at = widget.view.kickoffAt;
      return Center(
        child: Text(_started || at == null ? l.commentary : l.notStarted, style: TextStyle(color: p.textMuted)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (_readings.isNotEmpty)
          GlmCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.assistantNotes,
                  style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final r in _readings.reversed.take(3)) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r)),
              ],
            ),
          ),
        if (_readings.isNotEmpty) const SizedBox(height: 10),
        for (final e in _feed)
          if (e.text != null && e.text!.isNotEmpty) EventLine(e),
      ],
    );
  }
}
