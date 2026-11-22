import 'dart:async';

import 'push/message.dart';
import 'push/push_source.dart';

// For the demo app: a message arrives a moment after the app opens.
class DemoPush implements PushSource {
  DemoPush({
    this.state = PermissionState.unknown,
    this.answer = PermissionState.granted,
  });

  PermissionState state;
  final PermissionState answer;
  final foregroundMessages = StreamController<PushMessage>.broadcast();
  final openedMessages = StreamController<PushMessage>.broadcast();
  PushMessage? started;
  var requests = 0;

  @override
  Stream<PushMessage> get foreground => foregroundMessages.stream;

  @override
  Stream<PushMessage> get opened => openedMessages.stream;

  @override
  Future<PushMessage?> initial() async => started;

  @override
  Future<PermissionState> permission() async => state;

  @override
  Future<PermissionState> request() async {
    requests++;
    return state = answer;
  }
}
