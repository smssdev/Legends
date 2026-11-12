part of 'home_screen.dart';

/// A slot as the manager games show it: a big tile on the stadium, its number in a navy corner, the club's crest in its
/// middle and its name large under it with the league, or the way to a new league, or its lock and countdown. A live
/// match turns it red; a tap opens the league.
class _SlotTile extends ConsumerWidget {
  const _SlotTile(this.s);

  final Slot s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final locked = s.state == SlotState.locked;
    final free = s.state == SlotState.free;
    VoidCallback? tap = switch (s.state) {
      SlotState.club => () => context.push('/leagues/${s.leagueId}'),
      SlotState.free => () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlmButton(
                  label: l.createLeague,
                  block: true,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/leagues/new');
                  },
                ),
                const SizedBox(height: 8),
                GlmButton(
                  label: l.joinByCode,
                  block: true,
                  variant: GlmButtonVariant.quiet,
                  icon: const Icon(Icons.vpn_key_rounded),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/join');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      SlotState.locked when s.unlockCoins != null => () async {
        if (!await confirm(context, l.unlockConfirm(s.number, s.unlockCoins!)) || !context.mounted) return;
        try {
          await ref.read(apiProvider).post('/home/slots/${s.number}/unlock');
        } on ApiError catch (e) {
          if (context.mounted) showGlmToast(context, e.message, error: true);
        }
        ref.invalidate(homeProvider);
      },
      _ => null,
    };
    // [Sprint 47] The approved design's slot: its emerald band (its number and league, live in red), then the club with
    // its next opponent and its place in gold; a free slot dashed in mint; a locked one with its clock and its price.
    final band = switch (s.state) {
      SlotState.club => '${l.slotN(s.number)} · ${s.leagueName ?? ''}',
      _ => l.slotN(s.number),
    };
    final Widget body = switch (s.state) {
      SlotState.club => Row(
        children: [
          ClubCrest(url: s.crestUrl, name: s.clubName ?? '', size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.clubName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                if (s.opponent != null)
                  Text(
                    l.vs(s.opponent!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textSoft, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (s.position != null)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: s.position! <= 3 ? p.gold : p.surfaceRaised, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${s.position}',
                      style: TextStyle(
                        fontFamily: GlmFonts.numbers,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: s.position! <= 3 ? p.onGold : p.text,
                      ),
                    ),
                    Text(
                      l.positionWord,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.position! <= 3 ? p.onGold : p.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      SlotState.free => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: p.brand.withValues(alpha: .22), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.add_rounded, size: 30, color: context.glm.brandText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l.newLeagueShort, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ),
        ],
      ),
      SlotState.locked => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.lock_rounded, color: p.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.opensAt == null ? l.slotLocked : l.slotOpensIn(_left(context, s.opensAt!)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textSoft, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (s.unlockCoins != null)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.gold),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/brand/coin.png', width: 18, height: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${s.unlockCoins}',
                    style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, fontSize: 17, color: context.glm.goldText),
                  ),
                ],
              ),
            ),
        ],
      ),
      _ => Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(l.slotWaiting)),
        ],
      ),
    };
    final club = s.state == SlotState.club;
    return Material(
      shape: GlmCut.shape(
        GlmCut.card,
        side: BorderSide(color: s.live ? p.live : p.surfaceRaised, width: free || locked ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      color: locked || free ? p.surfaceSunk : p.surface,
      child: InkWell(
        onTap: tap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: club ? p.brandDark : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          band,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: club ? Colors.white : p.textMuted),
                        ),
                      ),
                      if (s.live)
                        Pulse(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: p.live, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l.liveNow,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                    child: Center(child: body),
                  ),
                ),
              ],
            ),
            if (s.pending > 0)
              PositionedDirectional(
                top: 4,
                end: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GlmStage.alert,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, height: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _left(BuildContext context, DateTime at) {
    final l = L.of(context);
    final left = at.difference(DateTime.now());
    if (left.inDays >= 1) return l.days(left.inDays);
    if (left.inHours >= 1) return l.hours(left.inHours);
    return l.minutes(left.inMinutes.clamp(1, 59));
  }
}
