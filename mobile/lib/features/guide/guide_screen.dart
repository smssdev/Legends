import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_card.dart';
import '../account/account_data.dart';
import '../leagues/page.dart';

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
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
                    title: Text(s.title, style: context.text.titleMedium),
                    children: [
                      for (final t in s.topics)
                        ExpansionTile(
                          shape: const Border(),
                          title: Text(t.q, style: const TextStyle(fontWeight: FontWeight.w700)),
                          children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(t.a))],
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
