import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../account/account_data.dart';
import '../leagues/page.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  final title = TextEditingController(), body = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final api = ref.read(apiProvider);
    return screenPage(
      l.ideas,
      AsyncView(
        value: ref.watch(ideasProvider),
        onRetry: () => ref.invalidate(ideasProvider),
        data: (d) {
          final p = context.palette;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final poll in d.polls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlmCard(
                    gold: poll.state == 'open',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(poll.question, style: context.text.titleMedium),
                        if (poll.body case final b?) Text(b, style: TextStyle(color: p.textMuted)),
                        for (final o in poll.options)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(poll.myVote == o.id ? Icons.radio_button_checked : Icons.radio_button_off, color: p.gold),
                            title: Text(o.label),
                            trailing: o.votes == null ? null : Text(l.votes(o.votes!), style: TextStyle(color: p.textMuted)),
                            onTap: poll.state != 'open' || poll.myVote != null
                                ? null
                                : () async {
                                    await tryAction(context, () => api.post('/ideas/polls/${poll.id}/vote', {'option_id': o.id}));
                                    ref.invalidate(ideasProvider);
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
              GlmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.ideasLead(d.leftToday), style: TextStyle(color: p.textMuted)),
                    TextField(
                      controller: title,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: l.articleTitle),
                    ),
                    TextField(
                      controller: body,
                      maxLength: 2000,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(labelText: l.articleBody),
                    ),
                    GlmButton(
                      label: l.suggest,
                      onPressed: d.leftToday == 0
                          ? null
                          : () async {
                              final r = await tryAction(
                                context,
                                () => api.post('/ideas/suggestions', {'title': title.text.trim(), 'body': body.text.trim()}),
                              );
                              if (r != null && context.mounted) {
                                showGlmToast(context, l.suggestionSent);
                                title.clear();
                                body.clear();
                              }
                              ref.invalidate(ideasProvider);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final sgg in d.suggestions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sgg.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      switch (sgg.status) {
                        'accepted' => l.statusAccepted,
                        'built' => l.statusBuilt,
                        'rejected' => l.statusRejected,
                        _ => l.statusPending,
                      },
                      if (sgg.coins > 0) l.coinsWord(sgg.coins),
                      ?sgg.reply,
                    ].join(' · '),
                  ),
                ),
              if (d.honours.isNotEmpty) ...[
                SectionTitle(l.honourRoll),
                for (final h in d.honours)
                  ListTile(
                    dense: true,
                    leading: Text(
                      '${h.rank}',
                      style: TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800, color: context.glm.goldText),
                    ),
                    title: Text(h.user.name),
                    trailing: Text('${h.count}'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
