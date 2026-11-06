import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_card.dart';
import '../leagues/shell.dart';

/// [Sprint 19 F1] Which notifications the account wants (`/notifications`, Sprint 36): the six kinds, on the phone and in
/// the browser alike, and the two emails. Whether the server can push to the app at all is shown on top.
final notificationSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.read(apiProvider).get('/notifications'));

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Map<String, dynamic>? _fresh;

  Future<void> _put(Map<String, Object> body) async {
    try {
      final v = await ref.read(apiProvider).put('/notifications', body);
      if (mounted) setState(() => _fresh = v);
    } on ApiError catch (e) {
      if (mounted) showGlmToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      appBar: GameBar(title: Text(l.notifications)),
      body: GlmBackground(
        child: AsyncView(
          value: ref.watch(notificationSettingsProvider),
          onRetry: () => ref.invalidate(notificationSettingsProvider),
          data: (loaded) {
            final s = _fresh ?? loaded;
            final p = context.palette;
            final ready = s['app_enabled'] == true;
            final names = {
              'referee': l.kindReferee, 'match_soon': l.kindMatchSoon, 'offers': l.kindOffers, 'done': l.kindDone, 'news': l.kindNews, 'absence': l.kindAbsence,
            };
            final emailReady = s['email_ready'] == true;
            return ListView(padding: const EdgeInsets.all(12), children: [
              GlmCard(
                gold: ready,
                child: Row(children: [
                  Icon(ready ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: ready ? p.gold : p.textMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(ready ? l.pushReady : l.pushNotReady)),
                ]),
              ),
              const SizedBox(height: 12),
              GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  for (final k in (s['kinds'] as List? ?? const []))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: (k as Map)['on'] == true,
                      activeThumbColor: p.gold,
                      title: Text(names[k['kind']] ?? '${k['kind']}'),
                      onChanged: (v) => _put({'kinds': {'${k['kind']}': v}}),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              GlmCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  for (final (key, label) in [('email_match', l.emailMatch), ('email_offers', l.emailOffers)])
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: s[key] == true,
                      activeThumbColor: p.gold,
                      title: Text(label),
                      subtitle: emailReady ? null : Text(l.emailNeeded, style: TextStyle(color: p.textMuted, fontSize: 12)),
                      onChanged: (v) => _put({key: v}),
                    ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
