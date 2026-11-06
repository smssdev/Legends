import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/game.dart';
import '../../ui/widgets/glm_card.dart';
import '../../ui/widgets/motion.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/widgets.dart' show when;
import 'money_data.dart';

/// [Sprint 18 F1] The club's money (the web's FinancePage): the balance and the season, the ticket price, the three
/// sponsors of the stands (one offer each, for the season) and the ledger. Every number comes from the server.
class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key, required this.leagueId});

  final int leagueId;

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
    } on ApiError catch (e) {
      if (context.mounted) showGlmToast(context, e.message, error: true);
    }
    ref.invalidate(financeProvider(leagueId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final repo = ref.read(moneyRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.finance)),
      body: GlmBackground(
        wide: true,
        child: AsyncView(
          value: ref.watch(financeProvider(leagueId)),
          onRetry: () => ref.invalidate(financeProvider(leagueId)),
          data: (f) {
            final p = context.palette;
            final num = TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, fontSize: 20, color: p.text);
            const gap = SizedBox(height: 12);
            Widget stat(String label, int v, {Color? color}) => Expanded(
                  child: Column(children: [
                    Text(money(context, v), textDirection: TextDirection.ltr, style: num.copyWith(color: color)),
                    Text(label, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted, fontSize: 12)),
                  ]),
                );
            return RefreshIndicator(
              color: p.gold,
              onRefresh: () => ref.refresh(financeProvider(leagueId).future),
              // [2026-11-06, stage 3] In landscape: the balance and the tickets on one side, sponsors and the ledger on the other.
              child: GamePanes(startFlex: 1, endFlex: 1, start: [
                GlmCard(
                  gold: true,
                  accent: f.balance < 0 ? p.live : p.gold,
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 18, color: p.textMuted),
                      const SizedBox(width: 6),
                      Text(l.balance, style: TextStyle(color: p.textMuted)),
                    ]),
                    CountUp(f.balance, format: (v) => money(context, v),
                        style: num.copyWith(fontSize: 44, color: f.balance < 0 ? context.glm.liveText : context.glm.goldText)),
                    if (!f.canSpend) ...[
                      const SizedBox(height: 6),
                      Text(l.inDebt(f.debtRounds, f.debtLimit), textAlign: TextAlign.center, style: TextStyle(color: context.glm.liveText, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 14),
                    Row(children: [
                      stat(l.seasonIncome, f.income, color: context.glm.successText),
                      stat(l.seasonExpenses, f.expenses, color: context.glm.liveText),
                      stat(l.wagesPerRound, f.wagesPerRound),
                    ]),
                  ]),
                ),
                gap,
                SectionTitle(l.ticketPrice),
                GlmCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    for (final t in f.tickets.levels)
                      RadioListTile<String>(
                        value: t.level,
                        // ignore: deprecated_member_use
                        groupValue: f.tickets.level,
                        // ignore: deprecated_member_use
                        onChanged: (v) => _act(context, ref, () => repo.setTickets(leagueId, v!)),
                        activeColor: p.gold,
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${l.perMatch(money(context, t.perMatch))} · ${l.attendance(t.attendanceBp ~/ 100)}'),
                      ),
                  ]),
                ),
              ], end: [
                SectionTitle(l.sponsors),
                for (final s in f.sponsors)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlmCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(s.name, style: context.text.titleMedium),
                        const SizedBox(height: 8),
                        for (final o in s.offers)
                          if (s.chosen == null || s.chosen == o.offer)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: s.chosen == o.offer ? p.gold : p.surfaceRaised),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text([l.perMatch(money(context, o.perMatch)), if (o.perWin > 0) l.perWin(money(context, o.perWin))].join(' · ')),
                                trailing: s.chosen == o.offer ? Text(l.signed, style: TextStyle(color: context.glm.successText, fontWeight: FontWeight.w800)) : const Icon(Icons.chevron_right_rounded),
                                onTap: s.chosen != null
                                    ? null
                                    : () async {
                                        if (await confirm(context, l.signSponsorConfirm) && context.mounted) {
                                          await _act(context, ref, () => repo.signSponsor(leagueId, s.sector, o.offer));
                                        }
                                      },
                              ),
                            ),
                      ]),
                    ),
                  ),
                gap,
                SectionTitle(l.transactions),
                GlmCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(children: [
                    for (final t in f.transactions)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: IconTile(t.amount >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded, size: 32, color: t.amount >= 0 ? p.success : p.live),
                        title: Text(t.label),
                        subtitle: t.at == null ? null : Text(when(context, t.at!.toLocal())),
                        trailing: Text('${t.amount > 0 ? '+' : ''}${money(context, t.amount)}', textDirection: TextDirection.ltr,
                            style: TextStyle(fontFamily: GlmFonts.numbers, fontSize: 17, fontWeight: FontWeight.w800, color: t.amount >= 0 ? context.glm.successText : context.glm.liveText)),
                      ),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// A yes or no before something that spends or binds.
Future<bool> confirm(BuildContext context, String question) async {
  final l = L.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(question),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
          ],
        ),
      ) ??
      false;
}
