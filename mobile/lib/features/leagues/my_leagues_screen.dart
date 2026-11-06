import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import 'leagues_repository.dart';

/// [Sprint 16 F1] My leagues: each with its state and my place in it, and the two ways in.
class MyLeaguesScreen extends ConsumerWidget {
  const MyLeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l.myLeagues)),
      body: GlmBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(myLeaguesProvider.future),
          child: AsyncView(
            value: ref.watch(myLeaguesProvider),
            onRetry: () => ref.invalidate(myLeaguesProvider),
            data: (leagues) => ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: GlmButton(label: l.createLeague, icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/leagues/new'))),
                const SizedBox(width: 10),
                Expanded(child: GlmButton(label: l.joinByCode, variant: GlmButtonVariant.quiet, onPressed: () => context.push('/join'))),
              ]),
              const SizedBox(height: 16),
              if (leagues.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(l.noLeagues, textAlign: TextAlign.center, style: TextStyle(color: p.textMuted))),
              for (final lg in leagues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    onTap: () => context.push('/leagues/${lg.id}'),
                    child: Row(children: [
                      Icon(lg.isOwner ? Icons.workspace_premium_rounded : Icons.emoji_events_outlined, color: p.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(lg.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            lg.myRequest == 'pending' ? l.requestPending : lg.canPick ? l.requestApproved : '${l.clubsCount(lg.teamCount)} · ${lg.code}',
                            style: TextStyle(color: lg.canPick ? context.glm.goldText : p.textMuted, fontSize: 13),
                          ),
                        ]),
                      ),
                      if (lg.isOwner && lg.pendingRequests > 0)
                        CircleAvatar(radius: 12, backgroundColor: p.live, child: Text('${lg.pendingRequests}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                      const Icon(Icons.chevron_left_rounded),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
