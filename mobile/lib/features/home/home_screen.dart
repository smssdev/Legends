import 'dart:async';

import 'first_steps.dart';
import '../notifications/push_primer.dart';
import '../leagues/explain.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../core/span.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../core/sounds.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/widgets/target.dart';
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

part 'home_screen_sim_banner.dart';
part 'home_screen_slot_tile.dart';

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
String latinDigits(String v) => v.replaceAllMapped(RegExp('[\u0660-\u0669]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');

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
                      style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
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
          Text(l.myTeams, style: glmText(GlmType.title, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text(
            l.slotsOpen(h.slotsOpen, h.slots.length),
            style: glmText(GlmType.body, fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], color: p.textMuted),
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
              // [Sprint 60 F3] The approved draft's home (Home.html): the coach in one line (M-D06), then the slots first, as
              // big numbered tiles on the stadium, and the gift, the simulator and the shop at the side.
              if (box.maxWidth >= 700) {
                final side = (box.maxWidth * .32).clamp(260.0, 380.0);
                return Column(
                  children: [
                    _ArenaBar(h),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _CoachLine(h.coach, leagueId: h.slots.map((s) => s.leagueId).nonNulls.firstOrNull),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, pane) {
                                final w = (pane.maxWidth - 24 - 12) / 2;
                                return ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 6, 8, 20),
                                  children: [
                                    // [Sprint 64 F2, F12] The first steps, then the notifications' primer after a match.
                                    FirstSteps(steps: h.firstSteps, leagueId: h.slots.map((s) => s.leagueId).nonNulls.firstOrNull),
                                    PushPrimer(played: h.coach.won + h.coach.drawn + h.coach.lost > 0),
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
                          SizedBox(
                            width: side,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(8, 6, 16, 20),
                              children: [
                                for (final (i, w) in extras.indexed) FadeSlideIn(index: i, child: w),
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: FadeSlideIn(index: 2, child: SimBanner()),
                                ),
                                if (h.starterClaimed || h.starterCoins == 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: FadeSlideIn(index: 3, child: _ShopTile()),
                                  ),
                              ],
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
/// [Sprint 60 F3] The coach in one line (the approved draft's home): his initial, his name, his tier and points, and
/// his record; a tap opens his account. The card with it all stays for the phone held upright.
class _CoachLine extends StatelessWidget {
  const _CoachLine(this.c, {this.leagueId});

  final Coach c;

  /// [Sprint 64 F5] A league of his, to explain the points from (none: only the number).
  final int? leagueId;

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
    final numbers = context.type.numbers(context.type.body).copyWith(fontWeight: FontWeight.w800);
    return Semantics(
      button: true,
      label: '${c.name}, $tier$division, ${c.points} ${l.pointsWord}',
      child: InkWell(
        onTap: () => context.push('/profile'),
        borderRadius: BorderRadius.circular(GlmRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GlmTouch.app),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: p.surfaceRaised,
                child: Text(c.name.characters.take(1).toString(), style: context.type.title.copyWith(color: context.glm.goldText)),
              ),
              const SizedBox(width: GlmSpace.sm),
              Flexible(
                child: Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodyLg.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: GlmSpace.sm),
              Icon(Icons.star_rounded, size: 16, color: context.glm.goldText),
              // Each part its own text: the Latin division (III) between Arabic words would turn the line around.
              Text(' $tier$division', style: context.type.caption.copyWith(color: context.glm.goldText)),
              Text(' · ', style: context.type.caption),
              ExplainTap(
                what: 'rating',
                leagueId: leagueId,
                child: Text('${c.points} ${l.pointsWord}', style: context.type.caption.copyWith(color: context.glm.goldText)),
              ),
              const Spacer(),
              Text('${c.won}', style: numbers.copyWith(color: context.glm.successText)),
              Text(' ${l.won}  ', style: context.type.caption),
              Text('${c.drawn}', style: numbers.copyWith(color: context.glm.goldText)),
              Text(' ${l.drawn}  ', style: context.type.caption),
              Text('${c.lost}', style: numbers.copyWith(color: p.warning)),
              Text(' ${l.lost}', style: context.type.caption),
            ],
          ),
        ),
      ),
    );
  }
}

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
            style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: color, height: 1.1),
          ),
          Text(label, style: glmText(GlmType.caption, color: p.textMuted)),
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
                  style: glmText(GlmType.headline, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: glmText(GlmType.bodyLg, fontWeight: FontWeight.w800),
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
                            style: glmText(GlmType.caption, fontWeight: FontWeight.w700, color: context.glm.goldText),
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
                    style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, height: 1),
                  ),
                  Text(l.pointsWord, style: glmText(GlmType.caption, color: p.textMuted)),
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
