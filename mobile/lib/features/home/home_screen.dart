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
import '../../ui/widgets/kit.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/motion.dart';
import '../../ui/widgets/stadium.dart';
import '../health/status_screens.dart';
import 'home_data.dart';
import '../inbox/inbox_data.dart';
import '../match/match_data.dart';
import '../money/finance_screen.dart' show confirm;
import 'settings_sheet.dart';

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
                if (!h.starterClaimed && h.starterCoins > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GlmCard(
                      gold: true,
                      child: Row(children: [
                        const Pulse(child: IconTile(Icons.redeem_rounded, size: 42)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.starterGift(h.starterCoins), style: const TextStyle(fontWeight: FontWeight.w800))),
                        GlmButton(label: l.claimGift, onPressed: () async {
                          try {
                            await ref.read(apiProvider).post('/home/starter-gift');
                            GameSounds.play(Sfx.coin);
                          } on ApiError catch (e) {
                            if (context.mounted) showGlmToast(context, e.message, error: true);
                          }
                          ref.invalidate(homeProvider);
                        }),
                      ]),
                    ),
                  ),
                // [Sprint 17 F2] My matches under way, in every league: one tap to the live screen.
                ...?ref.watch(myLiveMatchesProvider).value?.map((m) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GlmCard(
                        gold: true,
                        onTap: () => context.push('/match/${m.id}'),
                        child: Row(children: [
                          Icon(Icons.sensors_rounded, color: context.glm.liveText),
                          const SizedBox(width: 10),
                          Text(l.liveNow, style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('${m.home} - ${m.away}', textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right_rounded),
                        ]),
                      ),
                    )),
    ];
    final teamsTitle = Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
      child: Row(children: [
        Icon(Icons.shield_rounded, color: p.gold, size: 20),
        const SizedBox(width: 6),
        Text(l.myTeams, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text(l.slotsOpen(h.slotsOpen, h.slots.length), style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 15, color: p.textMuted)),
      ]),
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
          child: LayoutBuilder(builder: (context, box) {
            // [Sprint 46] Landscape, the manager games' way: the manager's file (his card, his record, the gift) on one
            // side, his slots as big numbered tiles on the stadium on the other, under the arena's top bar.
            if (box.maxWidth >= 700) {
              final side = (box.maxWidth * .44).clamp(320.0, 470.0);
              return Column(children: [
                _ArenaBar(h),
                Expanded(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: side,
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 8, 20), children: [
                        _Label(l.coachFile),
                        FadeSlideIn(child: _ProfileCard(h.coach)),
                        const SizedBox(height: 10),
                        FadeSlideIn(index: 1, child: _RecordTiles(h.coach)),
                        for (final (i, w) in extras.indexed) FadeSlideIn(index: i + 2, child: w),
                        if (h.starterClaimed || h.starterCoins == 0) Padding(padding: const EdgeInsets.only(top: 10), child: FadeSlideIn(index: 3, child: _ShopTile())),
                      ]),
                    ),
                    Expanded(
                      child: LayoutBuilder(builder: (context, pane) {
                        final w = (pane.maxWidth - 24 - 12) / 2;
                        return ListView(padding: const EdgeInsets.fromLTRB(8, 6, 16, 20), children: [
                          _Label('${l.coachSlots} · ${h.slotsOpen}/${h.slots.length}'),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            for (final (i, s) in h.slots.indexed) SizedBox(width: w, height: w * .62, child: FadeSlideIn(index: i + 1, child: _SlotTile(s))),
                          ]),
                        ]);
                      }),
                    ),
                  ]),
                ),
              ]);
            }
            return ListView(padding: EdgeInsets.zero, children: [
              _TopBar(h),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _CoachCard(h.coach)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ...extras,
                  teamsTitle,
                  for (final s in h.slots) Padding(padding: const EdgeInsets.only(bottom: 12), child: _SlotCard(s)),
                ]),
              ),
            ]);
          }),
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
      child: Row(children: [
        const Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: FittedBox(child: BrandMark(size: 30)))),
        CoinsPill(coins: h.coach.coins, onTap: () => context.push('/wallet')),
        IconButton(
          tooltip: l.inbox,
          icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_rounded)),
          onPressed: () => context.push('/inbox'),
        ),
        IconButton(tooltip: l.settings, icon: const Icon(Icons.menu_rounded), onPressed: () => showSettingsSheet(context, accountNo: h.coach.accountNo)),
      ]),
    );
  }
}

