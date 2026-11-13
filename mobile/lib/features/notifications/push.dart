import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/gen/models.g.dart' as api;
import '../../core/api/api_client.dart';
import '../inbox/inbox_data.dart';

/// [Sprint 19 F1] Pushes on the phone, by FCM on the server's one channel (App\Notify\Push, Fcm). The app's Firebase
/// settings come from the server (`/app` → `firebase`), so pushes start as soon as the owner sets them there, with no new
/// build; until then this does nothing. After sign-in the device's token is sent (`channel: fcm`), and forgotten at
/// sign-out. A tap on a push opens its screen (appRoute: the site's path inside its league).
class PushService {
  PushService(this._api);

  final ApiClient _api;
  bool _ready = false;
  String? _token;
  final _taps = StreamController<String>.broadcast();
  final _arrivals = StreamController<void>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];

  /// [Sprint 59 F7] The Firebase listeners and the two streams closed with the provider.
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _taps.close();
    await _arrivals.close();
  }

  /// The screens the taps open.
  Stream<String> get taps => _taps.stream;

  /// A push arrived while the app was open (the inbox count changes).
  Stream<void> get arrivals => _arrivals.stream;

  /// For the signed-in coach: Firebase from the server's settings, the permission, the token, and the taps.
  Future<void> start() async {
    if (_ready) return;
    try {
      // [Sprint 59 F1] The server's Firebase settings through the generated model (`AppAnswer`).
      final f = api.AppAnswer.fromJson(await _api.get('/app')).firebase;
      if (f == null) return;
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: f.apiKey ?? '',
            appId: f.appId ?? '',
            messagingSenderId: f.senderId ?? '',
            projectId: f.projectId ?? '',
          ),
        );
      }
      final messaging = FirebaseMessaging.instance;
      final allowed = await messaging.requestPermission();
      if (allowed.authorizationStatus == AuthorizationStatus.denied) return;
      _ready = true;
      // The registration token is what FCM HTTP v1 sends to (message.token); the newer installation-ID registration
      // is not that target, so the token stays until the server sends another way.
      // ignore: deprecated_member_use
      await _register(await messaging.getToken());
      _subs
        // ignore: deprecated_member_use
        ..add(messaging.onTokenRefresh.listen(_register))
        ..add(FirebaseMessaging.onMessage.listen((_) => _arrivals.add(null)))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final first = await messaging.getInitialMessage();
      if (first != null) _open(first);
    } catch (_) {
      // No Google services on the phone, or no network: the inbox still has every message.
    }
  }

  /// At sign-out: this phone stops getting the account's pushes.
  Future<void> forget() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.delete('/notifications/subscriptions?endpoint=${Uri.encodeQueryComponent(token)}');
    } catch (_) {
      // The server forgets a dead token by itself on the next push.
    }
    _token = null;
  }

  Future<void> _register(String? token) async {
    if (token == null) return;
    _token = token;
    await _api.post('/notifications/subscriptions', {'channel': 'fcm', 'token': token});
  }

  void _open(RemoteMessage m) {
    final league = int.tryParse('${m.data['league'] ?? ''}');
    _taps.add(appRoute(m.data['link'] as String?, league) ?? '/');
  }
}

final pushProvider = Provider<PushService>((ref) {
  final push = PushService(ref.watch(apiProvider));
  ref.onDispose(() => unawaited(push.dispose()));
  return push;
});
