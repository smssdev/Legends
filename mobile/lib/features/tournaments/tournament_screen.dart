import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/page.dart';
import '../leagues/widgets.dart' show when;
import 'tournaments_data.dart';

class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
      l.tournaments,
      AsyncView(
        value: ref.watch(tournamentProvider(id)),
        onRetry: () => ref.invalidate(tournamentProvider(id)),
        data: (t) {
          final p = context.palette;
          final entry = t.entry;
          final groups = <String, List<api.TournamentTeam>>{};
          for (final x in t.teams) {
            if (x.group case final g?) (groups[g] ??= []).add(x);
          }
          final code = t.code;
          Future<void> act(Future<Object?> Function() a) async {
            await tryAction(context, a);
            ref.invalidate(tournamentProvider(id));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              GlmCard(
                gold: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.name, style: context.text.titleLarge),
                    Text('${templateName(l, t.template ?? '')} · ${l.teamsCount(t.teamCount)}', style: TextStyle(color: p.textMuted)),
                    if (DateTime.tryParse(t.startsAt) case final at?) Text('${l.startsOn}: ${when(context, at.toLocal())}'),
                    const SizedBox(height: 10),
                    Text(l.tournamentCode, style: TextStyle(color: p.textMuted, fontSize: 12)),
                    SelectableText(
                      code,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GlmFonts.numbers,
                        fontSize: 28,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: context.glm.goldText,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GlmButton(
                            label: l.share,
                            icon: const Icon(Icons.share_rounded),
                            onPressed: () => SharePlus.instance.share(ShareParams(text: '${AppConfig.siteUrl}/join/$code')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlmButton(
                            label: l.code,
                            variant: GlmButtonVariant.quiet,
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              showGlmToast(context, l.copied);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (entry.mode == 'draw' && (entry.canEnter || entry.isEntrant))
                GlmButton(
                  label: entry.isEntrant ? l.leaveEntry : l.enter,
                  variant: entry.isEntrant ? GlmButtonVariant.outline : GlmButtonVariant.primary,
                  block: true,
                  onPressed: () => act(
                    () => entry.isEntrant
                        ? ref.read(apiProvider).delete('/tournaments/$id/entry')
                        : ref.read(apiProvider).post('/tournaments/$id/entry'),
                  ),
                ),
              const SizedBox(height: 8),
              GlmButton(
                label: l.watchDraw,
                variant: GlmButtonVariant.brand,
                icon: const Icon(Icons.casino_rounded),
                block: true,
                onPressed: () => context.push('/tournaments/$id/draw'),
              ),
              if (entry.isMember && t.status != 'waiting') ...[
                const SizedBox(height: 8),
                GlmButton(
                  label: l.openLeague,
                  variant: GlmButtonVariant.outline,
                  block: true,
                  onPressed: () => context.push('/leagues/$id'),
                ),
              ],
              const SizedBox(height: 12),
              for (final g in (groups.keys.toList()..sort()))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.groupN(g), style: context.text.titleMedium),
                        for (final x in groups[g]!)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                ClubCrest(url: x.crestUrl, name: x.code, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(x.name, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                                ),
                                if (x.coach case final coach?) Text(coach, style: TextStyle(color: p.textMuted, fontSize: 12)),
                              ],
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