/// The coach himself on the stadium at night: his picture in a gold ring, his name and rank, and his record.
class _CoachCard extends StatelessWidget {
  const _CoachCard(this.c);

  final Coach c;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final hour = DateTime.now().hour;
    final tier = switch (c.tierKey) {
      'tactician' => l.tierTactician, 'professional' => l.tierProfessional, 'elite' => l.tierElite, 'mastermind' => l.tierMastermind,
      'icon' => l.tierIcon, 'legend' => l.tierLegend, _ => l.tierProspect,
    };
    final division = c.division == null ? '' : ' ${['', 'I', 'II', 'III'][c.division!]}';
    Widget record(int n, String label, Color color) => Expanded(
          child: Column(children: [
            CountUp(n, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.1)),
            Text(label, style: TextStyle(color: p.textSoft, fontSize: 11)),
          ]),
        );
    return HeroFrame(
      child: Builder(builder: (_) => StadiumBackdrop(
          pitch: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [p.goldLight, p.goldDark])),
                  child: CircleAvatar(radius: 30, backgroundColor: p.brand,
                      child: Text(c.name.characters.take(1).toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hour < 12 ? l.greetingMorning : l.greetingEvening, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(c.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: ShapeDecoration(gradient: LinearGradient(colors: [p.gold.withValues(alpha: .30), p.gold.withValues(alpha: .12)]), shape: GlmCut.shape(GlmCut.chip + 2)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.military_tech_rounded, size: 15, color: context.glm.goldText),
                        const SizedBox(width: 4),
                        Flexible(child: Text('$tier$division · ${c.points}', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: context.glm.goldText))),
                      ]),
                    ),
                  ]),
                ),
                IconButton(tooltip: l.myLeagues, icon: Icon(Icons.emoji_events_rounded, color: p.gold, size: 28), onPressed: () => context.push('/leagues')),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: p.bgDeep.withValues(alpha: .6), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [record(c.won, l.won, p.success), record(c.drawn, l.drawn, p.textSoft), record(c.lost, l.lost, p.danger)]),
              ),
            ]),
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
    final number = Text('${s.number}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: p.textMuted));
    switch (s.state) {
      case SlotState.club:
        final locale = Localizations.localeOf(context).toLanguageTag();
        return GlmCard(
          accent: s.live ? p.danger : p.pitch,
          onTap: () => context.push('/leagues/${s.leagueId}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)),
                child: ClubCrest(url: s.crestUrl, name: s.clubName ?? '', size: 52),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.clubName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
                  Text(s.leagueName ?? '', style: TextStyle(color: p.textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (s.position != null && s.teams != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: p.gold.withValues(alpha: .14), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.gold.withValues(alpha: .35))),
                  child: Column(children: [
                    Text('${s.position}', style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 22, fontWeight: FontWeight.w800, color: context.glm.goldText, height: 1)),
                    Text('/${s.teams}', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 12, color: p.textMuted, height: 1.1)),
                  ]),
                ),
              if (s.pending > 0) ...[
                const SizedBox(width: 6),
                Badge(label: Text('${s.pending}'), backgroundColor: p.live),
              ],
            ]),
            if (s.matchAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: (s.live ? p.danger : Colors.black).withValues(alpha: s.live ? .18 : .18), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(s.live ? Icons.sensors_rounded : Icons.event_rounded, size: 16, color: s.live ? context.glm.liveText : p.gold),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${l.vs(s.opponent ?? '')} · ${s.home ? l.home : l.away}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.live ? context.glm.liveText : p.text))),
                  Text(latinDigits(DateFormat.E(locale).add_jm().format(s.matchAt!.toLocal())), style: TextStyle(color: p.textMuted, fontSize: 12)),
                ]),
              ),
            ],
          ]),
        );
      case SlotState.waiting:
        return GlmCard(child: Row(children: [Icon(Icons.hourglass_top_rounded, color: p.gold), const SizedBox(width: 10), Expanded(child: Text(l.slotWaiting)), number]));
      case SlotState.free:
        return GlmCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Text(l.slotFree, style: context.text.titleMedium), const Spacer(), number]),
            const SizedBox(height: 12),
            GlmButton(label: l.createLeague, block: true, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/leagues/new')),
            const SizedBox(height: 8),
            GlmButton(label: l.joinByCode, block: true, variant: GlmButtonVariant.quiet, icon: const Icon(Icons.vpn_key_rounded), onPressed: () => context.push('/join')),
          ]),
        );
      case SlotState.locked:
        return GlmCard(
          color: context.glm.day ? p.surfaceSunk : p.surfaceSunk,
          child: Row(children: [
            Icon(Icons.lock_rounded, color: p.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.slotLocked, style: context.text.titleMedium),
                if (s.opensAt != null) Text(l.slotOpensIn(_when(context, s.opensAt!)), style: TextStyle(color: p.textMuted, fontSize: 13)),
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
              ]),
            ),
            number,
          ]),
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
        child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 15)),
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
          child: Stack(clipBehavior: Clip.none, children: [
            Material(
              shape: GlmCut.shape(10, side: BorderSide(color: Colors.white.withValues(alpha: .25))),
              color: GlmArena.menu,
              child: InkWell(customBorder: GlmCut.shape(10), onTap: onTap, child: SizedBox(width: 46, height: 38, child: Tooltip(message: tip, child: Icon(icon, color: Colors.white, size: 24)))),
            ),
            if (badge > 0)
              PositionedDirectional(
                top: -6,
                end: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: GlmArena.alert, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                  child: Text('$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ),
          ]),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 6, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.navyLight, GlmArena.navy]),
        border: Border(bottom: BorderSide(color: p.gold.withValues(alpha: .45), width: 1.2)),
      ),
      child: Row(children: [
        const Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: FittedBox(child: BrandMark(size: 30)))),
        CoinsPill(coins: h.coach.coins, onTap: () => context.push('/wallet')),
        square(Icons.notifications_rounded, l.inbox, () => context.push('/inbox'), badge: unread),
        square(Icons.emoji_events_rounded, l.myLeagues, () => context.push('/leagues')),
        square(Icons.settings_rounded, l.settings, () => showSettingsSheet(context, accountNo: h.coach.accountNo)),
      ]),
    );
  }
}

