import '../../ui/tokens.g.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/console.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/club_data.dart';
import '../club/squad_screen.dart' show money;
import '../money/finance_screen.dart' show confirm;
import 'console_data.dart';

part 'market_console_player_card_art.dart';
part 'market_console_auction_listing.dart';

/// [Sprint 50 M17, M18, M19] The market's console: the league's auctions in a list with the picked player's card beside
/// it (the 3D card that turns, the value, the top bid and the bids), and the deals around a player: a bid, the release
/// clause, the talk with a computer club. Every price and rule is the server's.

class AuctionsTab extends ConsumerStatefulWidget {
  const AuctionsTab({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<AuctionsTab> createState() => _AuctionsTabState();
}

class _AuctionsTabState extends ConsumerState<AuctionsTab> {
  int? _picked;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The countdowns tick, and the list comes again every half minute (others bid meanwhile).
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (t.tick % 30 == 0) ref.invalidate(auctionsProvider(widget.leagueId));
      setState(() {});
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
    return AsyncView(
      value: ref.watch(auctionsProvider(widget.leagueId)),
      onRetry: () => ref.invalidate(auctionsProvider(widget.leagueId)),
      data: (a) {
        if (a.auctions.isEmpty) {
          return Center(
            child: Text(l.noAuctions, style: TextStyle(color: context.palette.textMuted)),
          );
        }
        final picked = a.auctions.where((x) => x.playerId == _picked).firstOrNull ?? a.auctions.first;
        return GlmSplitLayout(
          ratio: (60, 40),
          start: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final x in a.auctions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _AuctionRow(a: x, on: x.playerId == picked.playerId, onTap: () => setState(() => _picked = x.playerId)),
                ),
            ],
          ),
          end: _Inspector(leagueId: widget.leagueId, a: picked),
        );
      },
    );
  }
}

String _left(DateTime end) {
  final d = end.difference(DateTime.now());
  if (d.isNegative) return '00:00';
  String two(int n) => n.toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}' : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
}

class _AuctionRow extends StatelessWidget {
  const _AuctionRow({required this.a, required this.on, required this.onTap});

  final Auction a;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return GlmCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      gold: on,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.surfaceRaised, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${a.overall}',
              style: glmText(GlmType.bodyLg, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: p.goldLight),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${a.club} · ${a.position} · ${a.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glmText(GlmType.caption, color: p.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(context, a.top ?? a.opening),
                textDirection: TextDirection.ltr,
                style: glmText(GlmType.bodyLg, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: p.goldLight),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: (a.leading ? p.success : p.gold).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.leading ? l.leading : l.auctionEnds(_left(a.endsAt)),
                  style: glmText(GlmType.caption, color: a.leading ? p.success : p.goldLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The picked player's card: the 3D card turning, his value and the auction's state, and the ways to take him.
class _Inspector extends ConsumerStatefulWidget {
  const _Inspector({required this.leagueId, required this.a});

  final int leagueId;
  final Auction a;

  @override
  ConsumerState<_Inspector> createState() => _InspectorState();
}

class _InspectorState extends ConsumerState<_Inspector> {
  bool _busy = false;

  Future<void> _bid(int amount) async {
    setState(() => _busy = true);
    try {
      await ref.read(consoleRepositoryProvider).bid(widget.leagueId, widget.a.playerId, amount);
      unawaited(HapticFeedback.mediumImpact());
      ref.invalidate(auctionsProvider(widget.leagueId));
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final a = widget.a;
    Widget row(String k, String v, {Color? colour}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: glmText(GlmType.caption, color: p.textMuted),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: GlmFonts.numbers,
                fontFamilyFallback: const [GlmFonts.body],
                fontWeight: FontWeight.w700,
                color: colour ?? p.text,
              ),
            ),
          ),
        ],
      ),
    );
    return GlmCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 100,
            child: GlmModelSpin(
              model: 'player_card',
              label: a.name,
              fallback: PlayerCardArt(overall: a.overall, position: a.position, name: a.name),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: glmText(GlmType.body, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                row(l.marketValue, money(context, a.value), colour: p.success),
                row(l.auctionOpening, money(context, a.opening)),
                row(l.auctionTop, a.top == null ? '-' : money(context, a.top!), colour: p.goldLight),
                if (a.mine != null) row(l.yourBid, money(context, a.mine!)),
                Text(
                  l.auctionEnds(_left(a.endsAt)),
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.caption, color: p.goldLight, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                GlmButton(
                  label: l.bid(money(context, a.next)),
                  variant: GlmButtonVariant.brand,
                  block: true,
                  loading: _busy,
                  onPressed: a.leading || a.next > a.max ? null : () => _bid(a.next),
                ),
                const SizedBox(height: 6),
                ReleaseClauseButton(leagueId: widget.leagueId, playerId: a.playerId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
