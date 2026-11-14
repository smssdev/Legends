import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';

/// [Sprint 64 F5] Where one of the club's numbers comes from (GET team/explain/{what}): its parts as the server counts them.
final explainProvider = FutureProvider.autoDispose.family<api.Explain, (int, String)>(
  (ref, k) async => api.Explain.fromJson(await ref.read(apiProvider).get('/leagues/${k.$1}/team/explain/${k.$2}')),
);

/// [Sprint 64 F5] A number a coach may ask about, as one widget for every screen: a tap opens «where it came from»
/// and its guide topic. Without a league (no club to read) it is only the number.
class ExplainTap extends StatelessWidget {
  const ExplainTap({super.key, required this.what, required this.leagueId, required this.child});

  /// chemistry, strength, morale or rating.
  final String what;
  final int? leagueId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final league = leagueId;
    if (league == null) return child;
    final l = L.of(context);
    final title = switch (what) {
      'chemistry' => l.explainChemistry,
      'strength' => l.explainStrength,
      'morale' => l.explainMorale,
      _ => l.explainRating,
    };
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _ExplainDialog(league: league, what: what, title: title),
        ),
        borderRadius: BorderRadius.circular(GlmRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: GlmTouch.app, minHeight: GlmTouch.app),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}

class _ExplainDialog extends ConsumerWidget {
  const _ExplainDialog({required this.league, required this.what, required this.title});

  final int league;
  final String what, title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: AsyncView(
          value: ref.watch(explainProvider((league, what))),
          onRetry: () => ref.invalidate(explainProvider((league, what))),
          data: (e) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${e.value}',
                textDirection: TextDirection.ltr,
                style: glmText(GlmType.headline, fontFamily: GlmFonts.numbers, color: context.glm.goldText),
              ),
              const SizedBox(height: GlmSpace.sm),
              for (final p in e.parts)
                Padding(
                  padding: const EdgeInsets.only(bottom: GlmSpace.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(p.label, style: glmText(GlmType.body))),
                      Text(
                        p.value,
                        textDirection: TextDirection.ltr,
                        style: glmText(GlmType.body, fontFamily: GlmFonts.numbers),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        GlmButton(
          label: l.readInGuide,
          variant: GlmButtonVariant.quiet,
          onPressed: () {
            Navigator.pop(context);
            context.push('/guide');
          },
        ),
      ],
    );
  }
}
