// Everything that can go wrong with a request, as types the screen can switch on.
sealed class ApiError implements Exception {
  const ApiError();
}

final class Offline extends ApiError {
  const Offline();
}

final class TimedOut extends ApiError {
  const TimedOut();
}

final class Unauthorized extends ApiError {
  const Unauthorized();
}

final class NotFound extends ApiError {
  const NotFound();
}

/// The server refused the request (400, 409, 422…), with its reason.
final class Rejected extends ApiError {
  const Rejected(this.status, this.message);
  final int status;
  final String message;
}

/// 429 and 5xx: the server could not answer now.
final class ServerError extends ApiError {
  const ServerError(this.status, {this.retryAfter});
  final int status;
  final Duration? retryAfter;
}

final class BadResponse extends ApiError {
  const BadResponse(this.detail);
  final String detail;
}

String describe(ApiError e) => switch (e) {
  Offline() => 'Offline',
  TimedOut() => 'TimedOut',
  Unauthorized() => 'Unauthorized',
  NotFound() => 'NotFound',
  Rejected(:final status, :final message) => 'Rejected($status, $message)',
  ServerError(:final status) => 'ServerError($status)',
  BadResponse() => 'BadResponse',
};
