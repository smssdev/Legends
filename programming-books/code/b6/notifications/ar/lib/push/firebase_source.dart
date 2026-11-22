import 'package:firebase_messaging/firebase_messaging.dart';

import 'message.dart';
import 'push_source.dart';

class FirebasePushSource implements PushSource {
  final _messaging = FirebaseMessaging.instance;

  static PushMessage? _read(RemoteMessage message) =>
      PushMessage.fromData(message.data);

  @override
  Stream<PushMessage> get foreground =>
      FirebaseMessaging.onMessage.map(_read).where((m) => m != null).cast();

  @override
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp
      .map(_read)
      .where((m) => m != null)
      .cast();

  @override
  Future<PushMessage?> initial() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _read(message);
  }

  static PermissionState _state(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PermissionState.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PermissionState.denied,
        AuthorizationStatus.notDetermined => PermissionState.unknown,
      };

  @override
  Future<PermissionState> permission() async =>
      _state(await _messaging.getNotificationSettings());

  @override
  Future<PermissionState> request() async =>
      _state(await _messaging.requestPermission());
}
