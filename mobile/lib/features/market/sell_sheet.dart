import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/cut.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../club/squad_screen.dart' show money;
import '../club/team_data.dart' show teamProvider;
import '../console/market_console.dart' show AuctionListing;
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'market_data.dart';

/// [X114, the owner's request 2026-11-22] One of my players' sale, from the market's sell tab or from his card in the
/// squad (as on the site): listed at a price, as an auction, or sold now. A player whose line is at the squad's floor
/// shows why and cannot be sold (the server's rule, App\Market\SquadFloor).
Future<void> showSellSheet(BuildContext context, WidgetRef ref, int leagueId, MyPlayer player) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SellSheet(player: player, leagueId: leagueId, repo: ref.read(marketRepositoryProvider)),
  );
  if (changed == true) {
    ref
      ..invalidate(sellingProvider(leagueId))
      ..invalidate(teamProvider(leagueId));
  }
}

/// The sheet for a player of my squad by his id: his sale's numbers are read from the market first.
Future<void> sellFromSquad(BuildContext context, WidgetRef ref, int leagueId, int playerId) async {
  try {
    final selling = await ref.read(sellingProvider(leagueId).future);
    final mine = selling.mine.where((x) => x.id == playerId).firstOrNull;
    if (!context.mounted) return;
    if (selling.closed != null) return showGlmToast(context, selling.closed!, error: true);
    if (mine == null) return;
    await showSellSheet(context, ref, leagueId, mine);
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
  }
}

class SellSheet extends StatefulWidget {
  const SellSheet({super.key, required this.player, required this.leagueId, required this.repo});

  final MyPlayer player;
  final int leagueId;
  final MarketRepository repo;

  @override
  State<SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<SellSheet> {
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
            // [X114] His line is at the squad's floor: the reason, and no way to sell him (a listing can still go).
            if (pl.held != null && !pl.listed) ...[
              Container(
                padding: const EdgeInsets.all(GlmSpace.md),
                decoration: ShapeDecoration(shape: GlmCut.shape(GlmCut.badge), color: p.surfaceSunk),
                child: Text(
                  pl.held!,
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.body, color: p.textSoft, fontWeight: FontWeight.w700),
                ),
              ),
            ] else if (pl.listed) ...[
              Text(
                l.listedAt(money(context, pl.listedPrice!)),
                textAlign: TextAlign.center,
                style: glmText(GlmType.title, color: context.glm.goldText, fontWeight: FontWeight.w800),
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
                style: glmText(
                  GlmType.headline,
                  fontFamily: GlmFonts.numbers,
                  fontFamilyFallback: const [GlmFonts.body],
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
                style: glmText(GlmType.caption, color: p.textMuted),
              ),
              if (_wait != null)
                Text(
                  l.waitAbout(_wait!),
                  textAlign: TextAlign.center,
                  style: glmText(GlmType.caption, color: p.textMuted),
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
            if (pl.held == null) ...[
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
          ],
        ),
      ),
    );
  }
}
