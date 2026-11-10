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
import 'market_data.dart';
import '../console/market_console.dart';
import 'offer_screen.dart';

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
        appBar: gameTabsBar(context, title: l.market, tabs: [Tab(text: l.tabBuy), Tab(text: l.auctions), Tab(text: l.tabSell), Tab(text: l.tabOffers), Tab(text: l.academy)]),
        body: GlmBackground(
          child: TabBarView(children: [_BuyTab(leagueId), AuctionsTab(leagueId: leagueId), _SellTab(leagueId), _OffersTab(leagueId), _AcademyTab(leagueId)]),
        ),
      ),
    );
  }
}

/// [2026-11-06, stage 3] A player in the market as a game card: the rating badge by level, the position in its line's
/// colour, the name, a line under it, and the price (or an action) at the end.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.overall, required this.position, required this.line, required this.name, required this.sub, this.end, this.onTap, this.gold = false, this.subColor});

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
        child: Row(children: [
          RatingBadge(overall, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                PositionChip(position, line),
                const SizedBox(width: 8),
                Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              ]),
              const SizedBox(height: 4),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subColor ?? context.palette.textMuted, fontSize: 12, fontWeight: subColor == null ? FontWeight.w500 : FontWeight.w700)),
            ]),
          ),
          if (end != null) ...[const SizedBox(width: 8), end!],
        ]),
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
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            for (final (v, t) in [('gk', l.lineGk), ('def', l.lineDef), ('mid', l.lineMid), ('att', l.lineAtt)])
              ButtonSegment(value: v, label: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          selected: {_line},
          onSelectionChanged: (s) => setState(() => _line = s.first),
        )),
      ),
      Expanded(
        child: AsyncView(
          value: ref.watch(marketListProvider(key)),
          onRetry: () => ref.invalidate(marketListProvider(key)),
          data: (m) => RefreshIndicator(
            color: p.gold,
            onRefresh: () => ref.refresh(marketListProvider(key).future),
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 6, 12, 24), children: [
              if (m.closed != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l.marketClosed, textAlign: TextAlign.center, style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700))),
              if (m.renewsAt != null)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l.renewsAt(when(context, m.renewsAt!.toLocal())), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12))),
              GameGrid(minWidth: 300, children: [
                for (final pl in m.players)
                  _PlayerCard(
                    overall: pl.overall,
                    position: pl.position,
                    line: pl.line,
                    name: pl.name,
                    sub: '${pl.age} · ${pl.sellerKind == 'world' ? l.sellerWorld : pl.sellerClub ?? ''}',
                    gold: pl.fits,
                    onTap: () => _buySheet(pl),
                    end: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(money(context, pl.price), textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 20, fontWeight: FontWeight.w800, color: context.glm.goldText)),
                      if (pl.wasPrice != null)
                        Text(money(context, pl.wasPrice!), textDirection: TextDirection.ltr, style: TextStyle(color: p.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                    ]),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    ]);
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

class BuySheet extends StatefulWidget {
  const BuySheet({super.key, required this.player, required this.leagueId, required this.repo});

  final MarketPlayer player;
  final int leagueId;
  final MarketRepository repo;

  @override
  State<BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<BuySheet> {
  BuyQuote? _q;
  String? _error;
  bool _busy = false, _compensate = false;

  @override
  void initState() {
    super.initState();
    widget.repo.buyQuote(widget.leagueId, widget.player.id).then((q) {
      if (mounted) setState(() => _q = q);
    }, onError: (Object e) {
      if (mounted) setState(() => _error = ApiError.from(e).message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final pl = widget.player;
    final q = _q;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            RatingBadge(pl.overall, size: 52),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pl.name, textDirection: TextDirection.ltr, style: context.text.titleLarge),
              Text([pl.position, '${pl.age}', if (pl.nationality != null) pl.nationality!, if (pl.potential != null) '${l.potentialWord} ${pl.potential}'].join(' · '),
                  style: TextStyle(color: p.textMuted)),
            ])),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in pl.attributes.entries)
              Chip(label: Text('${e.key.toUpperCase()} ${e.value}', textDirection: TextDirection.ltr, style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          if (_error != null) Text(_error!, style: TextStyle(color: context.glm.liveText)),
          if (q == null && _error == null) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
          if (q != null) ...[
            if (q.docCoins > 0) Text(l.regFee(q.docCoins), style: TextStyle(color: p.textMuted)),
            if (q.why != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(q.why!, style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700))),
            if (q.compensate != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _compensate,
                activeThumbColor: p.gold,
                title: Text(l.compensateWith(q.compensate!.coins)),
                onChanged: (v) => setState(() => _compensate = v),
              ),
            const SizedBox(height: 10),
            // [Sprint 50 M19] A computer club's player: talk the price down; a coach's: take him at his release clause.
            if (pl.sellerKind == 'bot') ...[
              GlmButton(
                label: l.negotiate,
                variant: GlmButtonVariant.brand,
                block: true,
                onPressed: () async {
                  final done = await showNegotiation(context, leagueId: widget.leagueId, playerId: pl.id, name: pl.name);
                  if (done == true && context.mounted) Navigator.pop(context, true);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (pl.sellerKind == 'coach') ...[
              ReleaseClauseButton(leagueId: widget.leagueId, playerId: pl.id, onDone: () => Navigator.pop(context, true)),
              const SizedBox(height: 8),
            ],
            GlmButton(
              label: l.buyFor(money(context, q.price)),
              block: true,
              loading: _busy,
              onPressed: q.can || (q.compensate != null && _compensate)
                  ? () async {
                      setState(() => _busy = true);
                      try {
                        await widget.repo.buy(widget.leagueId, pl.id, compensate: _compensate);
                        if (context.mounted) Navigator.pop(context, true);
                      } on ApiError catch (e) {
                        if (mounted) setState(() => _error = e.message);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    }
                  : null,
            ),
          ],
        ]),
      ),
    );
  }
}

