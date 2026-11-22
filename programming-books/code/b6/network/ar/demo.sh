$ dart run bin/demo.dart
GET /menu
0.1s  attempt 1: ServerError(503)
0.1s    waiting 108 ms
0.2s  attempt 2: ServerError(503)
0.2s    waiting 244 ms
0.5s  attempt 3: OK
  -> [{name: Latte, price: 45}]
GET /slow
1.0s  attempt 1: TimedOut
1.0s    waiting 173 ms
2.2s  attempt 2: TimedOut
2.2s    waiting 247 ms
3.4s  attempt 3: TimedOut
3.4s    waiting 223 ms
4.7s  attempt 4: TimedOut
  -> TimedOut
GET /busy
0.0s  attempt 1: ServerError(429)
0.0s    waiting 1000 ms
1.0s  attempt 2: ServerError(429)
1.0s    waiting 1000 ms
2.0s  attempt 3: ServerError(429)
2.0s    waiting 1000 ms
3.0s  attempt 4: ServerError(429)
  -> ServerError(429)
GET /missing
0.0s  attempt 1: NotFound
  -> NotFound
