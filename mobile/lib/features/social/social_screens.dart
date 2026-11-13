import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/tokens.g.dart';

import 'package:flutter/services.dart';

import '../../ui/widgets/console.dart';
import '../auth/auth_controller.dart';
import '../console/console_data.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/live/live_channels.dart';
import '../../core/api/api_client.dart';
import '../../core/api/intents.dart';
import '../../core/api/api_error.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/async_view.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/glm_background.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_card.dart';
import '../club/squad_screen.dart' show money;
import '../leagues/widgets.dart' show when;
import '../leagues/shell.dart';

import 'chat_controller.dart';
import '../../api/gen/models.g.dart' as api;

part 'social_screens_quick_match_screen.dart';
part 'social_screens_newspaper_screen.dart';
part 'social_screens_groups_screen.dart';
part 'social_screens_chat_screen.dart';

/// [Sprint 18 E] The league's social screens in the app: the friendlies (Sprint 24, a quick match played back fast),
/// the predictions and the newspaper (UP12), and the chat groups (Sprint 29). The server decides and writes all of it.
class SocialRepository {
  SocialRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> friendlies(int league) => _api.get('/leagues/$league/friendlies');
  Future<Map<String, dynamic>> playFriendly(int league, int opponent) => Intents.run(
    'friendly:$league:$opponent',
    (key) => _api.post('/leagues/$league/friendlies', {'opponent_id': opponent, 'idempotency_key': key}),
  );
  Future<Map<String, dynamic>> predictions(int league) => _api.get('/leagues/$league/predictions');
  Future<Map<String, dynamic>> predict(int league, int fixture, String pick) =>
      _api.post('/leagues/$league/predictions', {'fixture_id': fixture, 'pick': pick});

  /// [Sprint 59 F1] The newspaper through the generated model (`Newspaper`).
  Future<api.Newspaper> newspaper(int league) async => api.Newspaper.fromJson(await _api.get('/leagues/$league/newspaper'));
  Future<Map<String, dynamic>> write(int league, String title, String body) =>
      _api.post('/leagues/$league/newspaper/articles', {'title': title, 'body': body});
  Future<Map<String, dynamic>> decide(int league, int article, bool publish) =>
      _api.post('/leagues/$league/newspaper/articles/$article/decide', {'publish': publish});
  Future<Map<String, dynamic>> groups() => _api.get('/groups');
  Future<List<Map<String, dynamic>>> messages(int group) async => [
    for (final m in ((await _api.get('/groups/$group/messages'))['messages'] as List<dynamic>? ?? const [])) m as Map<String, dynamic>,
  ];
  Future<void> say(int group, String body, {int? replyTo}) => _api.post('/groups/$group/messages', {'body': body, 'reply_to': ?replyTo});
  Future<void> read(int group) => _api.post('/groups/$group/read');
}

final socialRepositoryProvider = Provider<SocialRepository>((ref) => SocialRepository(ref.watch(apiProvider)));
final friendliesProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).friendlies(l));
final predictionsProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).predictions(l));
final newspaperProvider = FutureProvider.autoDispose.family((ref, int l) => ref.read(socialRepositoryProvider).newspaper(l));
final groupsProvider = FutureProvider.autoDispose((ref) => ref.read(socialRepositoryProvider).groups());

Future<T?> _try<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiError catch (e) {
    if (context.mounted) showGlmToast(context, e.message, error: true);
    return null;
  }
}

Widget _page(String title, Widget body) => Scaffold(
  appBar: GameBar(title: Text(title)),
  body: GlmBackground(child: body),
);

class FriendliesScreen extends ConsumerWidget {
  const FriendliesScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return _page(
      l.friendlies,
      AsyncView(
        value: ref.watch(friendliesProvider(leagueId)),
        onRetry: () => ref.invalidate(friendliesProvider(leagueId)),
        data: (f) {
          final p = context.palette;
          final recent = f['recent'] as List<dynamic>? ?? const [];
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l.friendlyLead(f['fitness'] as int? ?? 0),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted),
              ),
              Text(
                f['first_free'] == true ? l.friendlyFree : l.friendlyCost(f['coins'] as int? ?? 0),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.glm.goldText, fontWeight: FontWeight.w700),
              ),
              if (f['blocked'] != null)
                Text(
                  '${f['blocked']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.glm.liveText),
                ),
              const SizedBox(height: 12),
              if (recent.isNotEmpty) ...[
                SectionTitle(l.recentFriendlies),
                for (final r in recent.take(3))
                  ListTile(
                    dense: true,
                    title: Text(
                      '${((r as Map<dynamic, dynamic>)['opponent'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                    ),
                    trailing: Text(
                      '${r['goals_for']} - ${r['goals_against']}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: GlmFonts.numbers, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuickMatchScreen(
                          home: '${(f['club'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                          played: Map<String, dynamic>.from(r),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              for (final o in (f['opponents'] as List<dynamic>? ?? const []))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlmCard(
                    padding: const EdgeInsets.all(10),
                    gold: (o as Map<dynamic, dynamic>)['recommended'] == true,
                    child: Row(
                      children: [
                        ClubCrest(url: o['crest_url'] as String?, name: '${o['code']}', size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${o['name']}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                [
                                  if (o['recommended'] == true) l.suggestedOpponent,
                                  if (o['played_today'] == true) l.playedToday,
                                  if (o['coach'] != null) '${o['coach']}',
                                ].join(' · '),
                                style: TextStyle(color: p.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        GlmButton(
                          label: l.playFriendly,
                          onPressed: f['blocked'] != null
                              ? null
                              : () async {
                                  final r = await _try(
                                    context,
                                    () => ref.read(socialRepositoryProvider).playFriendly(leagueId, o['id'] as int),
                                  );
                                  ref.invalidate(friendliesProvider(leagueId));
                                  if (r != null && context.mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => QuickMatchScreen(
                                          home: '${(f['club'] as Map<dynamic, dynamic>?)?['name'] ?? ''}',
                                          played: Map<String, dynamic>.from(r['friendly'] as Map<dynamic, dynamic>),
                                        ),
                                      ),
                                    );
                                  }
                                },
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
