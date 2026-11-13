import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import 'tournaments_data.dart';

/// The draw: before it, its time (the organizer sets it); after, the balls one by one on the shared clock.
class DrawScreen extends ConsumerStatefulWidget {
  const DrawScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends ConsumerState<DrawScreen> {
  Timer? _tick;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return screenPage(
      l.watchDraw,
      AsyncView(
        value: ref.watch(drawProvider(widget.id)),
        onRetry: () => ref.invalidate(drawProvider(widget.id)),
        data: (d) {
          final p = context.palette;
          _offset = d.serverNow - DateTime.now().millisecondsSinceEpoch;
          final steps = d.steps;
          final drawnAt = DateTime.tryParse(d.drawnAt ?? '');
          final drawAt = DateTime.tryParse(d.drawAt ?? '');
          final revealMs = d.revealMs;
          final now = DateTime.now().millisecondsSinceEpoch + _offset;
          final shown = drawnAt == null ? 0 : ((now - drawnAt.millisecondsSinceEpoch) ~/ revealMs + 1).clamp(0, steps.length);
          if (drawnAt == null && drawAt != null && now >= drawAt.millisecondsSinceEpoch) {
            // Its time has come: ask again for the balls.
            Future.microtask(() => ref.invalidate(drawProvider(widget.id)));
          }
          final groups = <int, List<api.TournamentsDrawAnswerStepsItem>>{};
          for (final s in steps.take(shown)) {
            if (s.group case final g?) (groups[g] ??= []).add(s);
          }
          final last = shown == 0 ? null : steps[shown - 1];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (drawnAt == null) ...[
                Text(
                  drawAt == null ? l.drawNotSet : l.drawAt(when(context, drawAt.toLocal())),
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
                if (d.canSchedule) ...[
                  const SizedBox(height: 10),
                  GlmButton(
                    label: l.scheduleDraw,
                    icon: const Icon(Icons.schedule_rounded),
                    onPressed: () async {
                      final at = await pickWhen(context, DateTime.now());
                      if (at == null || !context.mounted) return;
                      await tryAction(
                        context,
                        () => ref.read(apiProvider).put('/leagues/${widget.id}/draw', {'draw_at': at.toUtc().toIso8601String()}),
                      );
                      ref.invalidate(drawProvider(widget.id));
                    },
                  ),
                ],
              ] else ...[
                Text(
                  l.drawnBalls(shown, steps.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.textMuted),
                ),
                if (last != null)
                  GlmCard(
                    gold: true,
                    child: Column(
                      children: [
                        ClubCrest(url: last.club?.crestUrl, name: last.club?.code ?? '', size: 64),
                        const SizedBox(height: 6),
                        Text(last.club?.name ?? '', textDirection: TextDirection.ltr, style: context.text.titleLarge),
                        if (last.group case final g?)
                          Text(
                            l.groupN(String.fromCharCode(64 + g)),
                            style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                for (final g in (groups.keys.toList()..sort()))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.groupN(String.fromCharCode(64 + g)), style: const TextStyle(fontWeight: FontWeight.w800)),
                          for (final s in groups[g]!)
                            Text(s.club?.name ?? '', textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
