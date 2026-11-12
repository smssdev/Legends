import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/game_icons.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/motion.dart';
import '../health/status_screens.dart';
import 'home_data.dart';
import '../inbox/inbox_data.dart';
import '../match/match_data.dart';
import '../money/finance_screen.dart' show confirm;
import 'settings_sheet.dart';
import '../auth/auth_controller.dart';
import '../auth/ui/keep_account.dart';

/// [Sprint 15] The app's first screen after sign-in, as the web's home (MobileHome.dc.html): the coach's card with his
/// rating, and his slots: each club with its league, place and next match, a free slot's two ways in, a locked one's
/// countdown; a club opens its league in the app (Sprint 16).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return home.when(
      loading: () => const SplashScreen(),
      error: (e, _) => OfflineScreen(message: ApiError.from(e).message, onRetry: () => ref.invalidate(homeProvider)),
      data: (h) => _Home(h),
    );
  }
}

/// The game writes its numbers in Western digits in every language (as the web, Sprint 30), dates included.
String latinDigits(String v) => v.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');

Future<void> openSite(String path) => launchUrl(Uri.parse('${AppConfig.siteUrl}$path'), mode: LaunchMode.externalApplication);

class _Home extends ConsumerWidget {
  const _Home(this.h);

  final HomeData h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final extras = <Widget>[
      // [Sprint 50 M5] A guest is asked to keep the account (it goes after 30 days otherwise).
      if (ref.watch(authProvider).value?.guest == true) const Padding(padding: EdgeInsets.only(top: 12), child: KeepAccountCard()),
      if (!h.starterClaimed && h.starterCoins > 0)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GlmCard(
            gold: true,
            child: Row(
              children: [
                const Pulse(child: IconTile(Icons.redeem_rounded, size: 42)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.starterGift(h.starterCoins), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                GlmButton(
                  label: l.claimGift,
                  onPressed: () async {
                    try {
                      await ref.read(apiProvider).post('/home/starter-gift');
                      unawaited(GameSounds.play(Sfx.coin));
                    } on ApiError catch (e) {
                      if (context.mounted) showGlmToast(context, e.message, error: true);
                    }
                    ref.invalidate(homeProvider);
                  },
                ),
              ],
            ),
          ),
        ),
      // [Sprint 17 F2] My matches under way, in every league: one tap to the live screen.
      ...?ref
          .watch(myLiveMatchesProvider)
          .value
          ?.map(
            (m) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GlmCard(
                gold: true,
                onTap: () => context.push('/match/${m.id}'),
                child: Row(
                  children: [
                    Icon(Icons.sensors_rounded, color: context.glm.liveText),
                    const SizedBox(width: 10),
                    Text(
                      l.liveNow,
                      style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      '${m.home} - ${m.away}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
    ];
    final teamsTitle = Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: p.gold, size: 20),
          const SizedBox(width: 6),
          Text(l.myTeams, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text(
            l.slotsOpen(h.slotsOpen, h.slots.length),
            style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 15, color: p.textMuted),
          ),
        ],
      ),
    );
    Future<void> refresh() {
      ref.invalidate(myLiveMatchesProvider);
      ref.invalidate(unreadProvider);
      return ref.refresh(homeProvider.future);
    }

    return Scaffold(
      body: GlmBackground(
        wide: true,
        child: RefreshIndicator(
          color: p.gold,
          onRefresh: refresh,
          child: LayoutBuilder(
            builder: (context, box) {
              // [Sprint 46] Landscape, the manager games' way: the manager's file (his card, his record, the gift) on one
              // side, his slots as big numbered tiles on the stadium on the other, under the arena's top bar.
              if (box.maxWidth >= 700) {
                final side = (box.maxWidth * .44).clamp(320.0, 470.0);
                return Column(
                  children: [
                    _ArenaBar(h),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: side,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 6, 8, 20),
                              children: [
                                _Label(l.coachFile),
                                // [Sprint 47] The approved design's coach card, then the simulator's door.
                                FadeSlideIn(child: _CoachCard(h.coach)),
                                const SizedBox(height: 10),
                                const FadeSlideIn(index: 1, child: SimBanner()),
                                for (final (i, w) in extras.indexed) FadeSlideIn(index: i + 2, child: w),
                                if (h.starterClaimed || h.starterCoins == 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: FadeSlideIn(index: 3, child: _ShopTile()),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, pane) {
                                final w = (pane.maxWidth - 24 - 12) / 2;
                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 20),
                                  children: [
                                    _Label('${l.coachSlots} · ${h.slotsOpen}/${h.slots.length}'),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        for (final (i, s) in h.slots.indexed)
                                          SizedBox(
                                            width: w,
                                            height: (w * .5).clamp(128.0, 170.0),
                                            child: FadeSlideIn(index: i + 1, child: _SlotTile(s)),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _TopBar(h),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _CoachCard(h.coach)),
                  const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: SimBanner()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...extras,
                        teamsTitle,
                        for (final s in h.slots) Padding(padding: const EdgeInsets.only(bottom: 12), child: _SlotCard(s)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The brand and the coach's tools: coins, notifications, the menu.
class _TopBar extends ConsumerWidget {
  const _TopBar(this.h);

  final HomeData h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final unread = ref.watch(unreadProvider).value ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 8, 4),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(child: BrandMark(size: 30)),
            ),
          ),
          CoinsPill(coins: h.coach.coins, onTap: () => context.push('/wallet')),
          IconButton(
            tooltip: l.inbox,
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_rounded)),
            onPressed: () => context.push('/inbox'),
          ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => showSettingsSheet(context, accountNo: h.coach.accountNo),
          ),
        ],
      ),
    );
  }
}

/// [Sprint 47] The coach's card in the approved design: his initial in a mint ring, his name, his rank in gold with
/// its bar toward the next level, his points large, and his record under it.
class _CoachCard extends StatelessWidget {
  const _CoachCard(this.c);

  final Coach c;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final tier = switch (c.tierKey) {
      'tactician' => l.tierTactician,
      'professional' => l.tierProfessional,
      'elite' => l.tierElite,
      'mastermind' => l.tierMastermind,
      'icon' => l.tierIcon,
      'legend' => l.tierLegend,
      _ => l.tierProspect,
    };
    final division = c.division == null ? '' : ' ${['', 'I', 'II', 'III'][c.division!.clamp(0, 3)]}';
    final fill = ((c.division ?? 1) / 3).clamp(.1, 1.0);
    Widget record(int n, String label, Color color) => Expanded(
      child: Column(
        children: [
          CountUp(
            n,
            style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 22, fontWeight: FontWeight.w700, color: color, height: 1.1),
          ),
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
    return GlmCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      onTap: () => context.push('/profile'),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceRaised,
                  border: Border.all(color: context.glm.day ? p.brand : p.ring, width: 3),
                ),
                child: Text(
                  c.name.characters.take(1).toString(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 15, color: context.glm.goldText),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$tier$division',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.glm.goldText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LevelBar(fill, color: context.glm.day ? p.brand : p.ring, width: double.infinity, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  CountUp(
                    c.points,
                    style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 26, fontWeight: FontWeight.w700, height: 1),
                  ),
                  Text(l.pointsWord, style: TextStyle(color: p.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: p.surfaceSunk, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                record(c.won, l.won, context.glm.successText),
                record(c.drawn, l.drawn, context.glm.goldText),
                record(c.lost, l.lost, p.warning),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
