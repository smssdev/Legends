import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money, lineColor;
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'buy_controller.dart';
import 'market_data.dart';
import '../console/market_console.dart';
import 'offer_screen.dart';

part 'market_screen_buy_sheet.dart';
part 'market_screen_offers_tab.dart';

/// [Sprint 18 F1] The market in three tabs: buy (the transfer list by line, UP11), sell (my players: listed up to
/// their cap, or now for a fee, X6) and the offers between coaches (answered here; made on the site for now).
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // [Sprint 50 M17, M18] The auctions are a tab of their own: the list and the picked player's card side by side.
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: gameTabsBar(
          context,
          title: l.market,
          tabs: [
            Tab(text: l.tabBuy),
            Tab(text: l.auctions),
            Tab(text: l.tabSell),
            Tab(text: l.tabOffers),
            Tab(text: l.academy),
          ],
        ),
        body: GlmBackground(
          child: TabBarView(
            children: [
              _BuyTab(leagueId),
              AuctionsTab(leagueId: leagueId),
              _SellTab(leagueId),
              _OffersTab(leagueId),
              _AcademyTab(leagueId),
            ],
          ),
        ),
      ),
    );
  }
}

/// [2026-11-06, stage 3] A player in the market as a game card: the rating badge by level, the position in its line's
/// colour, the name, a line under it, and the price (or an action) at the end.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.overall,
    required this.position,
    required this.line,
    required this.name,
    required this.sub,
    this.end,
    this.onTap,
    this.gold = false,
    this.subColor,
  });

  final int overall;
  final String position, line, name, sub;
  final Widget? end;
  final VoidCallback? onTap;
  final bool gold;
  final Color? subColor;

  @override
  Widget build(BuildContext context) => GlmCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    gold: gold,
    accent: lineColor(line).bg,
    onTap: onTap,
    child: Row(
      children: [
        RatingBadge(overall, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PositionChip(position, line),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: glmText(GlmType.body, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: glmText(
                  GlmType.caption,
                  color: subColor ?? context.palette.textMuted,
                  fontWeight: subColor == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (end != null) ...[const SizedBox(width: 8), end!],
      ],
    ),
  );
}

class _BuyTab extends ConsumerStatefulWidget {
  const _BuyTab(this.leagueId);

  final int leagueId;

  @override
  ConsumerState<_BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends ConsumerState<_BuyTab> with AutomaticKeepAliveClientMixin {
  String _line = 'gk';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = L.of(context);
    final p = context.palette;
    final key = (widget.leagueId, _line);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final (v, t) in [('gk', l.lineGk), ('def', l.lineDef), ('mid', l.lineMid), ('att', l.lineAtt)])
                  ButtonSegment(
                    value: v,
                    label: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              selected: {_line},
              onSelectionChanged: (s) => setState(() => _line = s.first),
            ),
          ),
        ),
        Expanded(
          child: AsyncView(
            value: ref.watch(marketListProvider(key)),
            onRetry: () => ref.invalidate(marketListProvider(key)),
            data: (m) => RefreshIndicator(
              color: p.gold,
              onRefresh: () => ref.refresh(marketListProvider(key).future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                children: [
                  if (m.closed != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l.marketClosed,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (m.renewsAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l.renewsAt(when(context, m.renewsAt!.toLocal())),
                        textAlign: TextAlign.center,
                        style: glmText(GlmType.caption, color: p.textMuted),
                      ),
                    ),
                  GameGrid(
                    minWidth: 300,
                    children: [
                      for (final pl in m.players)
                        _PlayerCard(
                          overall: pl.overall,
                          position: pl.position,
                          line: pl.line,
                          name: pl.name,
                          sub: '${pl.age} · ${pl.sellerKind == 'world' ? l.sellerWorld : pl.sellerClub ?? ''}',
                          gold: pl.fits,
                          onTap: () => _buySheet(pl),
                          end: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money(context, pl.price),
                                textDirection: TextDirection.ltr,
                                style: glmText(
                                  GlmType.title,
                                  fontFamily: GlmFonts.numbers,
                                  fontWeight: FontWeight.w800,
                                  color: context.glm.goldText,
                                ),
                              ),
                              if (pl.wasPrice != null)
                                Text(
                                  money(context, pl.wasPrice!),
                                  textDirection: TextDirection.ltr,
                                  style: glmText(GlmType.caption, color: p.textMuted, decoration: TextDecoration.lineThrough),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _buySheet(MarketPlayer pl) async {
    final repo = ref.read(marketRepositoryProvider);
    final bought = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => BuySheet(player: pl, leagueId: widget.leagueId, repo: repo),
    );
    if (bought == true && mounted) {
      showGlmToast(context, L.of(context).bought);
      ref.invalidate(marketListProvider((widget.leagueId, _line)));
    }
  }
}