class _SellTab extends ConsumerWidget {
  const _SellTab(this.leagueId);

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    return AsyncView(
      value: ref.watch(sellingProvider(leagueId)),
      onRetry: () => ref.invalidate(sellingProvider(leagueId)),
      data: (s) => RefreshIndicator(
        color: p.gold,
        onRefresh: () => ref.refresh(sellingProvider(leagueId).future),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          Text(l.listingsOf(s.listed, s.maxListings), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 8),
          GameGrid(minWidth: 300, children: [
            for (final pl in s.mine)
              _PlayerCard(
                overall: pl.overall,
                position: pl.position,
                line: pl.line,
                name: pl.name,
                gold: pl.listed,
                sub: pl.listed ? l.listedAt(money(context, pl.listedPrice!)) : '${l.value} ${money(context, pl.value)}',
                subColor: pl.listed ? context.glm.goldText : null,
                end: Icon(Icons.sell_rounded, color: pl.listed ? p.gold : p.textMuted, size: 20),
                onTap: () async {
                  final changed = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => _SellSheet(player: pl, leagueId: leagueId, repo: ref.read(marketRepositoryProvider)),
                  );
                  if (changed == true) ref.invalidate(sellingProvider(leagueId));
                },
              ),
          ]),
        ]),
      ),
    );
  }
}

class _SellSheet extends StatefulWidget {
  const _SellSheet({required this.player, required this.leagueId, required this.repo});

  final MyPlayer player;
  final int leagueId;
  final MarketRepository repo;

  @override
  State<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<_SellSheet> {
  late double _price = (widget.player.listedPrice ?? widget.player.value).clamp(widget.player.floor, widget.player.cap).toDouble();
  int? _wait;
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _quote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _quote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final q = await widget.repo.sellQuote(widget.leagueId, widget.player.id, _price.round());
        if (mounted) setState(() => _wait = q.waitHours);
      } on ApiError {
        // The wait is a hint only.
      }
    });
  }

  Future<void> _do(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
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
    final pl = widget.player;
    final fee = pl.quickFee.currency == 'coins' ? l.coinsWord(pl.quickFee.amount) : money(context, pl.quickFee.amount);
    final step = pl.cap > pl.floor ? ((pl.cap - pl.floor) / 50).ceilToDouble() : 1.0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(pl.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: 4),
          Text('${l.value} ${money(context, pl.value)}', textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 14),
          if (pl.listed) ...[
            Text(l.listedAt(money(context, pl.listedPrice!)), textAlign: TextAlign.center, style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 18)),
            if (pl.sellsAt != null) Text(l.sellsIn(when(context, pl.sellsAt!.toLocal())), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 10),
            GlmButton(label: l.unlist, variant: GlmButtonVariant.outline, block: true, loading: _busy, onPressed: () => _do(() => widget.repo.unlist(widget.leagueId, pl.id))),
          ] else if (pl.cap > pl.floor) ...[
            Text('${l.price}: ${money(context, _price.round())}', textAlign: TextAlign.center, style: TextStyle(fontFamily: GlmFonts.numbers, fontFamilyFallback: const [GlmFonts.body], fontSize: 22, fontWeight: FontWeight.w800, color: context.glm.goldText)),
            Slider(
              value: _price,
              min: pl.floor.toDouble(),
              max: pl.cap.toDouble(),
              divisions: ((pl.cap - pl.floor) / step).round().clamp(1, 50),
              activeColor: p.gold,
              onChanged: (v) {
                setState(() => _price = v);
                _quote();
              },
            ),
            Text(l.priceRange(money(context, pl.floor), money(context, pl.cap)), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
            if (_wait != null) Text(l.waitAbout(_wait!), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            GlmButton(label: l.listForSale, block: true, loading: _busy, onPressed: () => _do(() => widget.repo.listForSale(widget.leagueId, pl.id, _price.round()))),
            // [Sprint 50 M18] Or at this price as an auction's opening bid.
            AuctionListing(leagueId: widget.leagueId, playerId: pl.id, price: _price.round(), onListed: () => Navigator.pop(context, true)),
          ],
          const SizedBox(height: 10),
          GlmButton(
            label: l.sellNowFor(money(context, pl.quickPays), fee),
            variant: GlmButtonVariant.danger,
            block: true,
            onPressed: _busy
                ? null
                : () async {
                    if (await confirm(context, l.sellNowConfirm)) await _do(() => widget.repo.sellNow(widget.leagueId, pl.id));
                  },
          ),
        ]),
      ),
    );
  }
}

