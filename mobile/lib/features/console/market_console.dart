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
              style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: p.goldLight),
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
                  style: TextStyle(color: p.textMuted, fontSize: 12),
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
                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 16, color: p.goldLight),
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
                  style: TextStyle(fontSize: 11, color: a.leading ? p.success : p.goldLight),
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
              style: TextStyle(color: p.textMuted, fontSize: 12),
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
            child: GlmModel3D(
              model: 'player_card',
              label: a.name,
              orbit: '0deg 80deg 2.6m',
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                row(l.marketValue, money(context, a.value), colour: p.success),
                row(l.auctionOpening, money(context, a.opening)),
                row(l.auctionTop, a.top == null ? '-' : money(context, a.top!), colour: p.goldLight),
                if (a.mine != null) row(l.yourBid, money(context, a.mine!)),
                Text(
                  l.auctionEnds(_left(a.endsAt)),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.goldLight, fontWeight: FontWeight.w700, fontSize: 12),
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

/// The card drawn where the 3D one cannot turn (the tests, a phone without a web view): gold, the rating and the line.
class PlayerCardArt extends StatelessWidget {
  const PlayerCardArt({super.key, required this.overall, required this.position, required this.name});

  final int overall;
  final String position, name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0015)
          ..rotateY(-.3),
        child: Container(
          width: 100,
          height: 142,
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.goldLight, p.goldDark]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(-6, 8))],
          ),
          child: Column(
            children: [
              Text(
                '$overall',
                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 30, color: p.onGold),
              ),
              Text(
                position,
                style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w700, color: p.onGold),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: p.onGold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [Sprint 50 M19] Buying a coach's player at once at his release clause: the server's price, a confirmation, done.
class ReleaseClauseButton extends ConsumerStatefulWidget {
  const ReleaseClauseButton({super.key, required this.leagueId, required this.playerId, this.onDone});

  final int leagueId, playerId;
  final VoidCallback? onDone;

  @override
  ConsumerState<ReleaseClauseButton> createState() => _ReleaseClauseButtonState();
}

class _ReleaseClauseButtonState extends ConsumerState<ReleaseClauseButton> {
  bool _busy = false;

  Future<void> _go() async {
    final l = L.of(context);
    final repo = ref.read(consoleRepositoryProvider);
    setState(() => _busy = true);
    try {
      final q = await repo.releaseQuote(widget.leagueId, widget.playerId);
      if (!mounted) return;
      if (!q.can) {
        showGlmToast(context, q.why ?? '', error: true);
        return;
      }
      if (!await confirm(context, l.releaseClauseConfirm(money(context, q.clause), q.club))) return;
      await repo.payRelease(widget.leagueId, widget.playerId);
      if (!mounted) return;
      showGlmToast(context, l.bought);
      ref.invalidate(auctionsProvider(widget.leagueId));
      ref.invalidate(clubSummaryProvider(widget.leagueId));
      widget.onDone?.call();
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => GlmButton(
    label: L.of(context).payRelease,
    block: true,
    loading: _busy,
    icon: const Icon(Icons.bolt_rounded, size: 18),
    onPressed: _go,
  );
}

/// [Sprint 50 M19] The talk with a computer club over one of its players: its ask, the round, and the coach's offer.
Future<bool?> showNegotiation(BuildContext context, {required int leagueId, required int playerId, required String name}) =>
    showCompactInputSheet<bool>(
      context,
      title: '${L.of(context).negotiate} · $name',
      builder: (_) => _Negotiation(leagueId: leagueId, playerId: playerId),
    );

class _Negotiation extends ConsumerStatefulWidget {
  const _Negotiation({required this.leagueId, required this.playerId});

  final int leagueId, playerId;

  @override
  ConsumerState<_Negotiation> createState() => _NegotiationState();
}

class _NegotiationState extends ConsumerState<_Negotiation> {
  Negotiation? _n;
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(consoleRepositoryProvider)
        .negotiation(widget.leagueId, widget.playerId)
        .then(
          (n) {
            if (mounted) setState(() => _n = n);
          },
          onError: (Object e) {
            if (mounted) showGlmToast(context, ApiError.from(e).message, error: true);
          },
        );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null) return;
    setState(() => _busy = true);
    try {
      final n = await ref.read(consoleRepositoryProvider).offer(widget.leagueId, widget.playerId, amount);
      if (!mounted) return;
      if (n.bought) {
        ref.invalidate(clubSummaryProvider(widget.leagueId));
        Navigator.of(context).pop(true);
        showGlmToast(context, L.of(context).bought);
        return;
      }
      setState(() => _n = n);
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
    final n = _n;
    if (n == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final closed = n.status == 'closed';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.theyAsk(money(context, n.ask)),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.goldLight),
        ),
        Text(
          closed ? l.talkClosed : l.roundOf(n.round + 1, n.rounds + 1),
          style: TextStyle(color: closed ? p.danger : p.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        GlmCompactField(
          label: l.yourOffer,
          child: TextField(
            controller: _amount,
            enabled: !closed,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(isDense: true),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(height: 10),
        GlmButton(label: l.sendOffer, block: true, loading: _busy, onPressed: closed ? null : _send),
      ],
    );
  }
}

/// [Sprint 50 M18] Listing one of my players in an auction: its length, from the server's list.
class AuctionListing extends ConsumerWidget {
  const AuctionListing({super.key, required this.leagueId, required this.playerId, required this.price, required this.onListed});

  final int leagueId, playerId, price;
  final VoidCallback onListed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final minutes = ref.watch(auctionsProvider(leagueId)).value?.minutes ?? const [];
    if (minutes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        GlmSectionTitle(l.listAsAuction),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final m in minutes)
              ActionChip(
                label: Text(l.auctionMinutes(m)),
                onPressed: () async {
                  try {
                    await ref.read(consoleRepositoryProvider).listAuction(leagueId, playerId, price, m);
                    ref.invalidate(auctionsProvider(leagueId));
                    onListed();
                  } on ApiError catch (e) {
                    if (context.mounted) showGlmToast(context, e.message, error: true);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}
