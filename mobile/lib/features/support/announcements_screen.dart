import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../account/account_data.dart';
import '../leagues/page.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return screenPage(
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
