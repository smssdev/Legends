part of 'account_screens.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = context.palette;
    return _page(
      l.support,
      Column(
        children: [
          Expanded(
            child: AsyncView(
              value: ref.watch(supportProvider),
              onRetry: () => ref.invalidate(supportProvider),
              data: (messages) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    l.supportLead,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted),
                  ),
                  const SizedBox(height: 10),
                  for (final m in messages)
                    Align(
                      alignment: m.fromTeam ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: m.fromTeam ? p.gold.withValues(alpha: .14) : p.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m.fromTeam)
                              Text(
                                l.fromTeam,
                                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            Text(m.body),
                            if (DateTime.tryParse(m.at) != null)
                              Text(when(context, DateTime.parse(m.at).toLocal()), style: TextStyle(color: p.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(hintText: l.typeMessage, counterText: ''),
                    ),
                  ),
                  IconButton(
                    tooltip: l.send,
                    icon: Icon(Icons.send_rounded, color: p.gold),
                    onPressed: () async {
                      final body = _text.text.trim();
                      if (body.isEmpty) return;
                      if (await _try(context, () => ref.read(apiProvider).post('/support', {'body': body})) != null) _text.clear();
                      ref.invalidate(supportProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.announcements,
      AsyncView(
        value: ref.watch(announcementsProvider),
        onRetry: () => ref.invalidate(announcementsProvider),
        data: (cards) => cards.isEmpty
            ? Center(child: Text(l.noAnnouncements))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final a in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlmCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (a.imageUrl != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(a.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(a.title, style: context.text.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(a.body),
                                  if (a.cta case final cta?) ...[
                                    const SizedBox(height: 8),
                                    GlmButton(
                                      label: cta.label,
                                      variant: GlmButtonVariant.brand,
                                      onPressed: () => launchUrl(Uri.parse(cta.url), mode: LaunchMode.externalApplication),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
