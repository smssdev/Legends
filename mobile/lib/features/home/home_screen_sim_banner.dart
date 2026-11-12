part of 'home_screen.dart';

/// [Sprint 47] The simulator's door on the home: an emerald card, a ball rolling, «play» in gold. A quick match against
/// the computer or a friend, apart from the leagues.
class SimBanner extends StatelessWidget {
  const SimBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Shine(
      strength: .14,
      period: const Duration(milliseconds: 3400),
      clip: GlmCut.card,
      child: Material(
        color: p.brandDark,
        shape: GlmCut.shape(GlmCut.card, side: BorderSide(color: p.brand)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            GameSounds.play(Sfx.tap);
            context.push('/sim');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .35), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: RollingBall(size: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.simQuickTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                      ),
                      Text(l.simQuickLead, style: TextStyle(fontSize: 13, color: p.chrome)),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    l.simPlay,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: p.onGold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard(this.s);

  final Slot s;

  String _when(BuildContext context, DateTime at) {
    final l = L.of(context);
    final left = at.difference(DateTime.now());
    if (left.inDays >= 1) return '${l.days(left.inDays)} ${l.hours(left.inHours % 24)}';
    if (left.inHours >= 1) return l.hours(left.inHours);
    return l.minutes(left.inMinutes.clamp(1, 59));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final number = Text(
      '${s.number}',
      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: p.textMuted),
    );
    switch (s.state) {
      case SlotState.club:
        final locale = Localizations.localeOf(context).toLanguageTag();
        // [Sprint 47] The approved design: the slot's emerald band (its number and league, the live mark), then the club.
        return GlmCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push('/leagues/${s.leagueId}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: p.brandDark,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l.slotN(s.number)} · ${s.leagueName ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
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
                            const SizedBox(width: 6),
                            Text(
                              l.liveNow,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    if (s.pending > 0) ...[const SizedBox(width: 6), Badge(label: Text('${s.pending}'), backgroundColor: p.live)],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    ClubCrest(url: s.crestUrl, name: s.clubName ?? '', size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.clubName ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                          if (s.matchAt != null)
                            Text(
                              '${l.vs(s.opponent ?? '')} · ${latinDigits(DateFormat.E(locale).add_jm().format(s.matchAt!.toLocal()))}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.textSoft, fontSize: 13),
                            )
                          else
                            Text(
                              s.leagueName ?? '',
                              style: TextStyle(color: p.textMuted, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (s.position != null)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: s.position! <= 3 ? p.gold : p.surfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: s.position! <= 3 ? p.onGold : p.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case SlotState.waiting:
        return GlmCard(
          child: Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: p.gold),
              const SizedBox(width: 10),
              Expanded(child: Text(l.slotWaiting)),
              number,
            ],
          ),
        );
      case SlotState.free:
        return GlmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(l.slotFree, style: context.text.titleMedium),
                  const Spacer(),
                  number,
                ],
              ),
              const SizedBox(height: 12),
              GlmButton(
                label: l.createLeague,
                block: true,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push('/leagues/new'),
              ),
              const SizedBox(height: 8),
              GlmButton(
                label: l.joinByCode,
                block: true,
                variant: GlmButtonVariant.quiet,
                icon: const Icon(Icons.vpn_key_rounded),
                onPressed: () => context.push('/join'),
              ),
            ],
          ),
        );
      case SlotState.locked:
        return GlmCard(
          color: context.glm.day ? p.surfaceSunk : p.surfaceSunk,
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: p.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.slotLocked, style: context.text.titleMedium),
                    if (s.opensAt != null)
                      Text(l.slotOpensIn(_when(context, s.opensAt!)), style: TextStyle(color: p.textMuted, fontSize: 13)),
                    // [Sprint 24 B3] Open it now for coins, at the server's price; it stays open for good.
                    if (s.unlockCoins != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GlmButton(
                          label: l.unlockSlot(s.unlockCoins!),
                          variant: GlmButtonVariant.outline,
                          block: true,
                          onPressed: () async {
                            if (!await confirm(context, l.unlockConfirm(s.number, s.unlockCoins!)) || !context.mounted) return;
                            try {
                              await ref.read(apiProvider).post('/home/slots/${s.number}/unlock');
                            } on ApiError catch (e) {
                              if (context.mounted) showGlmToast(context, e.message, error: true);
                            }
                            ref.invalidate(homeProvider);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              number,
            ],
          ),
        );
    }
  }
}

/// [Sprint 46] A section's name over it, as the manager games label their panels: small, bold, light on the blue.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: TextStyle(color: context.palette.textSoft, fontWeight: FontWeight.w800, fontSize: 15),
    ),
  );
}

/// The arena's top bar on the home: the game's mark, the coins in their green pill (to the wallet), the messages with
/// their count, the settings.
class _ArenaBar extends ConsumerWidget {
  const _ArenaBar(this.h);

  final HomeData h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final unread = ref.watch(unreadProvider).value ?? 0;
    Widget square(IconData icon, String tip, VoidCallback onTap, {int badge = 0}) => Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            shape: GlmCut.shape(12, side: BorderSide(color: p.surfaceRaised)),
            color: context.glm.day ? p.surface : GlmStage.card,
            child: InkWell(
              customBorder: GlmCut.shape(12),
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Tooltip(
                  message: tip,
                  child: Icon(icon, color: p.text, size: 22),
                ),
              ),
            ),
          ),
          if (badge > 0)
            PositionedDirectional(
              top: -6,
              end: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: GlmStage.alert,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
    return Container(
      padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 6, 10, 6),
      decoration: BoxDecoration(
        color: context.glm.day ? p.panel : GlmStage.deep,
        border: Border(bottom: BorderSide(color: p.surfaceRaised)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(child: BrandMark(size: 30)),
            ),
          ),
          CoinsPill(coins: h.coach.coins, onTap: () => context.push('/wallet')),
          square(Icons.notifications_rounded, l.inbox, () => context.push('/inbox'), badge: unread),
          square(Icons.emoji_events_rounded, l.myLeagues, () => context.push('/leagues')),
          square(Icons.settings_rounded, l.settings, () => showSettingsSheet(context, accountNo: h.coach.accountNo)),
        ],
      ),
    );
  }
}

/// The shop as a gold tile, as the manager games keep their offers in sight.
class _ShopTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Material(
      shape: GlmCut.shape(14, side: BorderSide(color: p.goldLight)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/wallet'),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GlmStage.questTop, GlmStage.questBottom],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              const GameIcon(GameGlyph.shop, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.shopTile,
                      style: TextStyle(color: p.onGold, fontWeight: FontWeight.w800, fontSize: 19),
                    ),
                    Text(
                      l.shopSub,
                      style: TextStyle(color: p.onGold.withValues(alpha: .75), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.onGold),
            ],
          ),
        ),
      ),
    );
  }
}
