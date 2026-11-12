part of 'live_screen.dart';

/// [Sprint 59 F4] The live match's three sheets (a substitution, the tactics, the formation), out of its state's file.
extension _LiveSheets on _LiveState {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, textAlign: TextAlign.center, style: context.text.titleSmall),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      for (final p in list)
                        ListTile(
                          dense: true,
                          selected: sel?.id == p.id,
                          selectedTileColor: ctx.palette.gold.withValues(alpha: .18),
                          shape: GlmCut.shape(GlmCut.badge),
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
                          subtitle: Text('${p.pos} · ${p.fit}%', textDirection: TextDirection.ltr),
                          onTap: () => set(() => on(p)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * .7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Text(l.subsLeft(team.subsUsed, team.subsMax), style: TextStyle(color: ctx.palette.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    l.ordersHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ctx.palette.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pick(l.subOut, team.onPitch, out, (p) => out = p),
                        const SizedBox(width: 8),
                        pick(l.subIn, team.bench, into, (p) => into = p),
                      ],
                    ),
                  ),
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
                ],
              ),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Object? val(String k) => changes[k] ?? current[k];
          Widget chips<T extends Object>(String title, String key, Map<T, String> options) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: ctx.text.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final o in options.entries)
                      ChoiceChip(
                        label: Text(o.value),
                        selected: val(key) == o.key,
                        selectedColor: ctx.palette.gold.withValues(alpha: .28),
                        onSelected: (_) => set(() => changes[key] = o.key),
                      ),
                  ],
                ),
              ],
            ),
          );
          Widget slider(String title, String key) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(title, style: ctx.text.titleSmall),
                  const Spacer(),
                  Text(
                    '${(val(key) as num? ?? 50).round()}',
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: ctx.glm.goldText),
                  ),
                ],
              ),
              Slider(
                value: (val(key) as num? ?? 50).toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: ctx.palette.gold,
                onChanged: (v) => set(() => changes[key] = v.round()),
              ),
            ],
          );
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * .75,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    l.ordersHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ctx.palette.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  chips(l.plan, 'plan', {
                    'passing': l.planPassing,
                    'counter': l.planCounter,
                    'long': l.planLong,
                    'wings': l.planWings,
                    'shots': l.planShots,
                  }),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _formationSheet() async {
    final now = _teams[_you]!.formation;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in widget.view.formations)
              ListTile(
                title: Text(f.startsWith('custom:') ? f : f, textDirection: TextDirection.ltr),
                trailing: f == now ? Icon(Icons.check_rounded, color: ctx.palette.gold) : null,
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != now) await _send(() => _repo.formation(_id, picked));
  }
}
