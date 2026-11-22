import 'push/message.dart';

// Promotions wait for the morning; order updates never wait.
bool showNow(PushMessage message, DateTime localTime) {
  if (message.kind != PushKind.promo) {
    return true;
  }
  return localTime.hour >= 8 && localTime.hour < 22;
}
