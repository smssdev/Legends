part of 'tournament_screens.dart';

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.tournaments,
      AsyncView(
        value: ref.watch(tournamentProvider(id)),
        onRetry: () => ref.invalidate(tournamentProvider(id)),
        data: (t) {
          final p = context.palette;
          final entry = t.entry;
          final groups = <String, List<api.TournamentTeam>>{};
          for (final x in t.teams) {
            if (x.group case final g?) (groups[g] ??= []).add(x);
          }
          final code = t.code;
          Future<void> act(Future<Object?> Function() a) async {
            await _try(context, a);
            ref.invalidate(tournamentProvider(id));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GlmCard(
                gold: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.name, style: context.text.titleLarge),
                    Text('${templateName(l, t.template ?? '')} · ${l.teamsCount(t.teamCount)}', style: TextStyle(color: p.textMuted)),
                    if (DateTime.tryParse(t.startsAt) case final at?) Text('${l.startsOn}: ${when(context, at.toLocal())}'),
                    const SizedBox(height: 10),
                    Text(l.tournamentCode, style: TextStyle(color: p.textMuted, fontSize: 12)),
                    SelectableText(
                      code,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GlmFonts.numbers,
                        fontSize: 28,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: context.glm.goldText,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GlmButton(
                            label: l.share,
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () => SharePlus.instance.share(ShareParams(text: '${AppConfig.siteUrl}/join/$code')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlmButton(
                            label: l.code,
                            variant: GlmButtonVariant.quiet,
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              showGlmToast(context, l.copied);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (entry.mode == 'draw' && (entry.canEnter || entry.isEntrant))
                GlmButton(
                  label: entry.isEntrant ? l.leaveEntry : l.enter,
                  variant: entry.isEntrant ? GlmButtonVariant.outline : GlmButtonVariant.primary,
                  block: true,
                  onPressed: () => act(
                    () => entry.isEntrant
                        ? ref.read(apiProvider).delete('/tournaments/$id/entry')
                        : ref.read(apiProvider).post('/tournaments/$id/entry'),
                  ),
                ),
              const SizedBox(height: 8),
              GlmButton(
                label: l.watchDraw,
                variant: GlmButtonVariant.brand,
                icon: const Icon(Icons.casino_rounded),
                block: true,
                onPressed: () => context.push('/tournaments/$id/draw'),
              ),
              if (entry.isMember && t.status != 'waiting') ...[
                const SizedBox(height: 8),
                GlmButton(
                  label: l.openLeague,
                  variant: GlmButtonVariant.outline,
                  block: true,
                  onPressed: () => context.push('/leagues/$id'),
                ),
              ],
              const SizedBox(height: 12),
              for (final g in (groups.keys.toList()..sort()))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.groupN(g), style: context.text.titleMedium),
                        for (final x in groups[g]!)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                ClubCrest(url: x.crestUrl, name: x.code, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(x.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                                ),
                                if (x.coach case final coach?) Text(coach, style: TextStyle(color: p.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The draw: before it, its time (the organizer sets it); after, the balls one by one on the shared clock.
class DrawScreen extends ConsumerStatefulWidget {
  const DrawScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  Timer? _tick;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _page(
      l.watchDraw,
      AsyncView(
        value: ref.watch(drawProvider(widget.id)),
        onRetry: () => ref.invalidate(drawProvider(widget.id)),
        data: (d) {
          final p = context.palette;
          _offset = d.serverNow - DateTime.now().millisecondsSinceEpoch;
          final steps = d.steps;
          final drawnAt = DateTime.tryParse(d.drawnAt ?? '');
          final drawAt = DateTime.tryParse(d.drawAt ?? '');
          final revealMs = d.revealMs;
          final now = DateTime.now().millisecondsSinceEpoch + _offset;
          final shown = drawnAt == null ? 0 : ((now - drawnAt.millisecondsSinceEpoch) ~/ revealMs + 1).clamp(0, steps.length);
          if (drawnAt == null && drawAt != null && now >= drawAt.millisecondsSinceEpoch) {
            // Its time has come: ask again for the balls.
            Future.microtask(() => ref.invalidate(drawProvider(widget.id)));
          }
          final groups = <int, List<api.TournamentsDrawAnswerStepsItem>>{};
          for (final s in steps.take(shown)) {
            if (s.group case final g?) (groups[g] ??= []).add(s);
          }
          final last = shown == 0 ? null : steps[shown - 1];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (drawnAt == null) ...[
                Text(
                  drawAt == null ? l.drawNotSet : l.drawAt(when(context, drawAt.toLocal())),
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
                if (d.canSchedule) ...[
                  const SizedBox(height: 10),
                  GlmButton(
                    label: l.scheduleDraw,
                    icon: const Icon(Icons.schedule_rounded),
                    onPressed: () async {
                      final at = await pickWhen(context, DateTime.now());
                      if (at == null || !context.mounted) return;
                      await _try(
                        context,
                        () => ref.read(apiProvider).put('/leagues/${widget.id}/draw', {'draw_at': at.toUtc().toIso8601String()}),
                      );
                      ref.invalidate(drawProvider(widget.id));
                    },
                  ),
                ],
              ] else ...[
                Text(
                  l.drawnBalls(shown, steps.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
                if (last != null)
                  GlmCard(
                    gold: true,
                    child: Column(
                      children: [
                        ClubCrest(url: last.club?.crestUrl, name: last.club?.code ?? '', size: 64),
                        const SizedBox(height: 6),
                        Text(last.club?.name ?? '', textDirection: TextDirection.ltr, style: context.text.titleLarge),
                        if (last.group case final g?)
                          Text(
                            l.groupN(String.fromCharCode(64 + g)),
                            style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                for (final g in (groups.keys.toList()..sort()))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.groupN(String.fromCharCode(64 + g)), style: const TextStyle(fontWeight: FontWeight.w800)),
                          for (final s in groups[g]!)
                            Text(s.club?.name ?? '', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
