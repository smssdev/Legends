part of 'squad_screen.dart';

/// [X105, the owner's request 2026-11-22] The squad screen's rivals: picking another club of the league, and the action
/// under a player's card (mine sold, another coach's asked for).
extension _Rivals on _SquadScreenState {
  /// [X105] The league's other clubs, the next opponent first: a tap opens his squad here.
  Future<void> _pickRival(BuildContext context) async {
    final l = L.of(context);
    final c = context.palette;
    final summary = ref.read(clubSummaryProvider(widget.leagueId)).value;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: c.panel,
      builder: (context) => SafeArea(
        child: Consumer(
          builder: (context, ref, _) => AsyncView(
            value: ref.watch(leagueClubsProvider(widget.leagueId)),
            onRetry: () => ref.invalidate(leagueClubsProvider(widget.leagueId)),
            data: (clubs) {
              final next = summary?.next?.id;
              final others = [
                for (final x in clubs)
                  if (x.id != summary?.club.id && x.id != widget.clubId) x,
              ]..sort((a, b) => (a.id == next ? 0 : 1).compareTo(b.id == next ? 0 : 1));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(GlmSpace.md, 0, GlmSpace.md, GlmSpace.md),
                itemCount: others.length,
                itemBuilder: (context, i) {
                  final x = others[i];
                  return ListTile(
                    minTileHeight: GlmTouch.app + 8,
                    leading: ClubCrest(url: x.crestUrl, name: x.code, size: 36),
                    title: Text(
                      x.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                    ),
                    subtitle: Text(
                      [if (x.id == next) l.nextRival, x.coach == null ? l.runByComputer : l.coachedBy(x.coach!)].join(' · '),
                      style: glmText(GlmType.caption, color: x.id == next ? context.glm.goldText : c.textMuted),
                    ),
                    onTap: () => Navigator.pop(context, x.id),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    if (picked != null && context.mounted) await context.push<void>('/leagues/${widget.leagueId}/squad?club=$picked');
  }

  /// [X105] Under a player's card: mine for sale (the market's own sheet), another coach's asked for with an offer.
  Widget? _cardAction(BuildContext context, Player pl, RivalSquad? rival) {
    final l = L.of(context);
    if (rival == null) {
      return GlmButton(
        label: l.sellPlayer,
        icon: const GlmIcon(GlmIcons.market, size: 20),
        variant: GlmButtonVariant.outline,
        block: true,
        onPressed: () => sellFromSquad(context, ref, widget.leagueId, pl.id),
      );
    }
    if (rival.coach == null) return null;
    return GlmButton(
      label: l.askForPlayer,
      icon: const GlmIcon(GlmIcons.handshake, size: 20),
      block: true,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OfferScreen(leagueId: widget.leagueId, clubId: rival.id, clubName: rival.name, want: {pl.id}),
        ),
      ),
    );
  }
}

/// [X105] Another club's facts in the same navy band: its crest and name, who runs it, its players and its value.
class _RivalBand extends StatelessWidget {
  const _RivalBand({required this.rival});

  final RivalSquad rival;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    final ps = rival.team.players;
    final rating = ps.isEmpty
        ? 0
        : (ps.map((x) => x.overall).toList()..sort((a, b) => b.compareTo(a))).take(11).fold(0, (a, b) => a + b) ~/ ps.take(11).length;
    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlmSpace.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: glmText(GlmType.caption, color: p.textMuted, fontWeight: FontWeight.w700),
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: glmText(
              GlmType.title,
              fontFamily: GlmFonts.numbers,
              fontFamilyFallback: const [GlmFonts.body],
              fontWeight: FontWeight.w800,
              color: p.goldLight,
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GlmStage.cardRaised, GlmStage.card]),
      ),
      child: Row(
        children: [
          ClubCrest(url: rival.crestUrl, name: rival.code, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rival.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: p.text),
                ),
                Text(
                  rival.coach == null ? l.runByComputer : l.coachedBy(rival.coach!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: glmText(GlmType.caption, color: p.textSoft, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          fact(l.teamRating, '$rating'),
          fact(l.squad, '${ps.length}'),
          fact(l.squadValue, money(context, rival.team.squadValue)),
        ],
      ),
    );
  }
}
