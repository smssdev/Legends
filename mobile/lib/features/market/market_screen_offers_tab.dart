part of 'market_screen.dart';

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
      final sent = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => OfferScreen(
            leagueId: leagueId,
            clubId: club,
            clubName: name,
            counterOf: counterOf,
            want: want,
            give: give,
            fairMinBp: d?.fairMinBp ?? 5000,
            fairMaxBp: d?.fairMaxBp ?? 20000,
          ),
        ),
      );
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
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
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
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(l.pickCoachClub, textAlign: TextAlign.center, style: ctx.text.titleMedium),
                        ),
                        for (final c in d.clubs)
                          ListTile(
                            title: Text(c.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                            onTap: () => Navigator.pop(ctx, c),
                          ),
                      ],
                    ),
                  ),
                );
                if (club != null && context.mounted) await open(club.id, club.name);
              },
            ),
            const SizedBox(height: 12),
            if (d.offers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.noOffers,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
              ),
            for (final o in d.offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  gold: o.incoming && o.pending,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.incoming ? l.offerFrom(o.from) : l.offerTo(o.to),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (!o.pending)
                            Text(
                              switch (o.status) {
                                'accepted' => l.statusAccepted,
                                'rejected' => l.statusRejected,
                                _ => l.statusOther,
                              },
                              style: TextStyle(
                                color: o.status == 'accepted' ? context.glm.successText : p.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l.theyWant, style: TextStyle(color: p.textMuted, fontSize: 12)),
                      for (final pl in o.players)
                        Text('${pl.name} (${pl.position} ${pl.overall})', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                      if (o.give.isNotEmpty || o.money > 0) ...[
                        const SizedBox(height: 6),
                        Text(l.theyGive, style: TextStyle(color: p.textMuted, fontSize: 12)),
                        if (o.money > 0)
                          Text(
                            money(context, o.money),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontFamily: GlmFonts.numbers,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: context.glm.goldText,
                            ),
                          ),
                        for (final pl in o.give) Text('${pl.name} (${pl.position} ${pl.overall})', textDirection: TextDirection.ltr),
                      ],
                      if (o.pending) ...[
                        const SizedBox(height: 10),
                        if (o.incoming) ...[
                          Row(
                            children: [
                              Expanded(
                                child: GlmButton(label: l.accept, onPressed: () => answer(o.id, 'accept')),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GlmButton(
                                  label: l.reject,
                                  variant: GlmButtonVariant.outline,
                                  onPressed: () => answer(o.id, 'reject'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // My terms instead: his players he offered are those I may ask for, mine he asked for those I may give.
                          GlmButton(
                            label: l.counterOffer,
                            variant: GlmButtonVariant.quiet,
                            block: true,
                            onPressed: () => open(
                              o.fromId,
                              o.from,
                              counterOf: o.id,
                              want: {for (final x in o.give) x.id},
                              give: {for (final x in o.players) x.id},
                            ),
                          ),
                        ] else
                          GlmButton(
                            label: l.cancelOffer,
                            variant: GlmButtonVariant.outline,
                            block: true,
                            onPressed: () => answer(o.id, 'cancel'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ...?ref
                .watch(loansProvider(leagueId))
                .value
                ?.loans
                .let(
                  (loans) => [
                    if (loans.isNotEmpty) SectionTitle(l.loans),
                    for (final x in loans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlmCard(
                          gold: x.mine && x.pending,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l.loanOf(x.player, x.owner, x.borrower), style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(l.loanTerms(x.rounds, money(context, x.fee)), style: TextStyle(color: p.textMuted)),
                              if (x.mine && x.pending) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlmButton(label: l.accept, onPressed: () => answerLoan(x.id, true)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GlmButton(
                                        label: l.reject,
                                        variant: GlmButtonVariant.outline,
                                        onPressed: () => answerLoan(x.id, false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            const SizedBox(height: GlmSize.radiusXl),
          ],
        ),
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
      data: (a) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            l.academyLead(a.signed, a.perSeason),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted),
          ),
          if (a.renewsAt != null)
            Text(
              l.renewsAt(when(context, a.renewsAt!.toLocal())),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 12),
            ),
          const SizedBox(height: 12),
          GameGrid(
            minWidth: 300,
            children: [
              for (final x in a.prospects)
                GlmCard(
                  accent: lineColor(x.line).bg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          RatingBadge(x.overall, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PositionChip(x.position, x.line),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        x.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${x.age} · ${x.nationality ?? ''}', style: TextStyle(color: p.textMuted, fontSize: 12)),
                                Text(
                                  l.potentialRange(x.potentialFrom, x.potentialTo),
                                  style: TextStyle(color: context.glm.goldText, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GlmButton(
                        label: l.signProspect(money(context, x.price)),
                        onPressed: a.signed >= a.perSeason
                            ? null
                            : () async {
                                if (!await confirm(context, l.signProspectConfirm(x.name, money(context, x.price))) || !context.mounted) {
                                  return;
                                }
                                try {
                                  await ref.read(marketRepositoryProvider).signProspect(leagueId, x.id);
                                  if (context.mounted) showGlmToast(context, l.bought);
                                } on ApiError catch (e) {
                                  if (context.mounted) showGlmToast(context, e.message, error: true);
                                }
                                ref.invalidate(academyProvider(leagueId));
                              },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
