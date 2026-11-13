import '../../ui/tokens.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../account/account_data.dart';
import '../leagues/page.dart';

/// [X18] The coaches' ranking: titles first, then wins.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.ranking,
      AsyncView(
        value: ref.watch(rankingProvider),
        onRetry: () => ref.invalidate(rankingProvider),
        isEmpty: (rows) => rows.isEmpty,
        data: (rows) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final r in rows)
              ListTile(
                leading: Text(
                  '${r.position}',
                  style: glmText(GlmType.title, fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                ),
                title: Text(r.coach.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${l.trophiesShort(r.trophies.total)} · ${r.won}/${r.played} · ${r.rating.points}'),
                onTap: () => context.push('/coaches/${r.coach.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
