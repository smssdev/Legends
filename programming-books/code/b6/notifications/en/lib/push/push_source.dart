import 'message.dart';

enum PermissionState { unknown, granted, denied }

// The app depends on this, never on Firebase directly.
abstract interface class PushSource {
  // Three moments: open on screen, tapped from the tray, or the tap that started the app.
  Stream<PushMessage> get foreground;
  Stream<PushMessage> get opened;
  Future<PushMessage?> initial();

  Future<PermissionState> permission();
  Future<PermissionState> request();
}
