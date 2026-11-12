part of 'market_screen.dart';

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
    widget.repo
        .buyQuote(widget.leagueId, widget.player.id)
        .then(
          (q) {
            if (mounted) setState(() => _q = q);
          },
          onError: (Object e) {
            if (mounted) setState(() => _error = ApiError.from(e).message);
          },
        );
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RatingBadge(pl.overall, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pl.name, textDirection: TextDirection.ltr, style: context.text.titleLarge),
                      Text(
                        [
                          pl.position,
                          '${pl.age}',
                          if (pl.nationality != null) pl.nationality!,
                          if (pl.potential != null) '${l.potentialWord} ${pl.potential}',
                        ].join(' · '),
                        style: TextStyle(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in pl.attributes.entries)
                  Chip(
                    label: Text(
                      '${e.key.toUpperCase()} ${e.value}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: TextStyle(color: context.glm.liveText)),
            if (q == null && _error == null)
              const Center(
                child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
              ),
            if (q != null) ...[
              if (q.docCoins > 0) Text(l.regFee(q.docCoins), style: TextStyle(color: p.textMuted)),
              if (q.why != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    q.why!,
                    style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700),
                  ),
                ),
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
          ],
        ),
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
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              l.listingsOf(s.listed, s.maxListings),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted),
            ),
            const SizedBox(height: 8),
            GameGrid(
              minWidth: 300,
              children: [
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
              ],
            ),
          ],
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(pl.name, textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${l.value} ${money(context, pl.value)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted),
            ),
            const SizedBox(height: 14),
            if (pl.listed) ...[
              Text(
                l.listedAt(money(context, pl.listedPrice!)),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              if (pl.sellsAt != null)
                Text(
                  l.sellsIn(when(context, pl.sellsAt!.toLocal())),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
              const SizedBox(height: 10),
              GlmButton(
                label: l.unlist,
                variant: GlmButtonVariant.outline,
                block: true,
                loading: _busy,
                onPressed: () => _do(() => widget.repo.unlist(widget.leagueId, pl.id)),
              ),
            ] else if (pl.cap > pl.floor) ...[
              Text(
                '${l.price}: ${money(context, _price.round())}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlmFonts.numbers,
                  fontFamilyFallback: const [GlmFonts.body],
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.glm.goldText,
                ),
              ),
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
              Text(
                l.priceRange(money(context, pl.floor), money(context, pl.cap)),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 12),
              ),
              if (_wait != null)
                Text(
                  l.waitAbout(_wait!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
              const SizedBox(height: 10),
              GlmButton(
                label: l.listForSale,
                block: true,
                loading: _busy,
                onPressed: () => _do(() => widget.repo.listForSale(widget.leagueId, pl.id, _price.round())),
              ),
              // [Sprint 50 M18] Or at this price as an auction's opening bid.
              AuctionListing(
                leagueId: widget.leagueId,
                playerId: pl.id,
                price: _price.round(),
                onListed: () => Navigator.pop(context, true),
              ),
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
          ],
        ),
      ),
    );
  }
}
