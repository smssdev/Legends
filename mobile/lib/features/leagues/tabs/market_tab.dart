import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/game.dart';
import '../models.dart';

class MarketTab extends StatelessWidget {
  const MarketTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    void go(String path) => context.push('/leagues/${lg.id}/$path');
    return GamePanes(
      startFlex: 1,
      endFlex: 1,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      start: [
        MenuSection(
          title: l.secDeals,
          icon: Icons.swap_horiz_rounded,
          items: [
            MenuItem(Icons.storefront_rounded, l.market, () => go('market'), subtitle: l.subMarket),
            MenuItem(Icons.travel_explore_rounded, l.scout, () => go('scout'), subtitle: l.subScout, color: p.brandLight),
          ],
        ),
      ],
      end: [
        MenuSection(
          title: l.secMoney,
          icon: Icons.payments_rounded,
          items: [
            MenuItem(Icons.account_balance_wallet_rounded, l.finance, () => go('finance'), subtitle: l.subFinance, color: p.success),
            MenuItem(Icons.stadium_rounded, l.stadium, () => go('stadium'), subtitle: l.subStadium),
            MenuItem(Icons.confirmation_number_rounded, l.cheerTickets, () => go('tickets'), subtitle: l.subTickets, color: p.warning),
          ],
        ),
      ],
    );
  }
}