/// The manager's card: his picture in a lit ring, his name large, then a navy band with his rank, its shield and his
/// points with their bar, on the arena's bright blue.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard(this.c);

  final Coach c;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final tier = switch (c.tierKey) {
      'tactician' => l.tierTactician, 'professional' => l.tierProfessional, 'elite' => l.tierElite, 'mastermind' => l.tierMastermind,
      'icon' => l.tierIcon, 'legend' => l.tierLegend, _ => l.tierProspect,
    };
    const tiers = ['prospect', 'tactician', 'professional', 'elite', 'mastermind', 'icon', 'legend'];
    final level = tiers.indexOf(c.tierKey) + 1;
    final fill = ((c.division ?? 1) / 3).clamp(.1, 1.0);
    return HeroFrame(
      cut: 18,
      edge: Colors.white,
      glow: GlmArena.blueLight,
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.blueLight, GlmArena.blue]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFA94D), Color(0xFFE2620E)])),
              child: CircleAvatar(radius: 34, backgroundColor: GlmArena.navy,
                  child: Text(c.name.characters.take(1).toString(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)])),
            ),
          ]),
        ),
        Container(
          color: GlmArena.navy.withValues(alpha: .85),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            // The rank's shield with its level.
            SizedBox(width: 46, height: 46, child: CrestShield(code: '$level', color: const Color(0xFFE2620E), size: 46)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(tier, style: TextStyle(color: p.goldLight, fontWeight: FontWeight.w800, fontSize: 17))),
                  Image.asset('assets/brand/coin.png', width: 18, height: 18),
                  const SizedBox(width: 4),
                  CountUp(c.points, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
                ]),
                const SizedBox(height: 6),
                LevelBar(fill, color: p.success, width: double.infinity, height: 8),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// The manager's record as tiles: each number large over its glossy picture.
class _RecordTiles extends StatelessWidget {
  const _RecordTiles(this.c);

