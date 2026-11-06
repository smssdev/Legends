import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// [Sprint 18 F1] The inbox (`/messages`, Sprint 22): the server writes each message in the account's language.
class InboxMessage {
  const InboxMessage({required this.id, required this.type, this.leagueId, required this.read, this.at, required this.title, required this.body, this.link});

  factory InboxMessage.fromJson(Map<String, dynamic> j) => InboxMessage(
        id: j['id'] as int, type: '${j['type']}', leagueId: j['league_id'] as int?, read: j['read'] == true,
        at: DateTime.tryParse('${j['created_at'] ?? ''}'), title: '${j['title'] ?? ''}', body: '${j['body'] ?? ''}', link: j['link'] as String?,
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
    ('/stadium', 'stadium'), ('/finance', 'finance'), ('/market', 'market'), ('/transfers', 'market'), ('/scout', 'scout'), ('/training', 'training'),
    ('/specialists', 'specialists'), ('/spy', 'spy'), ('/quests', 'quests'), ('/friendlies', 'friendlies'), ('/predictions', 'predictions'), ('/newspaper', 'newspaper'), ('/stats', 'stats'), ('/match', 'matchday'), ('/contracts', 'contracts'), ('/tickets', 'tickets'), ('/squad', 'squad'), ('/team', 'squad'), ('/lineup', 'lineup'), ('/tactics', 'tactics'),
  ]) {
    if (path.startsWith(prefix)) return '/leagues/$league/$screen';
  }
  return '/leagues/$league';
}

class InboxPage {
  const InboxPage({required this.messages, required this.more, required this.unread});

  factory InboxPage.fromJson(Map<String, dynamic> j) => InboxPage(
        messages: [for (final m in (j['messages'] as List? ?? const [])) InboxMessage.fromJson(m as Map<String, dynamic>)],
        more: j['more'] == true, unread: j['unread'] as int? ?? 0,
      );

  final List<InboxMessage> messages;
  final bool more;
  final int unread;
}

class InboxRepository {
  InboxRepository(this._api);

  final ApiClient _api;

  Future<InboxPage> page({int? before}) async => InboxPage.fromJson(await _api.get('/messages', query: {'before': ?before}));
  Future<int> unread() async => (await _api.get('/messages/unread'))['unread'] as int? ?? 0;
  Future<void> read(int id) => _api.post('/messages/$id/read');
  Future<void> readAll() => _api.post('/messages/read-all');
}

final inboxRepositoryProvider = Provider<InboxRepository>((ref) => InboxRepository(ref.watch(apiProvider)));
final unreadProvider = FutureProvider.autoDispose<int>((ref) => ref.read(inboxRepositoryProvider).unread());
