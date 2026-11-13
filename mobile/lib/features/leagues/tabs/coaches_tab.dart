import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/async_view.dart';
import '../../../ui/widgets/glm_background.dart';
import '../../../ui/widgets/glm_button.dart';
import '../../../ui/widgets/glm_card.dart';
import '../leagues_repository.dart';
import '../models.dart';
import 'more_tab.dart';

class CoachesTab extends ConsumerWidget {
  const CoachesTab(this.lg, {super.key});

  final League lg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = context.palette;
    final invite = l.inviteText(lg.name, lg.inviteUrl ?? '');
    // Inside the «more» section and the page before a team: a column, not a list of its own.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlmCard(
          gold: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.invite, style: context.text.titleMedium),
              const SizedBox(height: 8),
              SelectableText(
                lg.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlmFonts.numbers,
                  fontSize: 30,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                  color: context.glm.goldText,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GlmButton(
                      label: l.share,
                      icon: const Icon(Icons.share_rounded),
                      onPressed: () => SharePlus.instance.share(ShareParams(text: invite)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlmButton(
                      label: l.code,
                      variant: GlmButtonVariant.quiet,
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: lg.code));
                        showGlmToast(context, l.copied);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (lg.isOwner) ...[
          SectionTitle(l.requests),
          AsyncView(
            value: ref.watch(requestsProvider(lg.id)),
            data: (reqs) => Column(
              children: [
                for (final r in reqs.where((r) => r.status == 'pending'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${r.name}${r.username == null ? '' : ' · @${r.username}'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: l.approve,
                            icon: Icon(Icons.check_circle_rounded, color: p.success),
                            onPressed: () async {
                              await ref.read(leaguesRepositoryProvider).decide(lg.id, r.id, true);
                              ref
                                ..invalidate(requestsProvider(lg.id))
                                ..invalidate(leagueProvider(lg.id));
                            },
                          ),
                          IconButton(
                            tooltip: l.reject,
                            icon: Icon(Icons.cancel_rounded, color: p.live),
                            onPressed: () async {
                              await ref.read(leaguesRepositoryProvider).decide(lg.id, r.id, false);
                              ref.invalidate(requestsProvider(lg.id));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        SectionTitle('${l.tabCoaches} · ${lg.members.length}'),
        for (final m in lg.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: p.brand,
              child: Text(
                m.name.characters.take(1).toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text([if (m.club != null) m.club!, if (m.isOwner) l.creator, if (m.onHoliday) l.onHoliday].join(' · ')),
            trailing: m.userId == null ? null : const Icon(Icons.chevron_right_rounded),
            onTap: m.userId == null ? null : () => context.push('/coaches/${m.userId}'),
          ),
        // [Sprint 18] The creator answers a holiday and may remove a coach, with a reason everyone sees.
        if (lg.isOwner)
          for (final m in lg.members.where((m) => !m.isOwner))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (m.vacationRequest != null) ...[
                    Text(
                      l.vacationAsk(m.vacationRequest!.days, m.vacationRequest!.reason),
                      style: TextStyle(color: p.textMuted, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => ownerAction(context, ref, '/leagues/${lg.id}/members/${m.id}/vacation/approve'),
                      child: Text(l.approve),
                    ),
                    TextButton(
                      onPressed: () => ownerAction(context, ref, '/leagues/${lg.id}/members/${m.id}/vacation/reject'),
                      child: Text(l.reject),
                    ),
                  ],
                  TextButton(
                    onPressed: () async {
                      final reason = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: Text('${l.kick}: ${m.name}'),
                          content: TextField(
                            controller: reason,
                            maxLength: 200,
                            decoration: InputDecoration(labelText: l.kickReason),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.kick)),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await ownerAction(context, ref, '/leagues/${lg.id}/members/${m.id}/kick', {'reason': reason.text.trim()});
                      }
                      reason.dispose();
                    },
                    child: Text(l.kick, style: TextStyle(color: context.glm.liveText)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