  final Coach c;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final tiles = [(l.statWon, c.won, GameGlyph.honours), (l.statDrawn, c.drawn, GameGlyph.match), (l.statLost, c.lost, GameGlyph.alliance)];
    return Row(children: [
      for (final (i, (label, n, glyph)) in tiles.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            decoration: ShapeDecoration(
              shape: GlmCut.shape(12, side: const BorderSide(color: GlmArena.navyEdge)),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.navyLight, GlmArena.navy]),
            ),
            child: Column(children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              CountUp(n, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 30, color: Colors.white, height: 1.1)),
              GameIcon(glyph, size: 34),
            ]),
          ),
        ),
      ],
    ]);
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
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.questTop, GlmArena.questBottom])),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(children: [
            const GameIcon(GameGlyph.shop, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.shopTile, style: TextStyle(color: p.onGold, fontWeight: FontWeight.w800, fontSize: 19)),
                Text(l.shopSub, style: TextStyle(color: p.onGold.withValues(alpha: .75), fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: p.onGold),
          ]),
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
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  GlmButton(label: l.createLeague, block: true, icon: const Icon(Icons.add_rounded), onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/leagues/new');
                  }),
                  const SizedBox(height: 8),
                  GlmButton(label: l.joinByCode, block: true, variant: GlmButtonVariant.quiet, icon: const Icon(Icons.vpn_key_rounded), onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/join');
                  }),
                ]),
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
    final top = switch (s.state) {
      SlotState.club => s.live ? l.liveBadge : s.position != null ? '${s.position}/${s.teams}' : '',
      SlotState.waiting => l.slotWaiting,
      SlotState.locked => s.opensAt == null ? l.slotLocked : l.slotOpensIn(_left(context, s.opensAt!)),
      _ => '',
    };
    Widget middle = switch (s.state) {
      SlotState.club => ClubCrest(url: s.crestUrl, name: s.clubName ?? '', size: 70),
      SlotState.free => Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(shape: BoxShape.circle, color: GlmArena.navy, border: Border.all(color: GlmArena.navyEdge, width: 2)),
          child: const Icon(Icons.add_rounded, size: 52, color: Color(0xFF7FD3FF)),
        ),
      SlotState.locked => Icon(Icons.lock_rounded, size: 56, color: Colors.white.withValues(alpha: .85)),
      _ => const Icon(Icons.hourglass_top_rounded, size: 52, color: Colors.white70),
    };
    final name = switch (s.state) {
      SlotState.club => (s.clubName ?? '').toUpperCase(),
      SlotState.free => l.newLeagueShort,
      SlotState.locked when s.unlockCoins != null => l.unlockSlot(s.unlockCoins!),
      _ => '',
    };
    final sub = s.state == SlotState.club ? (s.opponent == null ? s.leagueName ?? '' : l.vs(s.opponent!)) : '';
    return Material(
      shape: GlmCut.shape(16, side: BorderSide(color: s.live ? p.danger : Colors.white.withValues(alpha: .18), width: 1.4)),
      clipBehavior: Clip.antiAlias,
      color: GlmArena.navy,
      child: InkWell(
        onTap: tap,
        child: Stack(fit: StackFit.expand, children: [
          if (!free && !locked) const StadiumBackdrop(),
          if (free) DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(-.6, -.8), radius: 1.3, colors: [GlmArena.blueLight.withValues(alpha: .6), GlmArena.blueDeep]))),
          if (locked) const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmArena.navyLight, GlmArena.navy]))),
          if (s.live) DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [GlmArena.blue.withValues(alpha: .7), p.live.withValues(alpha: .8)]))),
          // The slot's number in its corner.
          PositionedDirectional(
            top: 0,
            end: 14,
            child: Container(
              width: 52,
              height: 58,
              alignment: Alignment.center,
              decoration: const ShapeDecoration(shape: BeveledRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))), color: GlmArena.navy),
              child: Text('${s.number}', style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 36, color: Colors.white)),
            ),
          ),
          if (top.isNotEmpty)
            PositionedDirectional(
              top: 10,
              start: 14,
              end: 76,
              child: Text(top, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: s.live ? Colors.white : p.goldLight, fontWeight: FontWeight.w800, fontSize: 15, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)])),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: middle)),
              const SizedBox(height: 6),
              if (name.isNotEmpty)
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, textDirection: s.state == SlotState.club ? TextDirection.ltr : null,
                    style: TextStyle(fontFamily: s.state == SlotState.club ? GlmFonts.numbers : GlmFonts.body, fontWeight: FontWeight.w800, fontSize: s.state == SlotState.club || free ? 26 : 16, color: Colors.white, height: 1.05,
                        shadows: const [Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)])),
              if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: TextStyle(color: p.goldLight, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
          if (s.pending > 0)
            PositionedDirectional(
              bottom: 8,
              end: 10,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: GlmArena.alert, border: Border.all(color: Colors.white, width: 2)),
                child: const Text('!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1)),
              ),
            ),
        ]),
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
