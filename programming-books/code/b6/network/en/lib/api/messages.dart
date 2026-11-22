import 'errors.dart';

// The screen's words for each error: the switch must cover them all.
String message(ApiError e) => switch (e) {
  Offline() => 'No connection. Check your internet and try again.',
  TimedOut() => 'The café is taking too long to answer. Try again in a moment.',
  Unauthorized() => 'Please sign in again.',
  NotFound() => 'This was not found. It may have been removed.',
  Rejected(:final message) => message,
  ServerError(status: 429 || 503) =>
    'The café is very busy. Try again in a minute.',
  ServerError() => 'Something went wrong on our side. We are on it.',
  BadResponse() =>
    'The answer from the café could not be read. Please update the app.',
};
