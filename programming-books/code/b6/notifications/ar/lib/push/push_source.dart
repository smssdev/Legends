import 'message.dart';

enum PermissionState { unknown, granted, denied }

// التطبيق يعتمد على هذه، لا على Firebase مباشرة.
abstract interface class PushSource {
  // ثلاث لحظات: مفتوح على الشاشة، أو ضُغط من الدرج، أو الضغطة التي شغّلت التطبيق.
  Stream<PushMessage> get foreground;
  Stream<PushMessage> get opened;
  Future<PushMessage?> initial();

  Future<PermissionState> permission();
  Future<PermissionState> request();
}
