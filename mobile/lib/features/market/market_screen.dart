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
import 'sell_sheet.dart';

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
                      maxLines: 2,
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

  /// [Sprint 60 F5] The approved draft's filters: a drawer from its button (part of a name, the highest price), and the
  /// ones set as small chips beside the button.
  String _q = '';
  int? _maxPrice;
  bool _drawer = false;
  static const _prices = [1000000, 5000000, 20000000, 50000000, 100000000];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = L.of(context);
    final p = context.palette;
    final MarketQuery key = (widget.leagueId, _line, _q, _maxPrice);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
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
              ),
              const SizedBox(width: GlmSpace.sm),
              if (_q.isNotEmpty)
                InputChip(
                  label: Text(_q, textDirection: TextDirection.ltr),
                  onDeleted: () => setState(() => _q = ''),
                ),
              if (_maxPrice != null)
                InputChip(
                  label: Text('≤ ${money(context, _maxPrice!)}', textDirection: TextDirection.ltr),
                  onDeleted: () => setState(() => _maxPrice = null),
                ),
              const SizedBox(width: GlmSpace.xs),
              TextButton.icon(
                onPressed: () => setState(() => _drawer = !_drawer),
                icon: const Icon(Icons.tune_rounded),
                label: Text(l.marketFilters),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: AsyncView(
                  value: ref.watch(marketListProvider(key)),
                  onRetry: () => ref.invalidate(marketListProvider(key)),
                  data: (m) => RefreshIndicator(
                    color: p.gold,
                    onRefresh: () => ref.refresh(marketListProvider(key).future),
                    // [Sprint 61 F3] Only the rows in view are built.
                    child: GameGridList(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      minWidth: 300,
                      itemCount: m.players.length,
                      itemBuilder: (context, i) => _buyCard(context, m.players[i]),
                      header: [
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
                      ],
                    ),
                  ),
                ),
              ),
              if (_drawer)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: 320,
                  child: _FilterDrawer(
                    q: _q,
                    maxPrice: _maxPrice,
                    prices: _prices,
                    apply: (q, max) => setState(() {
                      _q = q;
                      _maxPrice = max;
                      _drawer = false;
                    }),
                    close: () => setState(() => _drawer = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buyCard(BuildContext context, MarketPlayer pl) {
    final l = L.of(context);
    final p = context.palette;
    return _PlayerCard(
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
            style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
          ),
          if (pl.wasPrice != null)
            Text(
              money(context, pl.wasPrice!),
              textDirection: TextDirection.ltr,
              style: glmText(GlmType.caption, color: p.textMuted, decoration: TextDecoration.lineThrough),
            ),
        ],
      ),
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
      ref.invalidate(marketListProvider((widget.leagueId, _line, _q, _maxPrice)));
    }
  }
}

/// [Sprint 60 F5] The market's filters, a drawer over the list from the screen's end (as the squad's player card): part
/// of a name and the highest price; «طبّق» sets them, «امسح الفلاتر» clears them.
class _FilterDrawer extends StatefulWidget {
  const _FilterDrawer({required this.q, required this.maxPrice, required this.prices, required this.apply, required this.close});

  final String q;
  final int? maxPrice;
  final List<int> prices;
  final void Function(String q, int? maxPrice) apply;
  final VoidCallback close;

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  late final _name = TextEditingController(text: widget.q);
  late int? _max = widget.maxPrice;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return Material(
      color: p.panel,
      shape: BorderDirectional(start: BorderSide(color: p.surfaceRaised, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(GlmSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.marketFilters, style: context.type.title)),
                IconButton(tooltip: l.close, icon: const Icon(Icons.close_rounded), onPressed: widget.close),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: GlmSpace.sm),
                children: [
                  TextField(
                    controller: _name,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.marketName, prefixIcon: const Icon(Icons.search_rounded)),
                  ),
                  const SizedBox(height: GlmSpace.md),
                  Text(l.marketMaxPrice, style: context.type.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: GlmSpace.xs),
                  Wrap(
                    spacing: GlmSpace.xs,
                    runSpacing: GlmSpace.xs,
                    children: [
                      ChoiceChip(label: Text(l.marketAnyPrice), selected: _max == null, onSelected: (_) => setState(() => _max = null)),
                      for (final v in widget.prices)
                        ChoiceChip(
                          label: Text(money(context, v), textDirection: TextDirection.ltr),
                          selected: _max == v,
                          onSelected: (_) => setState(() => _max = v),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // The two answers stay at the drawer's foot, in reach whatever the height.
            Row(
              children: [
                Expanded(
                  child: GlmButton(label: l.marketApply, block: true, onPressed: () => widget.apply(_name.text.trim(), _max)),
                ),
                const SizedBox(width: GlmSpace.xs),
                Expanded(
                  child: GlmButton(
                    label: l.marketClear,
                    variant: GlmButtonVariant.quiet,
                    block: true,
                    onPressed: () => widget.apply('', null),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
