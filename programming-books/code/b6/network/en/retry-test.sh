$ flutter test test/retry_test.dart
00:00 +0: loading test/retry_test.dart
00:00 +0: retries wait longer each time, and only when it can help
GET, busy three times:
attempt 1: ServerError(503)
  waiting 108 ms
attempt 2: ServerError(503)
  waiting 244 ms
attempt 3: ServerError(503)
  waiting 368 ms
attempt 4: OK
GET, a bug on the server:
attempt 1: ServerError(500)
POST without a key:
attempt 1: ServerError(503)
POST with a key:
attempt 1: ServerError(503)
  waiting 108 ms
attempt 2: OK
429 with Retry-After: 2
attempt 1: ServerError(429)
  waiting 2000 ms
attempt 2: OK
00:00 +1: All tests passed!
