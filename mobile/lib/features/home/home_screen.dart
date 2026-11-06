import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
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
                        const Text('🎁', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.starterGift(h.starterCoins), style: const TextStyle(fontWeight: FontWeight.w800))),
                        GlmButton(label: l.claimGift, onPressed: () async {
                          try {
                            await ref.read(apiProvider).post('/home/starter-gift');
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
            // [2026-11-06] Landscape: the coach on the stadium at the side, his teams in a grid beside him.
            if (box.maxWidth >= 700) {
              return Column(children: [
                _TopBar(h),
                Expanded(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: (box.maxWidth * .38).clamp(300, 420),
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 8, 24), children: [
                        FadeSlideIn(child: _CoachCard(h.coach)),
                        for (final (i, w) in extras.indexed) FadeSlideIn(index: i + 1, child: w),
                      ]),
                    ),
                    Expanded(
                      child: ListView(padding: const EdgeInsets.fromLTRB(8, 0, 16, 24), children: [
                        teamsTitle,
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          for (final (i, s) in h.slots.indexed)
                            SizedBox(width: ((box.maxWidth - (box.maxWidth * .38).clamp(300, 420)) - 24 - 12) / 2, child: FadeSlideIn(index: i + 2, child: _SlotCard(s))),
                        ]),
                      ]),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.gold.withValues(alpha: .5)),
        boxShadow: [BoxShadow(color: p.gold.withValues(alpha: .14), blurRadius: 28, spreadRadius: -6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: StadiumBackdrop(
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
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [p.gold.withValues(alpha: .30), p.gold.withValues(alpha: .12)]), borderRadius: BorderRadius.circular(99)),
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
