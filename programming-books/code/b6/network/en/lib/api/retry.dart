import 'dart:math';

import 'errors.dart';

// How many times to try, and how long to wait between tries.
class RetryPolicy {
  const RetryPolicy({
    this.attempts = 4,
    this.base = const Duration(milliseconds: 200),
    this.cap = const Duration(seconds: 5),
  });

  final int attempts;
  final Duration base;
  final Duration cap;

  // Full jitter: a random wait between zero and the doubling limit, so that a thousand phones do not retry at the same moment.
  Duration delay(int retry, Random random) {
    final limit = min(
      cap.inMilliseconds,
      base.inMilliseconds * pow(2, retry).toInt(),
    );
    return Duration(milliseconds: random.nextInt(limit + 1));
  }
}

// Only failures that may pass: no connection, a timeout, an overloaded or restarting server.
bool retryable(ApiError e) => switch (e) {
  Offline() || TimedOut() => true,
  ServerError(:final status) =>
    status == 429 || status == 502 || status == 503 || status == 504,
  _ => false,
};
