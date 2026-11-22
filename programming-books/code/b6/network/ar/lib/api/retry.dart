import 'dart:math';

import 'errors.dart';

// كم مرة نحاول، وكم ننتظر بين المحاولات.
class RetryPolicy {
  const RetryPolicy({
    this.attempts = 4,
    this.base = const Duration(milliseconds: 200),
    this.cap = const Duration(seconds: 5),
  });

  final int attempts;
  final Duration base;
  final Duration cap;

  // عشوائية كاملة: انتظار عشوائي بين الصفر وحد يتضاعف، كي لا تعيد ألف جوال المحاولة في اللحظة نفسها.
  Duration delay(int retry, Random random) {
    final limit = min(
      cap.inMilliseconds,
      base.inMilliseconds * pow(2, retry).toInt(),
    );
    return Duration(milliseconds: random.nextInt(limit + 1));
  }
}

// فقط حالات الفشل التي قد تزول: لا اتصال، أو انتهاء المهلة، أو خادم مزدحم أو يُعاد تشغيله.
bool retryable(ApiError e) => switch (e) {
  Offline() || TimedOut() => true,
  ServerError(:final status) =>
    status == 429 || status == 502 || status == 503 || status == 504,
  _ => false,
};
