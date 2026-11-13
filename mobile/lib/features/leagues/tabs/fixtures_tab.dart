import '../../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/async_view.dart';
import '../leagues_repository.dart';
import '../models.dart';
import '../widgets.dart';

class FixturesTab extends ConsumerWidget {
  const FixturesTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(fixturesProvider(lg.id).future),
      child: AsyncView(
        value: ref.watch(fixturesProvider(lg.id)),
        onRetry: () => ref.invalidate(fixturesProvider(lg.id)),
        data: (all) {
          final shown = all.where((f) => !f.isBye).toList();
          if (shown.isEmpty) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noMatches, textAlign: TextAlign.center),
                ),
              ],
            );
          }
          // Grouped by round (league) or stage (cup), in their order.
          final groups = <String, List<Fixture>>{};
          for (final f in shown) {
            groups.putIfAbsent(f.competition == 'cup' ? '${l.cup} · ${f.stage ?? ''}' : l.round(f.round ?? 0), () => []).add(f);
          }
          final firstOpen = groups.keys.toList().indexWhere((k) => groups[k]!.any((f) => !f.finished));
          final keys = groups.keys.toList();
          // [Sprint 61 F3] Only the rounds in view are built.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final k = keys[i];
              return ExpansionTile(
                initiallyExpanded: i == firstOpen || (firstOpen == -1 && i == groups.length - 1),
                title: Text(k, style: context.text.titleMedium),
                subtitle: groups[k]!.first.at == null
                    ? null
                    : Text(when(context, groups[k]!.first.at!), style: glmText(GlmType.caption, color: context.palette.textMuted)),
                children: [for (final f in groups[k]!) FixtureTile(f, mine: lg.myClubId)],
              );
            },
          );
        },
      ),
    );
  }
}
