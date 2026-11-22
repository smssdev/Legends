import 'push/message.dart';

// العروض تنتظر الصباح؛ وتحديثات الطلب لا تنتظر أبداً.
bool showNow(PushMessage message, DateTime localTime) {
  if (message.kind != PushKind.promo) {
    return true;
  }
  return localTime.hour >= 8 && localTime.hour < 22;
}
