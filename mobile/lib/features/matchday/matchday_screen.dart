import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/size_class.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'matchday_data.dart';

class MatchdayScreen extends ConsumerWidget {
  const MatchdayScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return screenPage(
      l.matchday,
      AsyncView(
        value: ref.watch(nextMatchProvider(leagueId)),
        onRetry: () => ref.invalidate(nextMatchProvider(leagueId)),
        data: (m) {
          if (m == null) return Center(child: Text(l.noNextMatch));
          final p = context.palette;
          final fixture = m.fixtureId;
          final at = DateTime.tryParse(m.scheduledAt);
          final move = m.move;
          final pending = move?.pending;
          Future<void> act(Future<Object?> Function() a, [String? done]) async {
            final r = await tryAction(context, a);
            if (r != null && done != null && context.mounted) showGlmToast(context, done);
            ref.invalidate(nextMatchProvider(leagueId));
            ref.invalidate(pressProvider((leagueId, fixture)));
            ref.invalidate(integrityProvider(leagueId));
          }

          final parts = <Widget>[
            GlmCard(
              gold: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ClubCrest(url: m.club.crestUrl, name: m.club.code, size: 48),
                            Text(m.club.name, textDirection: TextDirection.ltr),
                          ],
                        ),
                      ),
                      Text(m.venue == 'away' ? l.away : l.home, style: TextStyle(color: p.textMuted)),
                      Expanded(
                        child: Column(
                          children: [
                            ClubCrest(url: m.opponent.crestUrl, name: m.opponent.code, size: 48),
                            Text(m.opponent.name, textDirection: TextDirection.ltr),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (at != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        when(context, at.toLocal()),
                        style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700),
                      ),
                    ),
                  // [Sprint 59 F1] The server sends the referee's strictness (a word), not a map: the app never showed it.
                  if (m.referee case final r?) Text('${l.referee}: ${refereeName(l, r)}', style: TextStyle(color: p.textMuted)),
                ],
              ),
            ),
            if (move != null && at != null && (pending != null || move.hours.isNotEmpty)) ...[
              SectionTitle(l.moveMatch),
              GlmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pending != null) ...[
                      Text(
                        pending.mine
                            ? l.movePendingMine(when(context, DateTime.parse(pending.toAt).toLocal()))
                            : l.movePendingTheirs(when(context, DateTime.parse(pending.toAt).toLocal())),
                      ),
                      const SizedBox(height: 8),
                      if (pending.mine)
                        GlmButton(
                          label: l.cancelRequest,
                          variant: GlmButtonVariant.outline,
                          onPressed: () => act(() => api.delete('/leagues/$leagueId/team/moves/${pending.id}')),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: GlmButton(
                                label: l.accept,
                                onPressed: () => act(() => api.post('/leagues/$leagueId/team/moves/${pending.id}/accept')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlmButton(
                                label: l.reject,
                                variant: GlmButtonVariant.outline,
                                onPressed: () => act(() => api.post('/leagues/$leagueId/team/moves/${pending.id}/decline')),
                              ),
                            ),
                          ],
                        ),
                    ] else ...[
                      Text(l.moveLead(move.movesLeft), style: TextStyle(color: p.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final h in move.hours)
                            ActionChip(
                              label: Text(
                                '${h < 0 ? l.hoursEarlier(-h) : l.hoursLater(h)} · ${when(context, at.toLocal().add(Duration(hours: h)))}',
                              ),
                              onPressed: () =>
                                  act(() => api.post('/leagues/$leagueId/team/moves', {'fixture_id': fixture, 'hours': h}), l.moveSent),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            ...?ref.watch(pressProvider((leagueId, fixture))).value?.let((pr) {
              final mineFirst = pr.mine == 'home';
              final said = mineFirst ? pr.said.home : pr.said.away;
              final reading = mineFirst ? pr.reading.home : pr.reading.away;
              final ch = pr.chances;
              return [
                SectionTitle(l.press),
                GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.chances(mineFirst ? ch.home : ch.away, ch.draw, mineFirst ? ch.away : ch.home),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (pr.mine != null) Text(reading, style: TextStyle(color: p.textMuted)),
                      const SizedBox(height: 8),
                      if (said != null)
                        Text(
                          '${l.youSaid}: ${pr.statements.where((s) => s.kind == said).firstOrNull?.text ?? said}',
                          style: TextStyle(color: context.glm.goldText),
                        )
                      else if (!pr.open)
                        Text(l.pressOpensAt(when(context, DateTime.parse(pr.opensAt).toLocal())), style: TextStyle(color: p.textMuted))
                      else
                        for (final s in pr.statements)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.text),
                            subtitle: Text(l.stakes(s.stakes.win, s.stakes.draw, s.stakes.loss)),
                            trailing: const Icon(Icons.mic_rounded),
                            onTap: () => act(() => api.post('/leagues/$leagueId/press/$fixture', {'kind': s.kind})),
                          ),
                    ],
                  ),
                ),
              ];
            }),
            ...?ref.watch(integrityProvider(leagueId)).value?.let((g) {
              if (!g.on_ || g.fixture == null) return const <Widget>[];
              final bribe = g.bribe;
              final security = g.security;
              final spies = g.spiesOnMe;
              final bribeText = l.bribe(money(context, bribe.money), price(context, bribe.extra.currency, bribe.extra.amount));
              return [
                SectionTitle(l.integrity),
                GlmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (bribe.paid)
                        Text(
                          l.bribePaid,
                          style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700),
                        )
                      else ...[
                        GlmButton(
                          label: bribeText,
                          variant: GlmButtonVariant.outline,
                          onPressed: () async {
                            if (await confirm(context, bribeText) && context.mounted) {
                              await act(() => api.post('/leagues/$leagueId/integrity/bribe', {'fixture_id': fixture}));
                            }
                          },
                        ),
                        Text(l.bribeNote(bribe.varPercent), style: glmText(GlmType.caption, color: p.textMuted)),
                      ],
                      const SizedBox(height: 10),
                      if (!security.sees)
                        GlmButton(
                          label: l.securityCheck(price(context, security.cost.currency, security.cost.amount)),
                          variant: GlmButtonVariant.outline,
                          onPressed: () => act(() => api.post('/leagues/$leagueId/integrity/security', {'fixture_id': fixture})),
                        )
                      else ...[
                        Text(l.spiesOnMe, style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (spies.isEmpty) Text(l.noSpies, style: TextStyle(color: p.textMuted)),
                        for (final s in spies)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Text(
                                s.club,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (!s.turned) ...[
                                TextButton(
                                  onPressed: () => act(() => api.post('/leagues/$leagueId/integrity/spies/${s.id}/turn')),
                                  child: Text(l.turnSpy(price(context, g.doubleAgent.currency, g.doubleAgent.amount))),
                                ),
                                TextButton(
                                  onPressed: () => act(() => api.post('/leagues/$leagueId/integrity/spies/${s.id}/accuse')),
                                  child: Text(l.accuse),
                                ),
                              ] else
                                Icon(Icons.check_rounded, color: p.gold),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ];
            }),
          ];
          // [Sprint 73 D5] On a landscape screen the match's card stays in view at the start and everything to do
          // about it (moving it, the press, the referee) scrolls beside it: it was one long page, 781px under a
          // first screen that showed the card alone.
          return LayoutBuilder(
            builder: (context, box) {
              if (GlmFit.isNarrow(box.maxWidth) || parts.length < 2) {
                return ListView(padding: const EdgeInsets.all(12), children: parts);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 6, 12), child: parts.first),
                  ),
                  Expanded(
                    flex: 5,
                    child: ListView(padding: const EdgeInsetsDirectional.fromSTEB(6, 12, 12, 12), children: parts.sublist(1)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
