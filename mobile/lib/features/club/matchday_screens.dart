import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'squad_screen.dart' show money;
import '../leagues/shell.dart';
import '../../api/gen/models.g.dart' as api;
import '../../api/read.dart';

part 'matchday_screens_contracts_screen.dart';
part 'matchday_screens_missed_screen.dart';

/// [Sprint 18 I] The club's match-day panels in the app (the web's NextMatch, Contracts and Tickets panels): moving
/// the next match by hours with the other coach's yes (Sprint 27 B2), the press conference (UP12), what goes on behind
/// the scenes (X28: the referee, a security check, the spies), the contracts (X61 E1) and the cheer tickets (X25).
/// [Sprint 59 F1] My next match through the generated model (`NextMatch`).
final nextMatchProvider = FutureProvider.autoDispose.family<api.NextMatch?, int>(
  (ref, l) async => JsonReader(
    await ref.read(apiProvider).get('/leagues/$l/team/next-match'),
    'NextMatchAnswer',
  ).objectOrNull('match', api.NextMatch.fromJson),
);

/// [Sprint 59 F1] The press conference through the generated model (`PressConference`).
final pressProvider = FutureProvider.autoDispose.family<api.PressConference?, (int, int)>(
  (ref, k) async => JsonReader(
    await ref.read(apiProvider).get('/leagues/${k.$1}/press/${k.$2}'),
    'PressAnswer',
  ).objectOrNull('press', api.PressConference.fromJson),
);
final integrityProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, l) => ref.read(apiProvider).get('/leagues/$l/integrity'),
);

/// [Sprint 59 F1] The contracts through the generated model (`Contracts`).
final contractsProvider = FutureProvider.autoDispose.family<api.Contracts, int>(
  (ref, l) async => api.Contracts.fromJson(await ref.read(apiProvider).get('/leagues/$l/team/contracts')),
);

/// [Sprint 59 F1] The matches I missed through the generated model (`MissedMatch`).
final missedProvider = FutureProvider.autoDispose.family<List<api.MissedMatch>, int>(
  (ref, l) async =>
      JsonReader(await ref.read(apiProvider).get('/leagues/$l/team/missed'), 'Missed').list('matches', api.MissedMatch.fromJson),
);
final ticketsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>(
  (ref, l) => ref.read(apiProvider).get('/leagues/$l/tickets'),
);

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

/// A price as the server gives it ({currency, amount}): coins or club money.
String price(BuildContext context, Object? p) {
  final m = p as Map<dynamic, dynamic>? ?? const {};
  final n = (m['amount'] as num? ?? 0).toInt();
  return m['currency'] == 'coins' ? L.of(context).coinsWord(n) : money(context, n);
}

/// The referee's strictness in the coach's language.
String refereeName(L l, String strictness) => switch (strictness) {
  'very_lenient' => l.refereeVeryLenient,
  'lenient' => l.refereeLenient,
  'strict' => l.refereeStrict,
  'very_strict' => l.refereeVeryStrict,
  _ => l.refereeMedium,
};

Widget _page(String title, Widget body) => Scaffold(
  appBar: GameBar(title: Text(title)),
  body: GlmBackground(child: body),
);

class MatchdayScreen extends ConsumerWidget {
  const MatchdayScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return _page(
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
            final r = await _try(context, a);
            if (r != null && done != null && context.mounted) showGlmToast(context, done);
            ref.invalidate(nextMatchProvider(leagueId));
            ref.invalidate(pressProvider((leagueId, fixture)));
            ref.invalidate(integrityProvider(leagueId));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
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
                if (g['on'] != true || g['fixture'] == null) return const <Widget>[];
                final bribe = g['bribe'] as Map<dynamic, dynamic>? ?? const {};
                final security = g['security'] as Map<dynamic, dynamic>? ?? const {};
                final spies = (g['spies_on_me'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>();
                return [
                  SectionTitle(l.integrity),
                  GlmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (bribe['paid'] == true)
                          Text(
                            l.bribePaid,
                            style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700),
                          )
                        else ...[
                          GlmButton(
                            label: l.bribe(money(context, (bribe['money'] as num? ?? 0).toInt()), price(context, bribe['extra'])),
                            variant: GlmButtonVariant.outline,
                            onPressed: () async {
                              if (await confirm(
                                    context,
                                    l.bribe(money(context, (bribe['money'] as num? ?? 0).toInt()), price(context, bribe['extra'])),
                                  ) &&
                                  context.mounted) {
                                await act(() => api.post('/leagues/$leagueId/integrity/bribe', {'fixture_id': fixture}));
                              }
                            },
                          ),
                          Text(l.bribeNote(bribe['var_percent'] as int? ?? 0), style: TextStyle(color: p.textMuted, fontSize: 12)),
                        ],
                        const SizedBox(height: 10),
                        if (security['sees'] != true)
                          GlmButton(
                            label: l.securityCheck(price(context, security['cost'])),
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
                                  '${s['club']}',
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                if (s['turned'] != true) ...[
                                  TextButton(
                                    onPressed: () => act(() => api.post('/leagues/$leagueId/integrity/spies/${s['id']}/turn')),
                                    child: Text(l.turnSpy(price(context, g['double_agent']))),
                                  ),
                                  TextButton(
                                    onPressed: () => act(() => api.post('/leagues/$leagueId/integrity/spies/${s['id']}/accuse')),
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
            ],
          );
        },
      ),
    );
  }
}
