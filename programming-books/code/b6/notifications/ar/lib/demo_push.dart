import 'dart:async';

import 'push/message.dart';
import 'push/push_source.dart';

// لتطبيق العرض: رسالة تصل بعد لحظة من فتح التطبيق.
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
