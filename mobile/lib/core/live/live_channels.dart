import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../storage/token_store.dart';

/// [Sprint 53 F1] The game's live channels (Reverb, the Pusher protocol) for the app, as the web has them
/// (web/src/lib/echo.ts): a live match's minutes, its chat and reactions, pushed as the server makes them, so the
/// screens stop asking every second. Private channels are signed with the account's token at /api/v1/broadcasting/auth.
/// Every screen keeps its own poll as the fallback: while [LiveSubscription.subscribed] is false it polls as before.
abstract interface class LiveFeed {
  /// Subscribes to the private channel [name] (`match.12`, without `private-`), each event to its handler (the event's
  /// data decoded). Leave it when the screen goes.
  LiveSubscription join(String name, Map<String, void Function(Map<String, dynamic>)> on);
}

abstract interface class LiveSubscription {
  /// True while the channel is subscribed on a connected socket.
  ValueListenable<bool> get subscribed;
  void leave();
}

class ReverbFeed implements LiveFeed {
  ReverbFeed(this._tokens);

  final TokenStore _tokens;
  PusherChannelsClient? _client;
  final _open = <_ReverbSubscription>{};
  StreamSubscription<PusherChannelsClientLifeCycleState>? _life;

  PusherChannelsClient _ensure() {
    final existing = _client;
    if (existing != null) return existing;
    final site = Uri.parse(AppConfig.siteUrl);
    final client = PusherChannelsClient.websocket(
      options: PusherChannelsOptions.fromHost(
        scheme: site.scheme == 'https' ? 'wss' : 'ws',
        host: site.host,
        port: site.hasPort ? site.port : (site.scheme == 'https' ? 443 : 80),
        key: AppConfig.reverbKey,
      ),
      // A dropped socket: try again (the client waits a little more each time).
      connectionErrorHandler: (_, _, refresh) => refresh(),
    );
    _life = client.lifecycleStream.listen((state) {
      final up = state == PusherChannelsClientLifeCycleState.establishedConnection;
      for (final s in _open) {
        if (up) {
          s.channel.subscribeIfNotUnsubscribed();
        } else {
          s._subscribed.value = false;
        }
      }
    });
    unawaited(client.connect());
    return _client = client;
  }

  @override
  LiveSubscription join(String name, Map<String, void Function(Map<String, dynamic>)> on) {
    final client = _ensure();
    final channel = client.privateChannel(
      'private-$name',
      forceCreateNewInstance: true,
      authorizationDelegate: _TokenAuthorization(_tokens),
    );
    final sub = _ReverbSubscription(channel, this);
    sub._listen.add(channel.bind(Channel.subscriptionSucceededEventName).listen((_) => sub._subscribed.value = true));
    on.forEach((event, handler) {
      sub._listen.add(
        channel.bind(event).listen((e) {
          final data = e.data;
          try {
            final map = data is String ? jsonDecode(data) : data;
            if (map is Map<String, dynamic>) handler(map);
          } catch (_) {
            // A message the app cannot read: the poll has it.
          }
        }),
      );
    });
    _open.add(sub);
    channel.subscribe();
    return sub;
  }

  void _left(_ReverbSubscription s) => _open.remove(s);

  void dispose() {
    _life?.cancel();
    _client?.dispose();
    _client = null;
  }
}

class _ReverbSubscription implements LiveSubscription {
  _ReverbSubscription(this.channel, this._feed);

  final PrivateChannel channel;
  final ReverbFeed _feed;
  final _subscribed = ValueNotifier(false);
  final _listen = <StreamSubscription<dynamic>>[];

  @override
  ValueListenable<bool> get subscribed => _subscribed;

  @override
  void leave() {
    for (final l in _listen) {
      l.cancel();
    }
    channel.unsubscribe();
    _subscribed.value = false;
    _feed._left(this);
  }
}

/// Signs each subscription with the token as it is now (it may change after a sign-in), at the API's own route.
class _TokenAuthorization implements EndpointAuthorizableChannelAuthorizationDelegate<PrivateChannelAuthorizationData> {
  _TokenAuthorization(this._tokens);

  final TokenStore _tokens;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(String socketId, String channelName) async {
    final token = await _tokens.read() ?? '';
    return EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
      authorizationEndpoint: Uri.parse('${AppConfig.apiUrl}/broadcasting/auth'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).authorizationData(socketId, channelName);
  }

  @override
  EndpointAuthFailedCallback? get onAuthFailed => null;
}

final liveFeedProvider = Provider<LiveFeed>((ref) {
  final feed = ReverbFeed(ref.watch(tokenStoreProvider));
  ref.onDispose(feed.dispose);
  return feed;
});
