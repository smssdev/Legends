import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';

/// [Sprint 18 F1] The inbox (`/messages`, Sprint 22): the server writes each message in the account's language.
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.type,
    this.leagueId,
    required this.read,
    this.at,
    required this.title,
    required this.body,
    this.link,
  });

  /// [Sprint 59 F1] From the generated model (`Message` in openapi.yaml).
  factory InboxMessage.fromJson(Object? json) => InboxMessage.of(api.Message.fromJson(json));

  factory InboxMessage.of(api.Message m) => InboxMessage(
    id: m.id,
    type: m.type,
    leagueId: m.leagueId,
    read: m.read,
    at: DateTime.tryParse(m.createdAt),
    title: m.title,
    body: m.body,
    link: m.link,
  );

  final int id;
  final String type, title, body;
  final int? leagueId;
  final bool read;
  final DateTime? at;
  final String? link;

  InboxMessage asRead() => InboxMessage(id: id, type: type, leagueId: leagueId, read: true, at: at, title: title, body: body, link: link);

  /// Where the message leads in the app (appRoute).
  String? get route => appRoute(link, leagueId);
}

/// [Sprint 18, 19] Where a message or a push leads in the app: the site's path, inside its league when it has one;
/// null when there is no league (the home screen).
String? appRoute(String? link, int? league) {
  final path = link ?? '';
  // Pages of the account, wherever the message came from.
  for (final page in ['/ideas', '/support', '/announcements', '/wallet', '/profile']) {
    if (path.startsWith(page)) return page;
  }
  final live = RegExp(r'^/live/(\d+)').firstMatch(path);
  if (live != null) return '/match/${live.group(1)}';
  if (league == null) return null;
  for (final (prefix, screen) in [
    ('/stadium', 'stadium'),
    ('/finance', 'finance'),
    ('/market', 'market'),
    ('/transfers', 'market'),
    ('/scout', 'scout'),
    ('/training', 'training'),
    ('/specialists', 'specialists'),
    ('/spy', 'spy'),
    ('/quests', 'quests'),
    ('/friendlies', 'friendlies'),
    ('/predictions', 'predictions'),
    ('/newspaper', 'newspaper'),
    ('/stats', 'stats'),
    ('/match', 'matchday'),
    ('/contracts', 'contracts'),
    ('/tickets', 'tickets'),
    ('/squad', 'squad'),
    ('/team', 'squad'),
    ('/lineup', 'lineup'),
    ('/tactics', 'tactics'),
  ]) {
    if (path.startsWith(prefix)) return '/leagues/$league/$screen';
  }
  return '/leagues/$league';
}

class InboxPage {
  const InboxPage({required this.messages, required this.more, required this.unread});

  factory InboxPage.fromJson(Object? json) {
    final page = api.MessagesAnswer.fromJson(json);
    return InboxPage(messages: [for (final m in page.messages) InboxMessage.of(m)], more: page.more, unread: page.unread);
  }

  final List<InboxMessage> messages;
  final bool more;
  final int unread;
}

class InboxRepository {
  InboxRepository(this._api);

  final ApiClient _api;

  /// [Sprint 61 F7] The first page with [onNewer]: the saved one first, the server's behind it.
  Future<InboxPage> page({int? before, void Function()? onNewer}) async => InboxPage.fromJson(
    before == null && onNewer != null
        ? await _api.getSaved('/messages', onNewer: onNewer)
        : await _api.get('/messages', query: {'before': ?before}),
  );
  Future<int> unread() async => api.MessagesUnreadAnswer.fromJson(await _api.get('/messages/unread')).unread;
  Future<void> read(int id) => _api.post('/messages/$id/read');
  Future<void> readAll() => _api.post('/messages/read-all');
}

final inboxRepositoryProvider = Provider<InboxRepository>((ref) => InboxRepository(ref.watch(apiProvider)));
final unreadProvider = FutureProvider.autoDispose<int>((ref) => ref.read(inboxRepositoryProvider).unread());
