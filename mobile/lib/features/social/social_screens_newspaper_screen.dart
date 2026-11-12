part of 'social_screens.dart';

class NewspaperScreen extends ConsumerWidget {
  const NewspaperScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.newspaper,
      AsyncView(
        value: ref.watch(newspaperProvider(leagueId)),
        onRetry: () => ref.invalidate(newspaperProvider(leagueId)),
        data: (d) {
          final p = context.palette;
          final e = d['edition'] as Map<dynamic, dynamic>?;
          final articles = d['articles'] as List<dynamic>? ?? const [];
          final pending = d['pending'] as List<dynamic>? ?? const [];
          Future<void> decide(int id, bool publish) async {
            await _try(context, () => ref.read(socialRepositoryProvider).decide(leagueId, id, publish));
            ref.invalidate(newspaperProvider(leagueId));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (e == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.noEdition,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted),
                  ),
                )
              else ...[
                for (final s in (e['stories'] as List<dynamic>? ?? const []))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlmCard(
                      gold: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${(s as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                          Text('${s['text']}', style: TextStyle(color: p.textMuted)),
                        ],
                      ),
                    ),
                  ),
                SectionTitle(l.roundResults(e['round'] as int? ?? 0)),
                GlmCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: [
                      for (final r in (e['results'] as List<dynamic>? ?? const []))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${(r as Map<dynamic, dynamic>)['home']}',
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              Text(
                                '${r['home_goals']} - ${r['away_goals']}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontFamily: GlmFonts.numbers, fontWeight: FontWeight.w800),
                              ),
                              Expanded(
                                child: Text('${r['away']}', textDirection: TextDirection.ltr, textAlign: TextAlign.end),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (e['coach'] is Map<dynamic, dynamic>) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Text('🎩', style: TextStyle(fontSize: 22)),
                    title: Text(l.coachOfRound),
                    subtitle: Text(
                      '${((e['coach'] as Map<dynamic, dynamic>)['coach'] as Map<dynamic, dynamic>?)?['name'] ?? ''} · ${(e['coach'] as Map<dynamic, dynamic>)['club'] ?? ''}',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              if (d['is_owner'] == true && pending.isNotEmpty) ...[
                SectionTitle(l.pendingArticles),
                for (final a in pending)
                  GlmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${(a as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                        Text('${a['body']}'),
                        Text(
                          '${(a['author'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GlmButton(label: l.publish, onPressed: () => decide(a['id'] as int, true)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlmButton(
                                label: l.reject,
                                variant: GlmButtonVariant.outline,
                                onPressed: () => decide(a['id'] as int, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              SectionTitle(l.articles),
              for (final a in articles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${(a as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                        const SizedBox(height: 4),
                        Text('${a['body']}'),
                        const SizedBox(height: 4),
                        Text(
                          [
                            (a['author'] as Map<dynamic, dynamic>?)?['name'] ?? '',
                            if (DateTime.tryParse('${a['at']}') != null) when(context, DateTime.parse('${a['at']}').toLocal()),
                          ].join(' · '),
                          style: TextStyle(color: p.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              if (d['wrote_this_round'] != true)
                GlmButton(
                  label: l.writeArticle,
                  variant: GlmButtonVariant.outline,
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _write(context, ref, d['max'] as int? ?? 2000),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref, int max) async {
    final l = L.of(context);
    final title = TextEditingController(), body = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: title,
              maxLength: 120,
              decoration: InputDecoration(labelText: l.articleTitle),
            ),
            TextField(
              controller: body,
              maxLength: max,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(labelText: l.articleBody),
            ),
            const SizedBox(height: 8),
            GlmButton(label: l.send, block: true, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (send == true && context.mounted) {
      final r = await _try(context, () => ref.read(socialRepositoryProvider).write(leagueId, title.text.trim(), body.text.trim()));
      if (r != null && context.mounted) showGlmToast(context, l.articleSent);
      ref.invalidate(newspaperProvider(leagueId));
    }
    title.dispose();
    body.dispose();
  }
}

/// [Sprint 18 G] Open a group by its invite code (a link gamelegendmanager.online/groups/join/CODE, or typed).
Future<void> joinGroup(BuildContext context, WidgetRef ref, String code) async {
  final r = await _try(context, () => ref.read(apiProvider).post('/groups/join/${code.trim().toLowerCase()}'));
  ref.invalidate(groupsProvider);
  final g = r?['group'] as Map<dynamic, dynamic>?;
  if (g != null && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(groupId: g['id'] as int, name: '${g['name']}'),
      ),
    );
  }
}
