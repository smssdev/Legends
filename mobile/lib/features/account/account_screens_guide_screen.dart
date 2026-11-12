part of 'account_screens.dart';

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.guide,
      AsyncView(
        value: ref.watch(guideProvider),
        onRetry: () => ref.invalidate(guideProvider),
        data: (sections) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final s in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlmCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ExpansionTile(
                    shape: const Border(),
                    title: Text('${(s as Map<dynamic, dynamic>)['title']}', style: context.text.titleMedium),
                    children: [
                      for (final t in (s['topics'] as List<dynamic>? ?? const []))
                        ExpansionTile(
                          shape: const Border(),
                          title: Text('${(t as Map<dynamic, dynamic>)['q']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('${t['a']}'))],
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

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
