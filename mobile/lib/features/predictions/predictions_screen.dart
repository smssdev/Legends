import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/page.dart';
import '../social/social_data.dart';

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  api.Predictions? _fresh;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return screenPage(
      l.predictions,
      AsyncView(
        value: ref.watch(predictionsProvider(widget.leagueId)),
        onRetry: () => ref.invalidate(predictionsProvider(widget.leagueId)),
        data: (loaded) {
          final d = _fresh ?? loaded;
          final p = context.palette;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.predictionsLead(d.round ?? 0, money(context, d.reward ?? 0)),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              const SizedBox(height: 12),
              for (final m in d.matches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.home.name,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Text(' — '),
                            Expanded(
                              child: Text(
                                m.away.name,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!m.open)
                          Text(
                            l.predictionClosed,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.textMuted),
                          )
                        else
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            emptySelectionAllowed: true,
                            segments: [
                              ButtonSegment(
                                value: 'home',
                                label: Text(m.home.code, textDirection: TextDirection.ltr),
                              ),
                              ButtonSegment(value: 'draw', label: Text(l.draw)),
                              ButtonSegment(
                                value: 'away',
                                label: Text(m.away.code, textDirection: TextDirection.ltr),
                              ),
                            ],
                            selected: {?m.mine},
                            onSelectionChanged: (s) async {
                              if (s.isEmpty) return;
                              final r = await tryAction(
                                context,
                                () => ref.read(socialRepositoryProvider).predict(widget.leagueId, m.fixtureId, s.first),
                              );
                              if (r != null && mounted) setState(() => _fresh = r);
                            },
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
