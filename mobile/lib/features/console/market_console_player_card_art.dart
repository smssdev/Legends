part of 'market_console.dart';

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
                style: glmText(GlmType.display, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: p.onGold),
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
                  style: glmText(GlmType.caption, fontWeight: FontWeight.w800, color: p.onGold),
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
          style: glmText(GlmType.bodyLg, fontWeight: FontWeight.w800, color: p.goldLight),
        ),
        Text(
          closed ? l.talkClosed : l.roundOf(n.round + 1, n.rounds + 1),
          style: glmText(GlmType.caption, color: closed ? p.danger : p.textMuted),
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
