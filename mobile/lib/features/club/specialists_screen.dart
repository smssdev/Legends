import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import '../money/finance_screen.dart' show confirm;
import 'extras_data.dart';
import 'squad_screen.dart' show money;

class SpecialistsScreen extends ConsumerWidget {
  const SpecialistsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.specialists,
      AsyncView(
        value: ref.watch(specialistsProvider(leagueId)),
        onRetry: () => ref.invalidate(specialistsProvider(leagueId)),
        data: (s) {
          final p = context.palette;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.specialistsLead(s.days),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              for (final sp in s.list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: sp.stars > 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(sp.name, style: context.text.titleMedium)),
                            if (sp.stars > 0)
                              Text(
                                '${'★' * sp.stars}${sp.endsAt != null ? '  ${l.hiredUntil(when(context, sp.endsAt!.toLocal()))}' : ''}',
                                style: TextStyle(color: context.glm.goldText),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final o in sp.offers)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('★' * o.stars, style: TextStyle(color: p.gold)),
                            subtitle: Text(o.effect),
                            trailing: GlmButton(
                              label: '${l.hire} ${o.currency == 'coins' ? l.coinsWord(o.cost) : money(context, o.cost)}',
                              variant: GlmButtonVariant.outline,
                              onPressed: sp.stars > 0
                                  ? null
                                  : () async {
                                      if (!await confirm(
                                            context,
                                            l.hireConfirm(o.currency == 'coins' ? l.coinsWord(o.cost) : money(context, o.cost)),
                                          ) ||
                                          !context.mounted) {
                                        return;
                                      }
                                      await tryAction(context, () => ref.read(extrasRepositoryProvider).hire(leagueId, sp.type, o.stars));
                                      ref.invalidate(specialistsProvider(leagueId));
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
