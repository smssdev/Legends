import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_error.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../health/status_screens.dart';
import 'home_data.dart';
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
    return Scaffold(
      body: GlmBackground(
        child: RefreshIndicator(
          color: p.gold,
          onRefresh: () => ref.refresh(homeProvider.future),
          child: CustomScrollView(slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: p.panel.withValues(alpha: .92),
              titleSpacing: 16,
              title: const BrandMark(size: 36),
              actions: [
                IconButton(tooltip: l.myLeagues, icon: const Icon(Icons.emoji_events_outlined), onPressed: () => context.push('/leagues')),
                CoinsPill(coins: h.coach.coins, onTap: () => openSite('/wallet')),
                IconButton(tooltip: l.settings, icon: const Icon(Icons.tune_rounded), onPressed: () => showSettingsSheet(context, accountNo: h.coach.accountNo)),
                const SizedBox(width: 6),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList.list(children: [
                _CoachCard(h.coach),
                const SizedBox(height: 22),
                Row(children: [
                  Text(l.myTeams, style: context.text.titleLarge),
                  const SizedBox(width: 8),
                  Text(l.slotsOpen(h.slotsOpen, h.slots.length), style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 16, color: p.textMuted)),
                ]),
                const SizedBox(height: 10),
                for (final s in h.slots) Padding(padding: const EdgeInsets.only(bottom: 12), child: _SlotCard(s)),
              ]),
            ),
          ]),
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
    final hour = DateTime.now().hour;
    final tier = switch (c.tierKey) {
      'tactician' => l.tierTactician, 'professional' => l.tierProfessional, 'elite' => l.tierElite, 'mastermind' => l.tierMastermind,
      'icon' => l.tierIcon, 'legend' => l.tierLegend, _ => l.tierProspect,
    };
    final division = c.division == null ? '' : ' ${['', 'I', 'II', 'III'][c.division!]}';
    return GlmCard(
      gold: true,
      child: Row(children: [
        CircleAvatar(radius: 32, backgroundColor: p.brand, child: Text(c.name.characters.take(1).toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hour < 12 ? l.greetingMorning : l.greetingEvening, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(c.name, style: context.text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: p.surfaceSunk, borderRadius: BorderRadius.circular(GlmSize.radiusPill)),
                child: Text('$tier$division · ${c.points}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Text(l.record(c.won, c.drawn, c.lost), style: TextStyle(color: p.textMuted, fontSize: 12)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _SlotCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final number = Text('${s.number}', style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: p.textMuted));
    switch (s.state) {
      case SlotState.club:
        final locale = Localizations.localeOf(context).toLanguageTag();
        return GlmCard(
          onTap: () => context.push('/leagues/${s.leagueId}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ClubCrest(url: s.crestUrl, name: s.clubName ?? '', size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.clubName ?? '', style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(s.leagueName ?? '', style: TextStyle(color: p.textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (s.pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: p.live, borderRadius: BorderRadius.circular(GlmSize.radiusPill)),
                  child: Text('${s.pending}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              const SizedBox(width: 6),
              number,
            ]),
            if (s.position != null && s.teams != null) ...[
              const SizedBox(height: 12),
              Text(l.position(s.position!, s.teams!), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
            if (s.matchAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${s.live ? '● ' : ''}${l.nextMatch}: ${l.vs(s.opponent ?? '')} · ${latinDigits(DateFormat.E(locale).add_jm().format(s.matchAt!))}',
                style: TextStyle(color: s.live ? context.glm.liveText : p.textMuted, fontSize: 13, fontWeight: s.live ? FontWeight.w800 : FontWeight.w500),
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
            Row(children: [
              Expanded(child: GlmButton(label: l.createLeague, onPressed: () => context.push('/leagues/new'))),
              const SizedBox(width: 10),
              Expanded(child: GlmButton(label: l.joinByCode, variant: GlmButtonVariant.quiet, onPressed: () => context.push('/join'))),
            ]),
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
              ]),
            ),
            number,
          ]),
        );
    }
  }
}