class _OffersTab extends ConsumerWidget {
  const _OffersTab(this.leagueId);

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    Future<void> answer(int offer, String action) async {
      try {
        await ref.read(marketRepositoryProvider).answer(leagueId, offer, action);
      } on ApiError catch (e) {
        if (context.mounted) showGlmToast(context, e.message, error: true);
      }
      ref.invalidate(dealsProvider(leagueId));
      ref.invalidate(sellingProvider(leagueId));
    }

    Future<void> answerLoan(int loan, bool accept) async {
      try {
        await ref.read(marketRepositoryProvider).answerLoan(leagueId, loan, accept);
      } on ApiError catch (e) {
        if (context.mounted) showGlmToast(context, e.message, error: true);
      }
      ref.invalidate(loansProvider(leagueId));
    }

    Future<void> open(int club, String name, {int? counterOf, Set<int> want = const {}, Set<int> give = const {}}) async {
      final d = ref.read(dealsProvider(leagueId)).value;
      final sent = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => OfferScreen(leagueId: leagueId, clubId: club, clubName: name, counterOf: counterOf, want: want, give: give,
            fairMinBp: d?.fairMinBp ?? 5000, fairMaxBp: d?.fairMaxBp ?? 20000),
      ));
      if (sent == true) {
        ref.invalidate(dealsProvider(leagueId));
        ref.invalidate(loansProvider(leagueId));
      }
    }

    return AsyncView(
      value: ref.watch(dealsProvider(leagueId)),
      onRetry: () => ref.invalidate(dealsProvider(leagueId)),
      data: (d) => RefreshIndicator(
        color: p.gold,
        onRefresh: () => ref.refresh(dealsProvider(leagueId).future),
        child: ListView(padding: const EdgeInsets.all(12), children: [
          // [Sprint 18 D] A new offer to one of the league's coaches.
          GlmButton(
            label: l.newOffer,
            icon: const Icon(Icons.add_rounded),
            block: true,
            onPressed: () async {
              if (d.clubs.isEmpty) {
                showGlmToast(context, l.noCoachClubs);
                return;
              }
              final club = await showModalBottomSheet<({int id, String name})>(
                context: context,
                showDragHandle: true,
                builder: (ctx) => SafeArea(
                  child: ListView(shrinkWrap: true, children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(l.pickCoachClub, textAlign: TextAlign.center, style: ctx.text.titleMedium)),
                    for (final c in d.clubs) ListTile(title: Text(c.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start), onTap: () => Navigator.pop(ctx, c)),
                  ]),
                ),
              );
              if (club != null && context.mounted) await open(club.id, club.name);
            },
          ),
          const SizedBox(height: 12),
          if (d.offers.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Text(l.noOffers, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))),
          for (final o in d.offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlmCard(
                gold: o.incoming && o.pending,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(o.incoming ? l.offerFrom(o.from) : l.offerTo(o.to), style: const TextStyle(fontWeight: FontWeight.w800))),
                    if (!o.pending)
                      Text(switch (o.status) { 'accepted' => l.statusAccepted, 'rejected' => l.statusRejected, _ => l.statusOther },
                          style: TextStyle(color: o.status == 'accepted' ? context.glm.successText : p.textMuted, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Text(l.theyWant, style: TextStyle(color: p.textMuted, fontSize: 12)),
                  for (final pl in o.players) Text('${pl.name} (${pl.position} ${pl.overall})', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                  if (o.give.isNotEmpty || o.money > 0) ...[
                    const SizedBox(height: 6),
                    Text(l.theyGive, style: TextStyle(color: p.textMuted, fontSize: 12)),
                    if (o.money > 0) Text(money(context, o.money), textDirection: TextDirection.ltr, style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 18, color: context.glm.goldText)),
                    for (final pl in o.give) Text('${pl.name} (${pl.position} ${pl.overall})', textDirection: TextDirection.ltr),
                  ],
                  if (o.pending) ...[
                    const SizedBox(height: 10),
                    if (o.incoming) ...[
                      Row(children: [
                        Expanded(child: GlmButton(label: l.accept, onPressed: () => answer(o.id, 'accept'))),
                        const SizedBox(width: 8),
                        Expanded(child: GlmButton(label: l.reject, variant: GlmButtonVariant.outline, onPressed: () => answer(o.id, 'reject'))),
                      ]),
                      const SizedBox(height: 6),
                      // My terms instead: his players he offered are those I may ask for, mine he asked for those I may give.
                      GlmButton(
                        label: l.counterOffer,
                        variant: GlmButtonVariant.quiet,
                        block: true,
                        onPressed: () => open(o.fromId, o.from, counterOf: o.id, want: {for (final x in o.give) x.id}, give: {for (final x in o.players) x.id}),
                      ),
                    ]
                    else
                      GlmButton(label: l.cancelOffer, variant: GlmButtonVariant.outline, block: true, onPressed: () => answer(o.id, 'cancel')),
                  ],
                ]),
              ),
            ),
          ...?ref.watch(loansProvider(leagueId)).value?.loans.let((loans) => [
                if (loans.isNotEmpty) SectionTitle(l.loans),
                for (final x in loans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      gold: x.mine && x.pending,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(l.loanOf(x.player, x.owner, x.borrower), style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(l.loanTerms(x.rounds, money(context, x.fee)), style: TextStyle(color: p.textMuted)),
                        if (x.mine && x.pending) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: GlmButton(label: l.accept, onPressed: () => answerLoan(x.id, true))),
                            const SizedBox(width: 8),
                            Expanded(child: GlmButton(label: l.reject, variant: GlmButtonVariant.outline, onPressed: () => answerLoan(x.id, false))),
                          ]),
                        ],
                      ]),
                    ),
                  ),
              ]),
          const SizedBox(height: GlmSize.radiusXl),
        ]),
      ),
    );
  }
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// [Sprint 18 D] The youth academy (X61 E3): this period's prospects, their potential as a range, signed at the price.
class _AcademyTab extends ConsumerWidget {
  const _AcademyTab(this.leagueId);

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    return AsyncView(
      value: ref.watch(academyProvider(leagueId)),
      onRetry: () => ref.invalidate(academyProvider(leagueId)),
      data: (a) => ListView(padding: const EdgeInsets.all(12), children: [
        Text(l.academyLead(a.signed, a.perSeason), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
        if (a.renewsAt != null) Text(l.renewsAt(when(context, a.renewsAt!.toLocal())), textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
        const SizedBox(height: 12),
        GameGrid(minWidth: 300, children: [
          for (final x in a.prospects)
            GlmCard(
              accent: lineColor(x.line).bg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  RatingBadge(x.overall, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        PositionChip(x.position, x.line),
                        const SizedBox(width: 8),
                        Flexible(child: Text(x.name, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800))),
                      ]),
                      const SizedBox(height: 4),
                      Text('${x.age} · ${x.nationality ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 12)),
                      Text(l.potentialRange(x.potentialFrom, x.potentialTo), style: TextStyle(color: context.glm.goldText, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                GlmButton(
                  label: l.signProspect(money(context, x.price)),
                  onPressed: a.signed >= a.perSeason
                      ? null
                      : () async {
                          if (!await confirm(context, l.signProspectConfirm(x.name, money(context, x.price))) || !context.mounted) return;
                          try {
                            await ref.read(marketRepositoryProvider).signProspect(leagueId, x.id);
                            if (context.mounted) showGlmToast(context, l.bought);
                          } on ApiError catch (e) {
                            if (context.mounted) showGlmToast(context, e.message, error: true);
                          }
                          ref.invalidate(academyProvider(leagueId));
                        },
                ),
              ]),
            ),
        ]),
      ]),
    );
  }
}
